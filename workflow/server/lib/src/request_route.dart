import 'dart:io';

import 'package:jaguar/jaguar.dart';

import 'controller/baseinfo_controller.dart';
import 'controller/debug_controller.dart';
import 'controller/device_controller.dart';
import 'controller/filetree_controller.dart';
import 'controller/res_address.dart';
import 'controller/log_controller.dart';
import 'controller/release_controller.dart';

String workspace = '';

//Add controllers
void handleController(Jaguar server, String buildPath, bool isWebBuild) {
  // 服务是否在线
  server.get(
      '/api/status', (context) => '🏊⚽️🏀🏈⚾️🎾🏐🏉🎱⛳️🏌🏓🏸🏒🏑🏏🎿\n');
  // 其他HTTP服务
  server.addRoute(Route('/api/release/*', (ctx) {
    return ReleaseController().route(ctx.uri.path, ctx);
  }));
  server.get('/', (ctx) {
    return Redirect.found(Uri.parse('/index.html'));
  });
  server.wsStream('/api/log/connect', onLogConnect);
  server.wsStream('/api/log/write_connect', onWriteLogConnect);
  server.wsStream('/api/log/read_connect', onReadLogConnect);
  if (isWebBuild) {
    server.staticFiles('/*', buildPath);
  }
  server.get(api_log_filepath, (ctx) {
    LogFileController().route(ctx.uri.toString(), ctx);
  });
  //设备管理列表
  server.get(api_devices_list, (ctx) {
    return DeviceController().route(ctx.uri.toString(), ctx);
  });
  server.addRoute(Route('/api/baseinfo/*', (ctx) {
    return BaseinfoController().route(ctx.uri.path, ctx);
  }));
  server.get('/api/debug/*', (ctx) {
    return DebugModuleController().route(ctx.uri.toString(), ctx);
  });
  server.get('/api/path', (ctx) => workspace);
  server.get('/api/app', (ctx) => ResAddress().route(ctx.uri.path, ctx));
  server.get(
      '/api/directory', (ctx) => FileTreeController().route(ctx.uri.path, ctx));
}
