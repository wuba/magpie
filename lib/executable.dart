// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'runner.dart' as runner;
import 'src/base/context.dart';
// The build_runner code generation is provided here to make it easier to
// avoid introducing the dependency into google3. Not all build* packages
// are synced internally.
import 'src/commands/clean.dart';
import 'src/commands/create.dart';
import 'src/commands/devices.dart';
import 'src/commands/doctor.dart';
import 'src/commands/version.dart';
import 'src/commands/start.dart';
import 'src/commands/service.dart';
import 'src/runner/mpcli_command.dart';

/// Main entry point for commands.
///
/// This function is intended to be used from the `mgpcli` command line tool.
Future<void> main(List<String> args) async {
  final bool verbose = args.contains('-v') || args.contains('--verbose');

  final bool doctor = (args.isNotEmpty && args.first == 'doctor') ||
      (args.length == 2 && verbose && args.last == 'doctor');
  final bool help = args.contains('-h') ||
      args.contains('--help') ||
      (args.isNotEmpty && args.first == 'help') ||
      (args.length == 1 && verbose);
  final bool muteCommandLogging = help || doctor;
  final bool verboseHelp = help && verbose;

  await runner.run(
      args,
      <MpcliCommand>[
        // AnalyzeCommand(verboseHelp: verboseHelp),
        CleanCommand(),
        CreateCommand(),
        DevicesCommand(),
        DoctorCommand(verbose: verbose),
        VersionCommand(),
        StartCommand(),
        ServiceCommand(),
      ],
      verbose: verbose,
      muteCommandLogging: muteCommandLogging,
      verboseHelp: verboseHelp,
      overrides: <Type, Generator>{
        // The build runner instance is not supported in google3 because
        // the build runner packages are not synced internally.
      });
}
