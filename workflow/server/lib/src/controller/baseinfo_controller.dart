import 'dart:io';
import 'package:jaguar/http/context/context.dart';
import 'base_controller.dart';
import '../response_bean.dart';
import 'package:process_run/process_run.dart';
import 'dart:convert';

final String API_BASE_DOCTOR = '/api/baseinfo/doctor';
final String API_BASE_INFO   = '/api/baseinfo/info';
final String API_BASE_SDK    = '/api/baseinfo/sdk';

class BaseinfoController extends BaseController {
  route(String path, Context ctx) async{
    if(match(path, API_BASE_DOCTOR)) {
      return getDoctorInfo(ctx);
    } else if (match(path, API_BASE_INFO)) {
      return getBaseInfo(ctx);
    } else if (match(path, API_BASE_SDK)) {
      return getSDKInfo(ctx);
    } else {
      return ResponseBean('baseinfo error!');
    }
  }

  //flutter doctor
  getDoctorInfo(Context ctx) async {
    ProcessResult result = await run('flutter', ['doctor'], verbose: true);
    return ResponseBean("${result.stdout}");
  }

  //显示当前的版本信息,显示当前的版本信息,相应配套FlutterSDK，58FlutterSDK的版本要求，及下载地址对应文档地址
  getBaseInfo(Context ctx) async {
    ProcessResult result = await run('flutter', ['--version']);
    var cli = new CliInfo();
    var flutterRuntimeText = result.stdout;

    var data = {
      'runtime_title': '环境信息',
      'runtime_value': flutterRuntimeText,
      'version_title': '版本要求',
      'data': cli.content,
    };
    return ResponseBean(data, code: 1, msg: 'success');
  }

  getSDKInfo(Context ctx) async {
    var cli = new CliInfo();
    String dataStr = ctx.query['data'];
    Map<String, dynamic> map = json.decode(dataStr);
    String fltVersion = map['flutterSdkVersion'];
    String wbVersion = map['wbsdkVersion'];
    String downUrl = map['wbsdkDownloadUrl'];
    String docUrl = map['wbsdk_docUrl'];

    cli.content = {
      'fltVersion': fltVersion,
      'wbVersion': wbVersion,
      'downUrl': downUrl,
      'docUrl': docUrl,
    };
  }
}

class CliInfo {
  dynamic content;

  static final CliInfo theOne = new CliInfo._internal();
  factory CliInfo() => theOne;
  CliInfo._internal();
}
