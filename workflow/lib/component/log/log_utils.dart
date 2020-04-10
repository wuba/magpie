import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:workflow/utils/net_util.dart';

LogUtil get logger {
  return LogUtil.getInstance();
}

class LogUtil {
  LogUtil._();
  factory LogUtil() => getInstance();
  static LogUtil _instance;
  StreamController<WBLogRecord> _streamController;

  static LogUtil getInstance() {
    _instance ??= LogUtil._();
    return _instance;
  }

  void info(String msg) {
    log(WBLevel.INFO, msg);
  }

  void error(String msg) {
    log(WBLevel.ERROR, msg);
  }

  void warning(String msg) {
    log(WBLevel.WARNING, msg);
  }

  void success(String msg) {
    log(WBLevel.SUCCESS, msg);
  }

  void server(String msg) {
    log(WBLevel.SERVER, msg);
  }

  void log(String level, String msg) {
    var message = '';
    if (msg == null) {
      message = '';
    } else if (msg is String) {
      message = msg;
    } else {
      message = msg.toString();
    }

    var record = WBLogRecord(
        level: level, message: message, time: DateTime.now().toString());
    _publish(record);
  }

  void _publish(WBLogRecord record) {
    if (_streamController != null) {
      _streamController.add(record);
    }
  }

  Stream<WBLogRecord> _getStream() {
    if (_streamController == null) {
      _streamController = StreamController<WBLogRecord>.broadcast(sync: true);
    }
    return _streamController.stream;
  }

  Stream<WBLogRecord> get onLogUpdate => _getStream();
}

class WBLevel {
  static const String INFO = 'INFO';
  static const String ERROR = 'ERROR';
  static const String WARNING = 'WARNING';
  static const String SUCCESS = 'SUCCESS';
  static const String SERVER = 'SERVER';
}

class WBLogRecord {
  WBLogRecord({
    this.level = WBLevel.INFO,
    @required this.message,
    @required this.time,
  });

  String level;
  String time;
  String message;

  @override
  String toString() => '[$level] $time: $message';
}

final LogManager logManager = LogManager.getInstance();

typedef OnLogMsgUpdateCallBack = void Function();

class LogManager {
  LogManager._();
  factory LogManager() => getInstance();
  static LogManager _instance;
  WebSocket _socketClient;
  OnLogMsgUpdateCallBack onLogMsgUpdate; //消息更新回调

  final List<WBLogRecord> _logList = [];
  final int maxLogLenght = 500; //最多展示500条

  static LogManager getInstance() {
    if (_instance == null) {
      _instance = LogManager._();
      _instance._init();
    }
    return _instance;
  }

  List<WBLogRecord> get logList => _logList;

  void _init() {
    //有日志 ，发送给server
    logger.onLogUpdate.listen((record) {
      print(record.toString());
      if (_socketClient != null && _socketClient.readyState == WebSocket.OPEN) {
        _socketClient.send(json.encode({
          'level': record.level,
          'message': record.message,
          'time': DateTime.now().toString()
        }));
      } else {
        _addLogToList(record);
      }
    });
  }

  void removeAllLog() {
    _logList.removeRange(0, _logList.length);
  }

  void _addLogToList(WBLogRecord record) {
    if (_logList.length >= maxLogLenght) {
      _logList.removeAt(0);
    }
    _logList.add(record);
    if (onLogMsgUpdate != null) {
      onLogMsgUpdate();
    }
  }

  //连接socket
  void connectSocketClient() async {
    var ws = await NetUtils.ws('api/log/connect');
    debugPrint('Connect to $ws');
    _socketClient = WebSocket(ws);

    _socketClient.onOpen.listen((e) {
      print('Websocket onOpen, retrying in ');
    });

    _socketClient.onClose.listen((e) {
      print('Websocket closed, retrying in ');
    });

    _socketClient.onError.listen((e) {
      print("Error connecting to ws");
    });

    //接收server的日志信息
    _socketClient.onMessage.listen((MessageEvent e) {
      if (e.data != null) {
        var data = json.decode(e.data);
        var record = WBLogRecord(
            level: data['level'], message: data['message'], time: data['time']);
        _addLogToList(record);
      }
    });
  }

  //关闭socket
  void closeSocketClient() {
    _socketClient?.close();
    _socketClient = null;
  }
}
