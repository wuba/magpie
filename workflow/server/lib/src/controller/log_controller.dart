import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:jaguar/http/context/context.dart';
import '../utils/log_file.dart';
import 'base_controller.dart';
import '../response_bean.dart';
import 'package:jaguar/jaguar.dart';

//控制消息的发送
final logController = StreamController<String>.broadcast();
final writeLogController = StreamController<String>.broadcast();
final readLogController = StreamController<String>.broadcast();

//可读写的socket
FutureOr onLogConnect(Context ctx, WebSocket ws){
  ws.listen((data){
    _logToClient(data);
  });
  return logController.stream;
}

//只可写的socket
FutureOr onWriteLogConnect(Context ctx, WebSocket ws){
  ws.listen((data){
    _logToClient(data);
  });
  return writeLogController.stream;
}

//只可读的socket
FutureOr onReadLogConnect(Context ctx, WebSocket ws){
  return readLogController.stream;
}

void _logToClient(String data){
  var params = json.decode(data);
  LogFile.getInstance().write('${params['level']}:${params['time']}:${params['message']}', folder: '');
  //只给可读写及只读发送消息
  logController.add(data);
  readLogController.add(data);
}

void logToClient(String level, String msg, DateTime dateTime) {
  var params = {'level': level, 'message': msg, 'time': '${dateTime}'};
  _logToClient(json.encode(params));
}

void getLogFileName(){
  LogFile.getInstance().filePathWithFolder();
}


final String api_log_filepath = '/api/log/getLogFilePath';
class LogFileController extends BaseController{

  FutureOr getLogFileName(Context ctx) async {
    String folder=ctx.query.get('folder');;
    String param = LogFile.getInstance().filePathWithFolder(folder: folder);
    ctx.response = Response(ResponseBean(param));
    return ctx.response ;
  }

  @override
  FutureOr route(String path,Context ctx) async{
    if(match(path, api_log_filepath)){
      return getLogFileName(ctx);
    }
  }

}




