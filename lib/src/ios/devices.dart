// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import 'code_signing.dart';
import 'ios_workflow.dart';
import 'mac.dart';

class IOSDeploy {
  const IOSDeploy();

  /// Installs and runs the specified app bundle using ios-deploy, then returns
  /// the exit code.
  Future<int> runApp({
    @required String deviceId,
    @required String bundlePath,
    @required List<String> launchArguments,
  }) async {
    final String iosDeployPath = artifacts.getArtifactPath(Artifact.iosDeploy,
        platform: TargetPlatform.ios);
    // TODO(fujino): remove fallback once g3 updated
    const List<String> fallbackIosDeployPath = <String>[
      '/usr/bin/env',
      'ios-deploy',
    ];
    final List<String> commandList =
        iosDeployPath != null ? <String>[iosDeployPath] : fallbackIosDeployPath;
    final List<String> launchCommand = <String>[
      ...commandList,
      '--id',
      deviceId,
      '--bundle',
      bundlePath,
      '--no-wifi',
      '--justlaunch',
    ];
    if (launchArguments.isNotEmpty) {
      launchCommand.add('--args');
      launchCommand.add('${launchArguments.join(" ")}');
    }

    // Push /usr/bin to the front of PATH to pick up default system python, package 'six'.
    //
    // ios-deploy transitively depends on LLDB.framework, which invokes a
    // Python script that uses package 'six'. LLDB.framework relies on the
    // python at the front of the path, which may not include package 'six'.
    // Ensure that we pick up the system install of python, which does include
    // it.
    final Map<String, String> iosDeployEnv =
        Map<String, String>.from(platform.environment);
    iosDeployEnv['PATH'] = '/usr/bin:${iosDeployEnv['PATH']}';
    iosDeployEnv.addEntries(<MapEntry<String, String>>[cache.dyLdLibEntry]);

    return await runCommandAndStreamOutput(
      launchCommand,
      mapFunction: _monitorInstallationFailure,
      trace: true,
      environment: iosDeployEnv,
    );
  }

  // Maps stdout line stream. Must return original line.
  String _monitorInstallationFailure(String stdout) {
    // Installation issues.
    if (stdout.contains('Error 0xe8008015') ||
        stdout.contains('Error 0xe8000067')) {
      printError(noProvisioningProfileInstruction, emphasis: true);

      // Launch issues.
    } else if (stdout.contains('e80000e2')) {
      printError('''
═══════════════════════════════════════════════════════════════════════════════════
Your device is locked. Unlock your device first before running.
═══════════════════════════════════════════════════════════════════════════════════''',
          emphasis: true);
    } else if (stdout.contains('Error 0xe8000022')) {
      printError('''
═══════════════════════════════════════════════════════════════════════════════════
Error launching app. Try launching from within Xcode via:
    open ios/Runner.xcworkspace

Your Xcode version may be too old for your iOS version.
═══════════════════════════════════════════════════════════════════════════════════''',
          emphasis: true);
    }

    return stdout;
  }
}

class IOSDevices extends PollingDeviceDiscovery {
  IOSDevices() : super('iOS devices');

  @override
  bool get supportsPlatform => platform.isMacOS;

  @override
  bool get canListAnything => iosWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() => IOSDevice.getAttachedDevices();
}

class IOSDevice extends Device {
  IOSDevice(String id, {this.name, String sdkVersion})
      : _sdkVersion = sdkVersion,
        super(
          id,
          category: Category.mobile,
          platformType: PlatformType.ios,
          ephemeral: true,
        ) {
    if (!platform.isMacOS) {
      assert(false,
          'Control of iOS devices or simulators only supported on Mac OS.');
      return;
    }
    _installerPath = artifacts.getArtifactPath(
          Artifact.ideviceinstaller,
          platform: TargetPlatform.ios,
        ) ??
        'ideviceinstaller'; // TODO(fujino): remove fallback once g3 updated
    _iproxyPath = artifacts.getArtifactPath(Artifact.iproxy,
            platform: TargetPlatform.ios) ??
        'iproxy'; // TODO(fujino): remove fallback once g3 updated
  }

  String _installerPath;
  String _iproxyPath;

  final String _sdkVersion;

  @override
  bool get supportsHotReload => true;

  @override
  bool get supportsHotRestart => true;

  @override
  final String name;

  DevicePortForwarder _portForwarder;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get emulatorId async => null;

  @override
  bool get supportsStartPaused => false;

  static Future<List<IOSDevice>> getAttachedDevices() async {
    if (!platform.isMacOS) {
      throw UnsupportedError(
          'Control of iOS devices or simulators only supported on Mac OS.');
    }
    if (!iMobileDevice.isInstalled) return <IOSDevice>[];

    final List<IOSDevice> devices = <IOSDevice>[];
    for (String id
        in (await iMobileDevice.getAvailableDeviceIDs()).split('\n')) {
      id = id.trim();
      if (id.isEmpty) continue;

      try {
        final String deviceName =
            await iMobileDevice.getInfoForDevice(id, 'DeviceName');
        final String sdkVersion =
            await iMobileDevice.getInfoForDevice(id, 'ProductVersion');
        devices.add(IOSDevice(id, name: deviceName, sdkVersion: sdkVersion));
      } on IOSDeviceNotFoundError catch (error) {
        // Unable to find device with given udid. Possibly a network device.
        printTrace('Error getting attached iOS device: $error');
      } on IOSDeviceNotTrustedError catch (error) {
        printTrace('Error getting attached iOS device information: $error');
        UsageEvent('device', 'ios-trust-failure').send();
      }
    }
    return devices;
  }

  @override
  bool isSupported() => true;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  Future<String> get sdkNameAndVersion async => 'iOS $_sdkVersion';

  @override
  DevicePortForwarder get portForwarder =>
      _portForwarder ??= _IOSDevicePortForwarder(this);

  @visibleForTesting
  set portForwarder(DevicePortForwarder forwarder) {
    _portForwarder = forwarder;
  }

  @override
  void clearLogs() {}

  @override
  bool get supportsScreenshot => iMobileDevice.isInstalled;

  @override
  Future<void> takeScreenshot(File outputFile) async {
    await iMobileDevice.takeScreenshot(outputFile);
  }

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.ios.existsSync();
  }
}

/// Decodes a vis-encoded syslog string to a UTF-8 representation.
///
/// Apple's syslog logs are encoded in 7-bit form. Input bytes are encoded as follows:
/// 1. 0x00 to 0x19: non-printing range. Some ignored, some encoded as <...>.
/// 2. 0x20 to 0x7f: as-is, with the exception of 0x5c (backslash).
/// 3. 0x5c (backslash): octal representation \134.
/// 4. 0x80 to 0x9f: \M^x (using control-character notation for range 0x00 to 0x40).
/// 5. 0xa0: octal representation \240.
/// 6. 0xa1 to 0xf7: \M-x (where x is the input byte stripped of its high-order bit).
/// 7. 0xf8 to 0xff: unused in 4-byte UTF-8.
///
/// See: [vis(3) manpage](https://www.freebsd.org/cgi/man.cgi?query=vis&sektion=3)
String decodeSyslog(String line) {
  // UTF-8 values for \, M, -, ^.
  const int kBackslash = 0x5c;
  const int kM = 0x4d;
  const int kDash = 0x2d;
  const int kCaret = 0x5e;

  // Mask for the UTF-8 digit range.
  const int kNum = 0x30;

  // Returns true when `byte` is within the UTF-8 7-bit digit range (0x30 to 0x39).
  bool isDigit(int byte) => (byte & 0xf0) == kNum;

  // Converts a three-digit ASCII (UTF-8) representation of an octal number `xyz` to an integer.
  int decodeOctal(int x, int y, int z) =>
      (x & 0x3) << 6 | (y & 0x7) << 3 | z & 0x7;

  try {
    final List<int> bytes = utf8.encode(line);
    final List<int> out = <int>[];
    for (int i = 0; i < bytes.length;) {
      if (bytes[i] != kBackslash || i > bytes.length - 4) {
        // Unmapped byte: copy as-is.
        out.add(bytes[i++]);
      } else {
        // Mapped byte: decode next 4 bytes.
        if (bytes[i + 1] == kM && bytes[i + 2] == kCaret) {
          // \M^x form: bytes in range 0x80 to 0x9f.
          out.add((bytes[i + 3] & 0x7f) + 0x40);
        } else if (bytes[i + 1] == kM && bytes[i + 2] == kDash) {
          // \M-x form: bytes in range 0xa0 to 0xf7.
          out.add(bytes[i + 3] | 0x80);
        } else if (bytes.getRange(i + 1, i + 3).every(isDigit)) {
          // \ddd form: octal representation (only used for \134 and \240).
          out.add(decodeOctal(bytes[i + 1], bytes[i + 2], bytes[i + 3]));
        } else {
          // Unknown form: copy as-is.
          out.addAll(bytes.getRange(0, 4));
        }
        i += 4;
      }
    }
    return utf8.decode(out);
  } catch (_) {
    // Unable to decode line: return as-is.
    return line;
  }
}

class _IOSDevicePortForwarder extends DevicePortForwarder {
  _IOSDevicePortForwarder(this.device) : _forwardedPorts = <ForwardedPort>[];

  final IOSDevice device;

  final List<ForwardedPort> _forwardedPorts;

  @override
  List<ForwardedPort> get forwardedPorts => _forwardedPorts;

  static const Duration _kiProxyPortForwardTimeout = Duration(seconds: 1);

  @override
  Future<int> forward(int devicePort, {int hostPort}) async {
    final bool autoselect = hostPort == null || hostPort == 0;
    if (autoselect) hostPort = 1024;

    Process process;

    bool connected = false;
    while (!connected) {
      printTrace(
          'attempting to forward device port $devicePort to host port $hostPort');
      // Usage: iproxy LOCAL_TCP_PORT DEVICE_TCP_PORT UDID
      process = await runCommand(
        <String>[
          device._iproxyPath,
          hostPort.toString(),
          devicePort.toString(),
          device.id,
        ],
        environment: Map<String, String>.fromEntries(
          <MapEntry<String, String>>[cache.dyLdLibEntry],
        ),
      );
      // TODO(ianh): This is a flakey race condition, https://github.com/libimobiledevice/libimobiledevice/issues/674
      connected = !await process.stdout.isEmpty
          .timeout(_kiProxyPortForwardTimeout, onTimeout: () => false);
      if (!connected) {
        if (autoselect) {
          hostPort += 1;
          if (hostPort > 65535)
            throw Exception('Could not find open port on host.');
        } else {
          throw Exception('Port $hostPort is not available.');
        }
      }
    }
    assert(connected);
    assert(process != null);

    final ForwardedPort forwardedPort = ForwardedPort.withContext(
      hostPort,
      devicePort,
      process,
    );
    printTrace('Forwarded port $forwardedPort');
    _forwardedPorts.add(forwardedPort);
    return hostPort;
  }

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    if (!_forwardedPorts.remove(forwardedPort)) {
      // Not in list. Nothing to remove.
      return;
    }

    printTrace('Unforwarding port $forwardedPort');

    final Process process = forwardedPort.context;

    if (process != null) {
      processManager.killPid(process.pid);
    } else {
      printError('Forwarded port did not have a valid process');
    }
  }
}
