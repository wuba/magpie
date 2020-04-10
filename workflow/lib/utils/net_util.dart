import 'dart:async';
import 'dart:html' as html;

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:workflow/component/log/log_utils.dart';
import 'package:workflow/model/response_bean.dart';

Map<String, dynamic> optHeader = {'content-type': 'application/json'};

String _host;
Dio _dio;

Future<Dio> get dioInstance async {
  if (_dio == null) {
    String hostString = await host;
    _dio = Dio(BaseOptions(
      connectTimeout: 5000 * 20,
      sendTimeout: 10000 * 20,
      headers: optHeader,
      baseUrl: 'http://$hostString',
    ));
  }
  return _dio;
}

Future<String> get host async {
  return _host ??= await _hostCheck();
}

Future<String> _hostCheck({defaultHost = '127.0.0.1:8080'}) async {
  var h = html.window.location.host;
  var response = await http.head('http://$h/api/status');
  return response?.statusCode == 200 ? h : defaultHost;
}

class NetUtils {

  static Future<String> ws(String path) async {
    String hostString = await host;
    return 'ws://$hostString/$path';
  }

  static Future get(String url,
      {Map<String, dynamic> params, bool withCode = false}) async {
    var response;

    try {
      var dio = await dioInstance;
      if (params != null) {
        response = await dio.get(url, queryParameters: params);
      } else {
        response = await dio.get(url);
      }
    } on DioError catch (e) {
      logger.error('${e.message},type:${e.type}');
      var r =
          ResponseBean('网络请求错误', code: 0, msg: _getErrorMsgFromType(e.type));
      return withCode ? r : r.toString(); //统一处理错误并封装返回结果
    }
    return withCode ? response : response.data;
  }

  static Future post(String url, [Map<String, dynamic> params]) async {
    var response;
    try {
      var dio = await dioInstance;
      if (params != null) {
        response = await dio.post(url, queryParameters: params);
      } else {
        response = await dio.post(url);
      }
    } on DioError catch (e) {
      logger.error('${e.message},type:${e.type}');
      return ResponseBean('网络请求错误', code: 0, msg: _getErrorMsgFromType(e.type))
          .toString(); //统一处理错误并封装返回结果
    }
    return response.data;
  }

  static _getErrorMsgFromType(DioErrorType type) {
    var errorMsg = '';
    switch (type) {
      case DioErrorType.CANCEL:
        errorMsg = '请求已取消';
        break;
      case DioErrorType.CONNECT_TIMEOUT:
      case DioErrorType.SEND_TIMEOUT:
      case DioErrorType.RECEIVE_TIMEOUT:
        errorMsg = '请求超时';
        break;
      case DioErrorType.RESPONSE:
        errorMsg = '服务器出错';
        break;
      case DioErrorType.DEFAULT:
      default:
        break;
    }
    return errorMsg;
  }
}
