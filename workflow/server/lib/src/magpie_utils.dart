// import 'dart:html';
import 'dart:io';
import 'dart:async';
import 'package:args/args.dart';
import 'tools/base/file_system.dart';
import 'tools/base/process.dart';

MagpiePathHelper get pathHelper => MagpiePathHelper.getInstance();

enum DarwinArch {
  armv7,
  arm64,
  x86_64,
}

class MagpiePathHelper {
  static MagpiePathHelper _instance;
  static MagpiePathHelper getInstance() {
    _instance ??= MagpiePathHelper();
    return _instance;
  }

  String buildPath;
  String productPath;
  String productAppPath;
  String targetFile;
  String assetsPath;
  void configWithData(
    String targetPath,
    String buildMode,
  ) {
    this.buildPath = "${targetPath}/.build_ios/${buildMode}";
    this.productPath = "${buildPath}/product";
    this.productAppPath = "${productPath}/App.framework";
    this.targetFile = "${targetPath}/lib/main.dart";
    this.assetsPath = "${productAppPath}/flutter_assets";
  }
}

Future<ArgResults> parseArgs(List<String> args) async {
  ArgParser argParser = ArgParser();
  argParser.addOption('targetPath',
      abbr: 't', defaultsTo: null, help: 'local dart project path');
  argParser.addOption('flutterroot',
      abbr: 'f', defaultsTo: null, help: 'local flutter install path');
  argParser.addOption('buildMode',
      abbr: 'm', defaultsTo: "release", help: 'build mode');
  argParser.addOption('localPath',
      abbr: 'l', defaultsTo: null, help: 'local path');
  argParser.addOption('source',
      abbr: 's', defaultsTo: null, help: 'git respon');
  argParser.addOption('version',
      abbr: 'v', defaultsTo: null, help: 'Git tag name');
  ArgResults argResults = argParser.parse(args);
  return argResults;
}

//复制
void copyFile(List<String> params, String targetPath, destinationPath,
    Map<String, String> env) async {
  print("正在拷贝${targetPath} 至${destinationPath}");
  int copyResult = await processUtils.stream(
    ['cp', ...params, targetPath, destinationPath],
    trace: true,
    environment: env,
  );
  if (copyResult == 0) {
    print("${targetPath} 拷贝完成");
  } else {
    print("${targetPath} 拷贝失败");
  }
}

//文件是否存在
Future<bool> fileExsit(String filePath) async {
  File file = fs.file(filePath);
  var ret = await file.exists(); //返回真假
  return ret;
}

//Flutter pub get
void pubGet(String flutterRoot, Map<String, String> iosDeployEnv,
    String targetPath) async {
  print('更新插件..');
  final List cleanCommand = <String>[
    '${flutterRoot}/bin/flutter',
    'pub',
    'get'
  ];
  //清理
  var cleanResult = await processUtils.stream(
    cleanCommand,
    trace: true,
    environment: iosDeployEnv,
    workingDirectory: targetPath,
  );
  if (cleanResult == 0) {
    print('更新插件成功');
  }
}
