import 'dart:convert';
import 'package:jaguar/http/context/context.dart';

import 'base_controller.dart';
import '../response_bean.dart';
import '../magpie_attach.dart' as magpie_attach_tool;

final API_DEBUG_ATTACH = '/api/debug/attach';
final API_DEBUG_REFRESH = '/api/debug/refresh';
final API_DEBUG_RELOAD = '/api/debug/reload';

class DebugModuleController extends BaseController {
  route(String path, Context context) async {
    ResponseBean bean = ResponseBean('', code: 0);
    if (match(context.uri.path, API_DEBUG_ATTACH)) {
      String directoryStr = context.query.get('directory');
      String targetFileStr = context.query.get('target');
      String deviceStr = context.query.get('device');
      await magpie_attach_tool.magpieAttach(
          ['-d${directoryStr}', '-t${targetFileStr}', '-e${deviceStr}']
              .toList(), (success, type) {
        bean = handleCallBack(success, type);
      });
    } else if (match(context.uri.path, API_DEBUG_RELOAD)) {
      String directoryStr = context.query.get('directory');
      await magpie_attach_tool
          .magpieReload(['-d${directoryStr}', '-mreload'].toList(), (success, type) {
        bean = handleCallBack(success, type);
      }, magpie_attach_tool.DebugActionType.reload);
    } else if (match(context.uri.path, API_DEBUG_REFRESH)) {
      String directoryStr = context.query.get('directory');
      await magpie_attach_tool
          .magpieReload(['-d${directoryStr}', '-mrefresh'].toList(), (success, type) {
        bean = handleCallBack(success, type);
      }, magpie_attach_tool.DebugActionType.refresh);
    }
    return bean;
  }

  ResponseBean handleCallBack(bool success, magpie_attach_tool.DebugActionType actionType) {
    String message = '';
    switch (actionType) {
      case magpie_attach_tool.DebugActionType.attach:
        message = 'attach' + (success ? '成功' : '失败');
        break;
      case magpie_attach_tool.DebugActionType.reload:
        message = 'reload' + (success ? '成功' : '失败');
        break;
      case magpie_attach_tool.DebugActionType.refresh:
        message = 'refresh' + (success ? '成功' : '失败');
        break;
      case magpie_attach_tool.DebugActionType.pubGet:
        message = 'pubGet' + (success ? '成功' : '失败');
        break;
      case magpie_attach_tool.DebugActionType.attach_reload:
        message = success ? 'attach成功' : 'attach成功，reload失败';
        break;
      default:
        break;
    }
    message = '${message}！';
    return ResponseBean({
      'message': message
    });
  }
}
