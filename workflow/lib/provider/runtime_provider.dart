import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:workflow/model/runtime_info.dart';
import 'package:workflow/utils/net_util.dart';

class RuntimeProvider extends ChangeNotifier {
  RuntimeInfo _runtime;

  loadData() async {
    String resJson = await NetUtils.get('/api/baseinfo/info');
    var map = json.decode(resJson);
    var data = map['data'];
    if (data == null) {
      return;
    }
    var runtimeInfo = RuntimeInfo.fromJson(data);
    _runtime = runtimeInfo;
    notifyListeners();
  }

  bool get hasData {
    return _runtime != null;
  }

  RuntimeInfo get data {
    return _runtime;
  }
}
