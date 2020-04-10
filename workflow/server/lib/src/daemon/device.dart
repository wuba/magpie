import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../tools/base/common.dart';
import '../tools/base/process_manager.dart';

class FlutterDaemon {
  static final FlutterDaemon _singleton = FlutterDaemon._internal();

  factory FlutterDaemon() {
    return _singleton;
  }

  FlutterDaemon._internal();

  Process _daemon;

  Future<void> attach() async {
    if (_daemon != null) {
      return;
    }
    /// 采用io包下的process需要进行系统适配, 可采用 flutter tool包装类，或者process_run扩展库
    var daemon = await processManager.start(['flutter', 'daemon']);
    print('daemon process started, pid: ${daemon.pid}');
    _daemon = daemon;
    daemon.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
      print('<== $line');
      // skip none JSON-RPC message
      if (!line.startsWith('[') && !line.endsWith(']')) {
        return;
      }
      var response = json.decode(line);
      var id = response[0]['id'];
      if (id == null) {
        return;
      }
      var onData = events[id];
      if (onData != null) {
        onData(response[0]);
        events.remove(id);
      }
    });
    daemon.stderr.transform<String>(utf8.decoder).listen((error) {
      var onData = events[id];
      if (onData != null) {
        onData({'error': error});
        events.remove(id);
      }
    });
    // Print in the callback can't fail.
    unawaited(daemon.exitCode.then<void>((int code) {
      print('daemon exiting ($code)');
      _daemon = null;
    }));
    var completer = Completer();
    _send({"method": "device.enable"}, onData: (data) {
      completer.complete();
    });
    return completer.future;
  }

  int id = 0;
  Map<int, Function> events = {};

  void _send(Map<String, dynamic> map,
      {void onData(Map<String, dynamic> event)}) {
    map['id'] = ++id;
    events[id] = onData;
    final String str = '[${json.encode(map)}]';
    _daemon.stdin.writeln(str);
    print('==> $str');
  }

  Future<Map<String, dynamic>> getDevice() {
    var completer = Completer<Map<String, dynamic>>();
    _send({'method': 'device.getDevices'}, onData: (data) {
      completer.complete(data);
    });
    return completer.future;
  }
}
