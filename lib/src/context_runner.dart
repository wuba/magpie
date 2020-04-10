// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'android/android_sdk.dart';
import 'android/android_studio.dart';
import 'android/android_workflow.dart';
import 'artifacts.dart';
import 'base/config.dart';
import 'base/context.dart';
import 'base/flags.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/time.dart';
import 'base/user_messages.dart';
import 'base/utils.dart';
import 'cache.dart';
import 'device.dart';
import 'doctor.dart';
import 'features.dart';
import 'ios/ios_workflow.dart';
import 'ios/mac.dart';
import 'ios/simulators.dart';
import 'ios/xcodeproj.dart';
import 'macos/cocoapods.dart';
import 'macos/cocoapods_validator.dart';
import 'macos/macos_workflow.dart';
import 'macos/xcode.dart';
import 'macos/xcode_validator.dart';
import 'reporting/reporting.dart';
import 'version.dart';
import 'web/chrome.dart';
import 'web/workflow.dart';

Future<T> runInContext<T>(
  FutureOr<T> runner(), {
  Map<Type, Generator> overrides,
}) async {
  return await context.run<T>(
    name: 'global fallbacks',
    body: runner,
    overrides: overrides,
    fallbacks: <Type, Generator>{
      Cache: () => Cache(),
      AndroidLicenseValidator: () => AndroidLicenseValidator(),
      AndroidSdk: AndroidSdk.locateAndroidSdk,
      AndroidStudio: AndroidStudio.latestValid,
      AndroidValidator: () => AndroidValidator(),
      AndroidWorkflow: () => AndroidWorkflow(),
      Artifacts: () => CachedArtifacts(),
      BotDetector: () => const BotDetector(),
      ChromeLauncher: () => const ChromeLauncher(),
      CocoaPods: () => CocoaPods(),
      CocoaPodsValidator: () => const CocoaPodsValidator(),
      Config: () => Config(),
      DeviceManager: () => DeviceManager(),
      Doctor: () => const Doctor(),
      DoctorValidatorsProvider: () => DoctorValidatorsProvider.defaultInstance,
      FeatureFlags: () => const FeatureFlags(),
      Flags: () => const EmptyFlags(),
      FlutterVersion: () => FlutterVersion(const SystemClock()),
      IMobileDevice: () => IMobileDevice(),
      IOSSimulatorUtils: () => IOSSimulatorUtils(),
      IOSWorkflow: () => const IOSWorkflow(),
      Logger: () => platform.isWindows ? WindowsStdoutLogger() : StdoutLogger(),
      MacOSWorkflow: () => const MacOSWorkflow(),
      OperatingSystemUtils: () => OperatingSystemUtils(),
      SimControl: () => SimControl(),
      Stdio: () => const Stdio(),
      SystemClock: () => const SystemClock(),
      TimeoutConfiguration: () => const TimeoutConfiguration(),
      Usage: () => Usage(),
      UserMessages: () => UserMessages(),
      WebWorkflow: () => const WebWorkflow(),
      Xcode: () => Xcode(),
      XcodeValidator: () => const XcodeValidator(),
      XcodeProjectInterpreter: () => XcodeProjectInterpreter(),
    },
  );
}
