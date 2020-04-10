// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../convert.dart';
import '../globals.dart';
import '../macos/xcode.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../services.dart';
import 'code_signing.dart';
import 'xcodeproj.dart';

IMobileDevice get iMobileDevice => context.get<IMobileDevice>();

/// Specialized exception for expected situations where the ideviceinfo
/// tool responds with exit code 255 / 'No device found' message
class IOSDeviceNotFoundError implements Exception {
  const IOSDeviceNotFoundError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exception representing an attempt to find information on an iOS device
/// that failed because the user had not paired the device with the host yet.
class IOSDeviceNotTrustedError implements Exception {
  const IOSDeviceNotTrustedError(this.message, this.lockdownCode);

  /// The error message to show to the user.
  final String message;

  /// The associated `lockdownd` error code.
  final LockdownReturnCode lockdownCode;

  @override
  String toString() => '$message (lockdownd error code ${lockdownCode.code})';
}

/// Class specifying possible return codes from `lockdownd`.
///
/// This contains only a subset of the return codes that `lockdownd` can return,
/// as we only care about a limited subset. These values should be kept in sync with
/// https://github.com/libimobiledevice/libimobiledevice/blob/26373b3/include/libimobiledevice/lockdown.h#L37
class LockdownReturnCode {
  const LockdownReturnCode._(this.code);

  /// Creates a new [LockdownReturnCode] from the specified OS exit code.
  ///
  /// If the [code] maps to one of the known codes, a `const` instance will be
  /// returned.
  factory LockdownReturnCode.fromCode(int code) {
    final Map<int, LockdownReturnCode> knownCodes = <int, LockdownReturnCode>{
      pairingDialogResponsePending.code: pairingDialogResponsePending,
      invalidHostId.code: invalidHostId,
    };

    return knownCodes.containsKey(code)
        ? knownCodes[code]
        : LockdownReturnCode._(code);
  }

  /// The OS exit code.
  final int code;

  /// Error code indicating that the pairing dialog has been shown to the user,
  /// and the user has not yet responded as to whether to trust the host.
  static const LockdownReturnCode pairingDialogResponsePending =
      LockdownReturnCode._(19);

  /// Error code indicating that the host is not trusted.
  ///
  /// This can happen if the user explicitly says "do not trust this  computer"
  /// or if they revoke all trusted computers in the device settings.
  static const LockdownReturnCode invalidHostId = LockdownReturnCode._(21);
}

class IMobileDevice {
  IMobileDevice()
      : _ideviceIdPath = artifacts.getArtifactPath(Artifact.ideviceId,
                platform: TargetPlatform.ios) ??
            'idevice_id', // TODO(fujino): remove fallback once g3 updated
        _ideviceinfoPath = artifacts.getArtifactPath(Artifact.ideviceinfo,
                platform: TargetPlatform.ios) ??
            'ideviceinfo', // TODO(fujino): remove fallback once g3 updated
        _idevicenamePath = artifacts.getArtifactPath(Artifact.idevicename,
                platform: TargetPlatform.ios) ??
            'idevicename', // TODO(fujino): remove fallback once g3 updated
        _idevicesyslogPath = artifacts.getArtifactPath(Artifact.idevicesyslog,
                platform: TargetPlatform.ios) ??
            'idevicesyslog', // TODO(fujino): remove fallback once g3 updated
        _idevicescreenshotPath = artifacts.getArtifactPath(
                Artifact.idevicescreenshot,
                platform: TargetPlatform.ios) ??
            'idevicescreenshot' {
    // TODO(fujino): remove fallback once g3 updated
  }
  final String _ideviceIdPath;
  final String _ideviceinfoPath;
  final String _idevicenamePath;
  final String _idevicesyslogPath;
  final String _idevicescreenshotPath;

  bool get isInstalled {
    _isInstalled ??= exitsHappy(
      <String>[_ideviceIdPath, '-h'],
      environment: Map<String, String>.fromEntries(
          <MapEntry<String, String>>[cache.dyLdLibEntry]),
    );
    return _isInstalled;
  }

  bool _isInstalled;

  /// Returns true if libimobiledevice is installed and working as expected.
  ///
  /// Older releases of libimobiledevice fail to work with iOS 10.3 and above.
  Future<bool> get isWorking async {
    if (_isWorking != null) {
      return _isWorking;
    }
    if (!isInstalled) {
      _isWorking = false;
      return _isWorking;
    }
    // If usage info is printed in a hyphenated id, we need to update.
    const String fakeIphoneId = '00008020-001C2D903C42002E';
    final Map<String, String> executionEnv = Map<String, String>.fromEntries(
        <MapEntry<String, String>>[cache.dyLdLibEntry]);
    final ProcessResult ideviceResult = (await runAsync(
      <String>[_ideviceinfoPath, '-u', fakeIphoneId],
      environment: executionEnv,
    ))
        .processResult;
    if (ideviceResult.stdout.contains('Usage: ideviceinfo')) {
      _isWorking = false;
      return _isWorking;
    }

    // If no device is attached, we're unable to detect any problems. Assume all is well.
    final ProcessResult result = (await runAsync(
      <String>[
        _ideviceIdPath,
        '-l',
      ],
      environment: executionEnv,
    ))
        .processResult;
    if (result.exitCode == 0 && result.stdout.isEmpty) {
      _isWorking = true;
    } else {
      // Check that we can look up the names of any attached devices.
      _isWorking = await exitsHappyAsync(
        <String>[_idevicenamePath],
        environment: executionEnv,
      );
    }
    return _isWorking;
  }

  bool _isWorking;

  Future<String> getAvailableDeviceIDs() async {
    try {
      final ProcessResult result = await processManager.run(
        <String>[_ideviceIdPath, '-l'],
        environment: Map<String, String>.fromEntries(
            <MapEntry<String, String>>[cache.dyLdLibEntry]),
      );
      if (result.exitCode != 0)
        throw ToolExit('idevice_id returned an error:\n${result.stderr}');
      return result.stdout;
    } on ProcessException {
      throw ToolExit('Failed to invoke idevice_id. Run flutter doctor.');
    }
  }

  Future<String> getInfoForDevice(String deviceID, String key) async {
    try {
      final ProcessResult result = await processManager.run(
        <String>[_ideviceinfoPath, '-u', deviceID, '-k', key],
        environment: Map<String, String>.fromEntries(
            <MapEntry<String, String>>[cache.dyLdLibEntry]),
      );
      if (result.exitCode == 255 &&
          result.stdout != null &&
          result.stdout.contains('No device found'))
        throw IOSDeviceNotFoundError(
            'ideviceinfo could not find device:\n${result.stdout}. Try unlocking attached devices.');
      if (result.exitCode == 255 &&
          result.stderr != null &&
          result.stderr.contains('Could not connect to lockdownd')) {
        if (result.stderr.contains(
            'error code -${LockdownReturnCode.pairingDialogResponsePending.code}')) {
          throw const IOSDeviceNotTrustedError(
            'Device info unavailable. Is the device asking to "Trust This Computer?"',
            LockdownReturnCode.pairingDialogResponsePending,
          );
        }
        if (result.stderr
            .contains('error code -${LockdownReturnCode.invalidHostId.code}')) {
          throw const IOSDeviceNotTrustedError(
            'Device info unavailable. Device pairing "trust" may have been revoked.',
            LockdownReturnCode.invalidHostId,
          );
        }
      }
      if (result.exitCode != 0)
        throw ToolExit('ideviceinfo returned an error:\n${result.stderr}');
      return result.stdout.trim();
    } on ProcessException {
      throw ToolExit('Failed to invoke ideviceinfo. Run flutter doctor.');
    }
  }

  /// Starts `idevicesyslog` and returns the running process.
  Future<Process> startLogger(String deviceID) {
    return runCommand(
      <String>[
        _idevicesyslogPath,
        '-u',
        deviceID,
      ],
      environment: Map<String, String>.fromEntries(
          <MapEntry<String, String>>[cache.dyLdLibEntry]),
    );
  }

  /// Captures a screenshot to the specified outputFile.
  Future<void> takeScreenshot(File outputFile) {
    return runCheckedAsync(
      <String>[_idevicescreenshotPath, outputFile.path],
      environment: Map<String, String>.fromEntries(
          <MapEntry<String, String>>[cache.dyLdLibEntry]),
    );
  }
}

String readGeneratedXcconfig(String appPath) {
  final String generatedXcconfigPath = fs.path
      .join(fs.currentDirectory.path, appPath, 'Flutter', 'Generated.xcconfig');
  final File generatedXcconfigFile = fs.file(generatedXcconfigPath);
  if (!generatedXcconfigFile.existsSync()) return null;
  return generatedXcconfigFile.readAsStringSync();
}

Future<void> diagnoseXcodeBuildFailure(XcodeBuildResult result) async {
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      result.stdout?.toUpperCase()?.contains('BITCODE') == true) {
    BuildEvent(
      'xcode-bitcode-failure',
      command: result.xcodeBuildExecution.buildCommands.toString(),
      settings: result.xcodeBuildExecution.buildSettings.toString(),
    ).send();
  }

  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      result.stdout?.contains('BCEROR') == true &&
      // May need updating if Xcode changes its outputs.
      result.stdout?.contains(
              'Xcode couldn\'t find a provisioning profile matching') ==
          true) {
    printError(noProvisioningProfileInstruction, emphasis: true);
    return;
  }
  // Make sure the user has specified one of:
  // * DEVELOPMENT_TEAM (automatic signing)
  // * PROVISIONING_PROFILE (manual signing)
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      !<String>['DEVELOPMENT_TEAM', 'PROVISIONING_PROFILE']
          .any(result.xcodeBuildExecution.buildSettings.containsKey)) {
    printError(noDevelopmentTeamInstruction, emphasis: true);
    return;
  }
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      result.xcodeBuildExecution.buildSettings['PRODUCT_BUNDLE_IDENTIFIER']
              ?.contains('com.example') ==
          true) {
    printError('');
    printError(
        'It appears that your application still contains the default signing identifier.');
    printError("Try replacing 'com.example' with your signing id in Xcode:");
    printError('  open ios/Runner.xcworkspace');
    return;
  }
  if (result.stdout?.contains('Code Sign error') == true) {
    printError('');
    printError(
        'It appears that there was a problem signing your application prior to installation on the device.');
    printError('');
    printError(
        'Verify that the Bundle Identifier in your project is your signing id in Xcode');
    printError('  open ios/Runner.xcworkspace');
    printError('');
    printError("Also try selecting 'Product > Build' to fix the problem:");
    return;
  }
}

class XcodeBuildResult {
  XcodeBuildResult({
    @required this.success,
    this.output,
    this.stdout,
    this.stderr,
    this.xcodeBuildExecution,
  });

  final bool success;
  final String output;
  final String stdout;
  final String stderr;

  /// The invocation of the build that resulted in this result instance.
  final XcodeBuildExecution xcodeBuildExecution;
}

/// Describes an invocation of a Xcode build command.
class XcodeBuildExecution {
  XcodeBuildExecution({
    @required this.buildCommands,
    @required this.appDirectory,
    @required this.buildForPhysicalDevice,
    @required this.buildSettings,
  });

  /// The original list of Xcode build commands used to produce this build result.
  final List<String> buildCommands;
  final String appDirectory;
  final bool buildForPhysicalDevice;

  /// The build settings corresponding to the [buildCommands] invocation.
  final Map<String, String> buildSettings;
}

const String _xcodeRequirement =
    'Xcode $kXcodeRequiredVersionMajor.$kXcodeRequiredVersionMinor or greater is required to develop for iOS.';

bool _checkXcodeVersion() {
  if (!platform.isMacOS) return false;
  if (!xcodeProjectInterpreter.isInstalled) {
    printError('Cannot find "xcodebuild". $_xcodeRequirement');
    return false;
  }
  if (!xcode.isVersionSatisfactory) {
    printError(
        'Found "${xcodeProjectInterpreter.versionText}". $_xcodeRequirement');
    return false;
  }
  return true;
}

Future<void> _addServicesToBundle(Directory bundle) async {
  final List<Map<String, String>> services = <Map<String, String>>[];
  printTrace('Trying to resolve native pub services.');

  // Step 1: Parse the service configuration yaml files present in the service
  //         pub packages.
  await parseServiceConfigs(services);
  printTrace('Found ${services.length} service definition(s).');

  // Step 2: Copy framework dylibs to the correct spot for xcodebuild to pick up.
  final Directory frameworksDirectory =
      fs.directory(fs.path.join(bundle.path, 'Frameworks'));
  await _copyServiceFrameworks(services, frameworksDirectory);

  // Step 3: Copy the service definitions manifest at the correct spot for
  //         xcodebuild to pick up.
  final File manifestFile =
      fs.file(fs.path.join(bundle.path, 'ServiceDefinitions.json'));
  _copyServiceDefinitionsManifest(services, manifestFile);
}

Future<void> _copyServiceFrameworks(
    List<Map<String, String>> services, Directory frameworksDirectory) async {
  printTrace(
      "Copying service frameworks to '${fs.path.absolute(frameworksDirectory.path)}'.");
  frameworksDirectory.createSync(recursive: true);
  for (Map<String, String> service in services) {
    final String dylibPath = await getServiceFromUrl(
        service['ios-framework'], service['root'], service['name']);
    final File dylib = fs.file(dylibPath);
    printTrace('Copying ${dylib.path} into bundle.');
    if (!dylib.existsSync()) {
      printError("The service dylib '${dylib.path}' does not exist.");
      continue;
    }
    // Shell out so permissions on the dylib are preserved.
    await runCheckedAsync(
        <String>['/bin/cp', dylib.path, frameworksDirectory.path]);
  }
}

void _copyServiceDefinitionsManifest(
    List<Map<String, String>> services, File manifest) {
  printTrace("Creating service definitions manifest at '${manifest.path}'");
  final List<Map<String, String>> jsonServices = services
      .map<Map<String, String>>(
          (Map<String, String> service) => <String, String>{
                'name': service['name'],
                // Since we have already moved it to the Frameworks directory. Strip away
                // the directory and basenames.
                'framework':
                    fs.path.basenameWithoutExtension(service['ios-framework']),
              })
      .toList();
  final Map<String, dynamic> jsonObject = <String, dynamic>{
    'services': jsonServices
  };
  manifest.writeAsStringSync(json.encode(jsonObject),
      mode: FileMode.write, flush: true);
}

Future<bool> upgradePbxProjWithFlutterAssets(IosProject project) async {
  final File xcodeProjectFile = project.xcodeProjectInfoFile;
  assert(await xcodeProjectFile.exists());
  final List<String> lines = await xcodeProjectFile.readAsLines();

  final RegExp oldAssets = RegExp(r'\/\* (flutter_assets|app\.flx)');
  final StringBuffer buffer = StringBuffer();
  final Set<String> printedStatuses = <String>{};

  for (final String line in lines) {
    final Match match = oldAssets.firstMatch(line);
    if (match != null) {
      if (printedStatuses.add(match.group(1)))
        printStatus(
            'Removing obsolete reference to ${match.group(1)} from ${project.hostAppBundleName}');
    } else {
      buffer.writeln(line);
    }
  }
  await xcodeProjectFile.writeAsString(buffer.toString());
  return true;
}
