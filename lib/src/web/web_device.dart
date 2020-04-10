// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/io.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../device.dart';
import '../features.dart';
import '../project.dart';
import 'chrome.dart';
import 'workflow.dart';

class ChromeDevice extends Device {
  ChromeDevice()
      : super(
          'chrome',
          category: Category.web,
          platformType: PlatformType.web,
          ephemeral: false,
        );

  // TODO(jonahwilliams): this is technically false, but requires some refactoring
  // to allow hot mode restart only devices.
  @override
  bool get supportsHotReload => true;

  @override
  bool get supportsHotRestart => true;

  @override
  bool get supportsStartPaused => true;

  @override
  bool get supportsFlutterExit => true;

  @override
  bool get supportsScreenshot => false;

  @override
  void clearLogs() {}

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get emulatorId async => null;

  @override
  bool isSupported() => featureFlags.isWebEnabled && canFindChrome();

  @override
  String get name => 'Chrome';

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async {
    if (!isSupported()) {
      return 'unknown';
    }
    // See https://bugs.chromium.org/p/chromium/issues/detail?id=158372
    String version = 'unknown';
    if (platform.isWindows) {
      final ProcessResult result = await processManager.run(<String>[
        r'reg',
        'query',
        'HKEY_CURRENT_USER\\Software\\Google\\Chrome\\BLBeacon',
        '/v',
        'version'
      ]);
      if (result.exitCode == 0) {
        final List<String> parts = result.stdout.split(RegExp(r'\s+'));
        if (parts.length > 2) {
          version = 'Google Chrome ' + parts[parts.length - 2];
        }
      }
    } else {
      final String chrome = findChromeExecutable();
      final ProcessResult result = await processManager.run(<String>[
        chrome,
        '--version',
      ]);
      if (result.exitCode == 0) {
        version = result.stdout;
      }
    }
    return version;
  }

  @override
  Future<TargetPlatform> get targetPlatform async =>
      TargetPlatform.web_javascript;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.web.existsSync();
  }
}

class WebDevices extends PollingDeviceDiscovery {
  WebDevices() : super('chrome');

  final ChromeDevice _webDevice = ChromeDevice();

  @override
  bool get canListAnything => featureFlags.isWebEnabled;

  @override
  Future<List<Device>> pollingGetDevices() async {
    return <Device>[
      _webDevice,
    ];
  }

  @override
  bool get supportsPlatform => featureFlags.isWebEnabled;
}

@visibleForTesting
String parseVersionForWindows(String input) {
  return input.split(RegExp('\w')).last;
}
