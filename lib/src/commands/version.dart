import 'dart:async';

import '../base/common.dart';
import '../base/process.dart';
import '../globals.dart';
import '../runner/mpcli_command.dart';
import '../version.dart';
import '../../utils/util.dart';

class VersionCommand extends MpcliCommand {
  VersionCommand() : super() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help:
          'Force switch to older Flutter versions that do not include a version command',
    );
  }

  @override
  final String name = 'version';

  @override
  final String description = 'List mgpcli and dependencies tools versions.';

  @override
  Future<MpcliCommandResult> runCommand() async {
    final FlutterVersion flutterVersion = FlutterVersion();

    printStatus('');
    printStatus('');
    //engine version
    printStatus('Engine version ${flutterVersion.engineRevision}');

    //Dart Version
    printStatus('Dart version ${flutterVersion.dartSdkVersion}');

    //Mpcli Version
    printStatus('Mpcli version ${cliVersion}');

    // Run a doctor check in case system requirements have changed.
    printStatus('');
    printStatus('Running flutter doctor...');
    int code = await runCommandAndStreamOutput(
      <String>['flutter', 'doctor'],
      allowReentrantFlutter: true,
    );

    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }

    return const MpcliCommandResult(ExitStatus.success);
  }
}
