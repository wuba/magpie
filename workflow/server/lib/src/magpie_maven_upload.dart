import 'dart:io';
import 'package:args/args.dart';
import 'magpie_utils.dart';
import 'tools/base/file_system.dart';
import 'tools/base/process.dart';

/*  Des: upload aar to maven
 *  Args:
    -t :  help: 'local dart project path'

 * Example:
    "-t",
    "/Users/sac/magpie/example"
 */

Future<int> magpieMavenUpload(List<String> args) async {
  ArgResults argResults = await parseArgs(args);
  String targetPath = argResults['targetPath'];
  String versionTag = argResults['version'];
  String buildMode = argResults['buildMode'];

  if (targetPath == null) {
    targetPath = '.';
  }

  //目标目录
  Directory targetPathDir = fs.directory(targetPath);
  bool targetExist = await targetPathDir.exists();
  if (!targetExist) {
    print('目标目录不存在');
    return -1;
  }

  final List<String> gradleCommand = <String>[
    './gradlew',
    'publishM1PublicationToMavenRepository'
  ];

  gradleCommand.add('-PaarBuildType=$buildMode');;

  if(versionTag != null){
    gradleCommand.add('-PversionTag=$versionTag');
  }

  int taskResult = await processUtils.stream(
      gradleCommand,
    trace: true,
    workingDirectory: targetPathDir.childDirectory('android_magpie').path
  );
  if (taskResult == 0) {
    print('aar上传maven成功');
    return 1;
  } else {
    print('aar上传maven失败');
    return -1;
  }
}
