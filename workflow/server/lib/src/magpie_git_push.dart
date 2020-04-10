import 'dart:io';
import 'package:args/args.dart';
import 'magpie_utils.dart';
import 'tools/base/file_system.dart';
import 'tools/base/process.dart';

/* Des: Copy Product Folder To Local Path And Git Push
 * Args:
    -t :  help: 'local dart project path'
    -m :  help: 'build mode'  defaultsTo: "release"
    -l :  help: 'git local path'
    -s :  help: 'git response'
    -v :  help: 'Git tag name'

 * Example:
    "-t",
    "/Users/sac/magpie/example",
    "-l",
    "/Users/sac/magpie_ios_framework",
    "-s",
    "https://github.com/wuba/magpie_ios_framework.git",
    "-m",
    "debug",
    "-v",
    "1.0.0",
 */

Future<int> magpieGitPush(List<String> args) async {
  ArgResults argResults = await parseArgs(args);
  String targetPath = argResults['targetPath'];
  String buildMode = argResults['buildMode'];
  String source = argResults['source'];
  String localPath = argResults['localPath'];
  String version = argResults['version'];
  if (targetPath == null) {
    targetPath = '.';
  }
  if (buildMode == null) {
    print('Error: Please use -m to set the build mode');
    return Future.value(-1);
  }
  if (source == null) {
    print('Error: Please use -s to set the git path');
    return Future.value(-1);
  }
  if (localPath == null) {
    print('Error: Please use -l to set the local path');
    return Future.value(-1);
  }
  if (version == null) {
    print('Error: Please use -v to set a branch or tag');
    return Future.value(-1);
  }

  pathHelper.configWithData(targetPath, buildMode);
  String productPath = pathHelper.productPath;

  //目标目录 clone
  Directory localPathDir = fs.directory(localPath);
  await localPathDir.create();

  final List<String> cloneCommand = <String>[
    'git',
    'clone',
    '${source}',
    '${localPath}',
    '--template=',
    '--single-branch',
    '--depth',
    '1',
  ];
  int cloneResult = await processUtils.stream(
    cloneCommand,
    trace: true,
  );
  if (cloneResult == 0) {
    print('git clone成功');
  } else {
    print('git clone失败');
  }

  //Del
  final List<String> delCommand = <String>[
    'rm',
    '-rf',
    '${localPath}/product',
  ];
  int deleteResult = await processUtils.stream(delCommand,
      trace: true, workingDirectory: '${localPath}');
  if (deleteResult == 0) {
    print('清理Product目录成功');
  } else {
    print('清理Product目录失败');
  }

  //Copy File
  await copyFile(['-r', '--'], productPath, '${localPath}', null);

  //Add
  final List<String> addCommand = <String>[
    'git',
    'add',
    '${localPath}/product',
  ];
  int addResult = await processUtils.stream(addCommand,
      trace: true, workingDirectory: '${localPath}');
  if (addResult == 0) {
    print('git add成功');
  } else {
    print('git add失败');
  }

  //Commit
  final List<String> commitCommand = <String>[
    'git',
    'commit',
    '-m',
    'Workflow Product ${version}',
  ];
  int commitResult = await processUtils.stream(commitCommand,
      trace: true, workingDirectory: '${localPath}');
  if (commitResult == 0) {
    print('git commit成功');
  } else {
    print('git commit失败');
  }

  //Tag
  final List<String> delTagCommand = <String>[
    'git',
    'tag',
    '-d',
    '${version}',
  ];
  int delResult = await processUtils.stream(delTagCommand,
      trace: true, workingDirectory: '${localPath}');
  final List<String> delOriginTagCommand = <String>[
    'git',
    'push',
    'origin',
    ':refs/tags/${version}',
  ];
  int delOriginResult = await processUtils.stream(delOriginTagCommand,
      trace: true, workingDirectory: '${localPath}');

  final List<String> tagCommand = <String>[
    'git',
    'tag',
    '-a',
    '${version}',
    '-m',
    'Workflow Product ${version}',
  ];
  int tagResult = await processUtils.stream(tagCommand,
      trace: true, workingDirectory: '${localPath}');
  if (tagResult == 0) {
    print('git tag成功');
  } else {
    print('git tag失败');
  }

  //Push
  final List<String> pushCommand = <String>[
    'git',
    'push',
    'origin',
    '${version}',
  ];
  int pushResult = await processUtils.stream(pushCommand,
      trace: true, workingDirectory: '${localPath}');
  if (pushResult == 0) {
    print('git push成功');
    return 1;
  } else {
    print('git push失败');
    return -1;
  }
}
