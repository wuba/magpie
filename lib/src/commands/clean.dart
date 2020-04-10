import 'dart:async';
import '../base/file_system.dart';
import '../globals.dart';
import '../project.dart';
import '../runner/mpcli_command.dart';
import '../cache.dart';
import '../base/process.dart';
import '../../utils/util.dart';

class CleanCommand extends MpcliCommand {
  CleanCommand() {
    //  requiresPubspecYaml();
  }

  @override
  final String name = 'clean';

  @override
  final String description =
      '1、Delete the build/ and .dart_tool/ directories.  2、pub get';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async =>
      const <DevelopmentArtifact>{};

  @override
  Future<MpcliCommandResult> runCommand() async {
    var status = ExitStatus.success;
    if (cliEnvironment() == CliEnvironment.debug) {
      final FlutterProject flutterProject = FlutterProject.current();
      final Directory buildDir = fs.directory(flutterProject.dartTool.path);
      deleteFile(buildDir);
      final int code = await runCommandAndStreamOutput(
        <String>['pub', 'get'],
        workingDirectory: Cache.mpcliRoot,
        allowReentrantFlutter: true,
      );
      if (code != 0) {
        printStatus('exitCode: $code');
        status = ExitStatus.fail;
      } else {
        status = ExitStatus.success;
        printStatus("Clean Success.");
      }
    } else {
      final Directory resourceDir = fs.directory(homeResourcePath());
      deleteFile(resourceDir);
      printStatus("Clean Success.");
    }
    return MpcliCommandResult(status);
  }
}
