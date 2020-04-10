import 'dart:async';
import '../base/os.dart';
import '../base/file_system.dart';
import '../runner/mpcli_command.dart';

class StartCommand extends MpcliCommand {
  static const timeout = 30;

  @override
  final String name = 'start';

  @override
  final String description = 'Start Web Workflow.';

  @override
  Future<MpcliCommandResult> runCommand() async {
    // kill exist service process
    os.killProcessByName('www.dart');

    var success = true;
    var wpath = fs.path.join(homeResourcePath(), 'wpath');
    ensureDirectoryExists(wpath);
    fs.file(wpath).writeAsStringSync(currentFolderPath());
    final int code = await os.launchWorkflow();
//    final int code = await runCommandAndStreamOutput(
//      <String>['open', '-a', 'Terminal.app', '/Users/anjuke/haijun/Flutter/magpie_workflow/cli/bin/cache/service.sh'],
//      allowReentrantFlutter: true,
//    );
    if (code != 0) {
      print('exitCode: $code');
      success = false;
    }
    return MpcliCommandResult(success ? ExitStatus.success : ExitStatus.fail);
  }
}
