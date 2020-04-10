import 'dart:io';

import 'package:args/args.dart';
import 'package:jaguar/jaguar.dart';
import 'package:logging/logging.dart';

import 'src/controller/log_controller.dart';
import 'src/daemon/device.dart';
import 'src/interceptor/common_after_interceptor.dart';
import 'src/interceptor/common_before_interceptor.dart';
import 'src/interceptor/static_assets_interptor.dart';
import 'src/request_route.dart';
import 'src/utils/logger.dart';

final address = '0.0.0.0';
final port = 8080;

Future main(List<String> arguments) async {
  _logConfig();
  final parser = ArgParser()
    ..addOption('resource', abbr: 'r', defaultsTo: '../build/web/')
    ..addOption('workspace', abbr: 'w');
  ArgResults argResults = parser.parse(arguments);
  final dir = argResults['resource'];
  workspace = argResults['workspace'];
  final sites = Platform.script.resolve(dir).toFilePath();
  var dicExist = await Directory(sites).exists();
  print('${sites}');
  final server = Jaguar(address: address, port: port);
  requestHandler(server, sites, isWebBuild: dicExist);
  await server.serve();
  LoggerUtil.i('Serving on http://$address:$port');
  await FlutterDaemon().attach();
  LoggerUtil.i('flutter is ready');
}

void _logConfig() {
  //监听器能监听的范围
  Logger.root.level = Level.ALL;
  //日志监听器
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level}::${rec.time}::${rec.message}');
    var name = rec.level.value >= Level.SEVERE.value ? "ERROR" : rec.level.name;
    logToClient(name, rec.message, rec.time);
  });
}

void requestHandler(Jaguar server, String path, {bool isWebBuild}) async {
  print('isWebBuild=$isWebBuild');
  server.onException.add((ctx, e, trace) {
    LoggerUtil.i(e.toString()); //错误处理
  });
  server.before.add((ctx) {
    CommonBeforeInterceptor().call(ctx);
  });

  server.after.add((ctx) {
    CommonAfterInterceptor().call(ctx);
    StaticAssetsInterceptor().call(ctx);
  });

  handleController(server, path, isWebBuild);
}
