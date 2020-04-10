// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart';
import '../project.dart';
import 'ios_workflow.dart';

const String _xcrunPath = '/usr/bin/xcrun';
const String iosSimulatorId = 'apple_ios_simulator';

class IOSSimulators extends PollingDeviceDiscovery {
  IOSSimulators() : super('iOS simulators');

  @override
  bool get supportsPlatform => platform.isMacOS;

  @override
  bool get canListAnything => iosWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async =>
      IOSSimulatorUtils.instance.getAttachedDevices();
}

class IOSSimulatorUtils {
  /// Returns [IOSSimulatorUtils] active in the current app context (i.e. zone).
  static IOSSimulatorUtils get instance => context.get<IOSSimulatorUtils>();

  Future<List<IOSSimulator>> getAttachedDevices() async {
    // if (!xcode.isInstalledAndMeetsVersionCheck)
    //   return <IOSSimulator>[];

    final List<SimDevice> connected =
        await SimControl.instance.getConnectedDevices();
    return connected.map<IOSSimulator>((SimDevice device) {
      return IOSSimulator(device.udid,
          name: device.name, simulatorCategory: device.category);
    }).toList();
  }
}

/// A wrapper around the `simctl` command line tool.
class SimControl {
  /// Returns [SimControl] active in the current app context (i.e. zone).
  static SimControl get instance => context.get<SimControl>();

  /// Runs `simctl list --json` and returns the JSON of the corresponding
  /// [section].
  Future<Map<String, dynamic>> _list(SimControlListSection section) async {
    // Sample output from `simctl list --json`:
    //
    // {
    //   "devicetypes": { ... },
    //   "runtimes": { ... },
    //   "devices" : {
    //     "com.apple.CoreSimulator.SimRuntime.iOS-8-2" : [
    //       {
    //         "state" : "Shutdown",
    //         "availability" : " (unavailable, runtime profile not found)",
    //         "name" : "iPhone 4s",
    //         "udid" : "1913014C-6DCB-485D-AC6B-7CD76D322F5B"
    //       },
    //       ...
    //   },
    //   "pairs": { ... },

    final List<String> command = <String>[
      _xcrunPath,
      'simctl',
      'list',
      '--json',
      section.name
    ];
    printTrace(command.join(' '));
    final ProcessResult results = await processManager.run(command);
    if (results.exitCode != 0) {
      printError(
          'Error executing simctl: ${results.exitCode}\n${results.stderr}');
      return <String, Map<String, dynamic>>{};
    }
    try {
      final Object decodeResult =
          json.decode(results.stdout?.toString())[section.name];
      if (decodeResult is Map<String, dynamic>) {
        return decodeResult;
      }
      printError('simctl returned unexpected JSON response: ${results.stdout}');
      return <String, dynamic>{};
    } on FormatException {
      // We failed to parse the simctl output, or it returned junk.
      // One known message is "Install Started" isn't valid JSON but is
      // returned sometimes.
      printError('simctl returned non-JSON response: ${results.stdout}');
      return <String, dynamic>{};
    }
  }

  /// Returns a list of all available devices, both potential and connected.
  Future<List<SimDevice>> getDevices() async {
    final List<SimDevice> devices = <SimDevice>[];

    final Map<String, dynamic> devicesSection =
        await _list(SimControlListSection.devices);

    for (String deviceCategory in devicesSection.keys) {
      final Object devicesData = devicesSection[deviceCategory];
      if (devicesData != null && devicesData is List<dynamic>) {
        for (Map<String, dynamic> data
            in devicesData.map<Map<String, dynamic>>(castStringKeyedMap)) {
          devices.add(SimDevice(deviceCategory, data));
        }
      }
    }

    return devices;
  }

  /// Returns all the connected simulator devices.
  Future<List<SimDevice>> getConnectedDevices() async {
    final List<SimDevice> simDevices = await getDevices();
    return simDevices.where((SimDevice device) => device.isBooted).toList();
  }

  Future<bool> isInstalled(String deviceId, String appId) {
    return exitsHappyAsync(<String>[
      _xcrunPath,
      'simctl',
      'get_app_container',
      deviceId,
      appId,
    ]);
  }

  Future<RunResult> install(String deviceId, String appPath) {
    Future<RunResult> result;
    try {
      result = runCheckedAsync(
          <String>[_xcrunPath, 'simctl', 'install', deviceId, appPath]);
    } on ProcessException catch (exception) {
      throwToolExit('Unable to install $appPath on $deviceId:\n$exception');
    }
    return result;
  }

  Future<RunResult> uninstall(String deviceId, String appId) {
    Future<RunResult> result;
    try {
      result = runCheckedAsync(
          <String>[_xcrunPath, 'simctl', 'uninstall', deviceId, appId]);
    } on ProcessException catch (exception) {
      throwToolExit('Unable to uninstall $appId from $deviceId:\n$exception');
    }
    return result;
  }

  Future<RunResult> launch(String deviceId, String appIdentifier,
      [List<String> launchArgs]) {
    Future<RunResult> result;
    try {
      result = runCheckedAsync(<String>[
        _xcrunPath,
        'simctl',
        'launch',
        deviceId,
        appIdentifier,
        ...?launchArgs,
      ]);
    } on ProcessException catch (exception) {
      throwToolExit(
          'Unable to launch $appIdentifier on $deviceId:\n$exception');
    }
    return result;
  }

  Future<void> takeScreenshot(String deviceId, String outputPath) async {
    try {
      await runCheckedAsync(<String>[
        _xcrunPath,
        'simctl',
        'io',
        deviceId,
        'screenshot',
        outputPath
      ]);
    } on ProcessException catch (exception) {
      throwToolExit('Unable to take screenshot of $deviceId:\n$exception');
    }
  }
}

/// Enumerates all data sections of `xcrun simctl list --json` command.
class SimControlListSection {
  const SimControlListSection._(this.name);

  final String name;

  static const SimControlListSection devices =
      SimControlListSection._('devices');
  static const SimControlListSection devicetypes =
      SimControlListSection._('devicetypes');
  static const SimControlListSection runtimes =
      SimControlListSection._('runtimes');
  static const SimControlListSection pairs = SimControlListSection._('pairs');
}

/// A simulated device type.
///
/// Simulated device types can be listed using the command
/// `xcrun simctl list devicetypes`.
class SimDeviceType {
  SimDeviceType(this.name, this.identifier);

  /// The name of the device type.
  ///
  /// Examples:
  ///
  ///     "iPhone 6s"
  ///     "iPhone 6 Plus"
  final String name;

  /// The identifier of the device type.
  ///
  /// Examples:
  ///
  ///     "com.apple.CoreSimulator.SimDeviceType.iPhone-6s"
  ///     "com.apple.CoreSimulator.SimDeviceType.iPhone-6-Plus"
  final String identifier;
}

class SimDevice {
  SimDevice(this.category, this.data);

  final String category;
  final Map<String, dynamic> data;

  String get state => data['state']?.toString();
  String get availability => data['availability']?.toString();
  String get name => data['name']?.toString();
  String get udid => data['udid']?.toString();

  bool get isBooted => state == 'Booted';
}

class IOSSimulator extends Device {
  IOSSimulator(String id, {this.name, this.simulatorCategory})
      : super(
          id,
          category: Category.mobile,
          platformType: PlatformType.ios,
          ephemeral: true,
        );

  @override
  final String name;

  final String simulatorCategory;

  @override
  Future<bool> get isLocalEmulator async => true;

  @override
  Future<String> get emulatorId async => iosSimulatorId;

  @override
  bool get supportsHotReload => true;

  @override
  bool get supportsHotRestart => true;

  _IOSSimulatorDevicePortForwarder _portForwarder;

  String get xcrunPath => fs.path.join('/usr', 'bin', 'xcrun');

  @override
  bool isSupported() {
    if (!platform.isMacOS) {
      _supportMessage = 'iOS devices require a Mac host machine.';
      return false;
    }

    // Check if the device is part of a blacklisted category.
    // We do not yet support WatchOS or tvOS devices.
    final RegExp blacklist = RegExp(r'Apple (TV|Watch)', caseSensitive: false);
    if (blacklist.hasMatch(name)) {
      _supportMessage = 'Flutter does not support Apple TV or Apple Watch.';
      return false;
    }
    return true;
  }

  String _supportMessage;

  @override
  String supportMessage() {
    if (isSupported()) return 'Supported';

    return _supportMessage ?? 'Unknown';
  }

  String get logFilePath {
    return platform.environment.containsKey('IOS_SIMULATOR_LOG_FILE_PATH')
        ? platform.environment['IOS_SIMULATOR_LOG_FILE_PATH']
            .replaceAll('%{id}', id)
        : fs.path.join(
            homeDirPath, 'Library', 'Logs', 'CoreSimulator', id, 'system.log');
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  Future<String> get sdkNameAndVersion async => simulatorCategory;

  final RegExp _iosSdkRegExp = RegExp(r'iOS( |-)(\d+)');

  Future<int> get sdkMajorVersion async {
    final Match sdkMatch = _iosSdkRegExp.firstMatch(await sdkNameAndVersion);
    return int.parse(sdkMatch?.group(2) ?? '11');
  }

  @override
  DevicePortForwarder get portForwarder =>
      _portForwarder ??= _IOSSimulatorDevicePortForwarder(this);

  @override
  void clearLogs() {
    final File logFile = fs.file(logFilePath);
    if (logFile.existsSync()) {
      final RandomAccessFile randomFile =
          logFile.openSync(mode: FileMode.write);
      randomFile.truncateSync(0);
      randomFile.closeSync();
    }
  }

  Future<void> ensureLogsExists() async {
    if (await sdkMajorVersion < 11) {
      final File logFile = fs.file(logFilePath);
      if (!logFile.existsSync()) logFile.writeAsBytesSync(<int>[]);
    }
  }

  bool get _xcodeVersionSupportsScreenshot {
    return false; //xcode.majorVersion > 8 || (xcode.majorVersion == 8 && xcode.minorVersion >= 2);
  }

  @override
  bool get supportsScreenshot => _xcodeVersionSupportsScreenshot;

  @override
  Future<void> takeScreenshot(File outputFile) {
    return SimControl.instance.takeScreenshot(id, outputFile.path);
  }

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.ios.existsSync();
  }
}

/// Launches the device log reader process on the host.
Future<Process> launchDeviceLogTool(IOSSimulator device) async {
  // Versions of iOS prior to iOS 11 log to the simulator syslog file.
  if (await device.sdkMajorVersion < 11)
    return runCommand(<String>['tail', '-n', '0', '-F', device.logFilePath]);

  // For iOS 11 and above, use /usr/bin/log to tail process logs.
  // Run in interactive mode (via script), otherwise /usr/bin/log buffers in 4k chunks. (radar: 34420207)
  return runCommand(<String>[
    'script',
    '/dev/null',
    '/usr/bin/log',
    'stream',
    '--style',
    'syslog',
    '--predicate',
    'processImagePath CONTAINS "${device.id}"',
  ]);
}

Future<Process> launchSystemLogTool(IOSSimulator device) async {
  // Versions of iOS prior to 11 tail the simulator syslog file.
  if (await device.sdkMajorVersion < 11)
    return runCommand(
        <String>['tail', '-n', '0', '-F', '/private/var/log/system.log']);

  // For iOS 11 and later, all relevant detail is in the device log.
  return null;
}

int compareIosVersions(String v1, String v2) {
  final List<int> v1Fragments = v1.split('.').map<int>(int.parse).toList();
  final List<int> v2Fragments = v2.split('.').map<int>(int.parse).toList();

  int i = 0;
  while (i < v1Fragments.length && i < v2Fragments.length) {
    final int v1Fragment = v1Fragments[i];
    final int v2Fragment = v2Fragments[i];
    if (v1Fragment != v2Fragment) return v1Fragment.compareTo(v2Fragment);
    i += 1;
  }
  return v1Fragments.length.compareTo(v2Fragments.length);
}

/// Matches on device type given an identifier.
///
/// Example device type identifiers:
///   ✓ com.apple.CoreSimulator.SimDeviceType.iPhone-5
///   ✓ com.apple.CoreSimulator.SimDeviceType.iPhone-6
///   ✓ com.apple.CoreSimulator.SimDeviceType.iPhone-6s-Plus
///   ✗ com.apple.CoreSimulator.SimDeviceType.iPad-2
///   ✗ com.apple.CoreSimulator.SimDeviceType.Apple-Watch-38mm
final RegExp _iosDeviceTypePattern =
    RegExp(r'com.apple.CoreSimulator.SimDeviceType.iPhone-(\d+)(.*)');

int compareIphoneVersions(String id1, String id2) {
  final Match m1 = _iosDeviceTypePattern.firstMatch(id1);
  final Match m2 = _iosDeviceTypePattern.firstMatch(id2);

  final int v1 = int.parse(m1[1]);
  final int v2 = int.parse(m2[1]);

  if (v1 != v2) return v1.compareTo(v2);

  // Sorted in the least preferred first order.
  const List<String> qualifiers = <String>['-Plus', '', 's-Plus', 's'];

  final int q1 = qualifiers.indexOf(m1[2]);
  final int q2 = qualifiers.indexOf(m2[2]);
  return q1.compareTo(q2);
}

class _IOSSimulatorDevicePortForwarder extends DevicePortForwarder {
  _IOSSimulatorDevicePortForwarder(this.device);

  final IOSSimulator device;

  final List<ForwardedPort> _ports = <ForwardedPort>[];

  @override
  List<ForwardedPort> get forwardedPorts {
    return _ports;
  }

  @override
  Future<int> forward(int devicePort, {int hostPort}) async {
    if (hostPort == null || hostPort == 0) {
      hostPort = devicePort;
    }
    assert(devicePort == hostPort);
    _ports.add(ForwardedPort(devicePort, hostPort));
    return hostPort;
  }

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    _ports.remove(forwardedPort);
  }
}
