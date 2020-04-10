import 'dart:async';
import 'dart:io';

import 'package:jaguar/http/context/context.dart';
import 'package:process_run/shell.dart';

import '../response_bean.dart';
import 'base_controller.dart';

class FileTreeController extends BaseController {
  var home = Directory(userHomePath).absolute.path;

  @override
  FutureOr route(String path, Context context) async {
    var current = context.query.get('current');
    if (current != null && current.isNotEmpty) {
      if (!Directory(current).existsSync()) {
        return ResponseBean([], code: 0, msg: '目录不存在');
      }
    } else {
      current = home;
    }
    var dirs = await list(current);
    return ResponseBean({
      'current': current,
      'directory': dirs,
    }, code: 1, msg: '目录获取成功');
  }

  Future<List<dynamic>> list(String currentPath) async {
    print("list subdirectory of => $currentPath");
    var files = await Directory(currentPath).list();
    return files
        .where((f) =>
            f is Directory &&
            !f.path.substring(f.parent.path.length + 1).startsWith("."))
        .map((f) => {
              'name': f.path.substring(f.parent.path.length + 1),
              'path': f.path
            })
        .toList();
  }
}
