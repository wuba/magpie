import 'dart:async';
import 'dart:io';

import 'package:jaguar/http/context/context.dart';

import '../../www.dart';
import '../response_bean.dart';
import 'base_controller.dart';

class ResAddress extends BaseController {
  @override
  FutureOr route(String path, Context ctx) async {
    var ip = await ipList();
    if (ip.isNotEmpty) {
      var app = {
        'android': 'http://${ip.first}:${port}/assets/data/demo-android.apk',
        'ios': 'http://${ip.first}:${port}/assets/data/demo-ios.zip'
      };
      return ResponseBean(app, code: 1, msg: '获取地址成功');
    }
    return ResponseBean('', code: 0, msg: '无网络，获取资源地址失败');
  }

  Future<List<String>> ipList() async {
    var address = <String>[];
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        print('${addr.address}');
        address.add(addr.address);
      }
    }
    return address;
  }
}
