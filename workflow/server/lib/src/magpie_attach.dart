import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'tools/base/platform.dart';
import 'tools/base/process.dart';
import 'utils/logger.dart';

enum DebugActionType {pubGet, attach, attach_reload, refresh, reload}

typedef MagpieDebugCallback = void Function(bool success, DebugActionType type);

Future<void> magpieAttach(
    List<String> args, MagpieDebugCallback callback) async {
  ArgParser argParser = ArgParser();
  argParser
    ..addOption('directory',
        abbr: 'd', defaultsTo: null, help: 'working directory')
    ..addOption('flutterroot',
        abbr: 'f', defaultsTo: null, help: 'local flutter install path')
    ..addOption('target',
        abbr: 't', defaultsTo: null, help: 'entry target file')
    ..addOption('device', abbr: 'e', help: 'target device');
  ArgResults argResults = await argParser.parse(args);
  String flutterRoot = argResults['flutterroot'];
  String directory = argResults['directory'];
  String targetFile = argResults['target'];
  String deviceStr = argResults['device'];

  if (!await magpiePubGet(directory, deviceStr)) {
    callback(false, DebugActionType.pubGet);
    return;
  }

  final Map<String, String> iosDeployEnv =
      Map<String, String>.from(platform.environment);
  final String flutterPath = (flutterRoot == null || flutterRoot == '')
      ? 'flutter'
      : '${flutterRoot}/bin/flutter';
  final String pidFileStr = '${directory}/magpie_pid_file';
  final List<String> attachCommand = <String>[flutterPath, 'attach'];
  if (targetFile != null && targetFile != '') {
    attachCommand.add('--target=${targetFile}');
  }
  attachCommand.add('--device-id=${deviceStr}');
  attachCommand.add('--pid-file=${pidFileStr}');

  Process attachProcess = await processUtils.start(
    attachCommand,
    workingDirectory: directory,
    environment: iosDeployEnv,
  );
  Stream<List<int>> outStream = attachProcess.stdout.asBroadcastStream();
  Stream<List<int>> errStream = attachProcess.stderr.asBroadcastStream();
  errStream.transform(utf8.decoder).listen((data){
    LoggerUtil.e('attach_error===>' + data);
  });
  if (await whenTrue(outStream, 'To detach')) {
    await magpieReload(['-d${directory}', '-mreload'].toList(), callback, DebugActionType.attach_reload);
  } else {
    callback(false, DebugActionType.attach);
  }
}

Future<bool> magpiePubGet(String directory, String deviceID) async {
  final Map<String, String> iosDeployEnv =
      Map<String, String>.from(platform.environment);
  Process getProcess = await processUtils.start(
    <String>['flutter', 'pub', 'get', '--device-id=${deviceID}'],
    workingDirectory: directory,
    environment: iosDeployEnv,
  );
  Stream<List<int>> outStream = getProcess.stdout.asBroadcastStream();
  Stream<List<int>> errStream = getProcess.stderr.asBroadcastStream();
  errStream.transform(utf8.decoder).listen((data){
    LoggerUtil.e('pubGet_error===>' + data);
  });
  outStream.transform(utf8.decoder).listen((String dataStr) {
    LoggerUtil.w('pubGet_warning===>' + dataStr);
  });
  int exitCode = await getProcess.exitCode;
  if (exitCode == 0) {
    return true;
  }
  return false;
}

Future<bool> whenTrue(Stream<List<int>> source, String rexStr) async {
  String data =
      await source.transform(utf8.decoder).firstWhere((String singleStr) {
    LoggerUtil.w('attach_warning===>' + singleStr);
    return singleStr.contains(rexStr);
  }, orElse: () => '');
  return data.isNotEmpty;
}

Future handlePidFile(String filePath) async {
  if (filePath == null || filePath == '') {
    throw AssertionError('filePath cannot be empty');
  }
  File file = File(filePath);
  /// 如果文件存在，删除
  if (await file.exists()) {
    await file.delete();
  }
  /// 创建文件
  file = await file.create();
}

Future<void> magpieReload(
    List<String> args, MagpieDebugCallback callback, DebugActionType type) async {
  ArgParser argParser = ArgParser();
  argParser
    ..addOption('directory',
        abbr: 'd', defaultsTo: null, help: 'working directory')
    ..addOption('method',
        abbr: 'm', defaultsTo: null, help: 'reload or refresh');
  ArgResults argResults = await argParser.parse(args);
  String directory = argResults['directory'];
  String method = argResults['method'];
  final String pidFileStr = '${directory}/magpie_pid_file';
  String signalStr = method == 'refresh' ? '-USR1' : '-USR2';
  String pidStr = await getPid(pidFileStr);
  final Map<String, String> iosDeployEnv =
      Map<String, String>.from(platform.environment);

  final List<String> attachCommand = <String>['kill', signalStr, pidStr];

  int attachResult = await processUtils.stream(
    attachCommand,
    trace: true,
    environment: iosDeployEnv,
  );
  if (attachResult == 0) {
    callback(true, type);
  } else {
    callback(false, type);
  }
}

Future<String> getPid(String filePath) async {
  File file = File(filePath);
  String pidStr = await file.readAsString();
  return pidStr;
}
