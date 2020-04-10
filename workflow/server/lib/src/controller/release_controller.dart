import 'dart:async';

import 'package:jaguar/jaguar.dart';
import '../magpie_build_android.dart';
import '../magpie_build_ios.dart';
import '../magpie_git_push.dart';
import '../magpie_maven_upload.dart';
import '../tools/flutter_environment.dart';
import '../utils/logger.dart';
import 'base_controller.dart';

import '../response_bean.dart';

class ReleaseController extends BaseController{

  Future buildAndroid(Context ctx) async{
    return build(Platforms.Android,ctx);
  }

  Future buildIos(Context ctx) async {
    return build(Platforms.Ios,ctx);
  }

  ///Release编译
  Future build(Platforms platform, Context ctx) async{
    String plat = platform.toString();
    Map form = ctx.query;
    String targetPath = form['tPath'];
    String flutterPath = await getFlutterRootPath();
    LoggerUtil.i(flutterPath);

    if(flutterPath == null || flutterPath.isEmpty){
      return ResponseBean('$plat编译失败',code: 0,msg: '未安装flutter或未配置flutter环境变量');
    }
    try {
      var result = 0;
      if(platform == Platforms.Android){
        result = await LoggerUtil.logRunZone(() async{
          return await magpieBuildAndroid(['-f',flutterPath,'-t',targetPath,'-b','release']);
        });
      }else if(platform == Platforms.Ios){
        result = await LoggerUtil.logRunZone(() async{
          return await magpieBuildIOS(['-f',flutterPath,'-t',targetPath]);
        });
      }

      if(result == 1){
        return ResponseBean('$plat编译成功');
      }else {
        return ResponseBean('$plat编译失败',code: 0,msg: 'result:$result');
      }
    } catch (e) {
      return ResponseBean('$plat 编译失败',code: 0,msg: e.toString().replaceAll(RegExp(r'\n'),' '));//替换换行符，防止前端解析json失败
    }
  }

  Future uploadIos(Context ctx) async{
    Map form = ctx.query;
    String locationPath = form['lPath'];
    String targetPath = form['tPath'];
    String sourceUrl = form['sourceUrl'];
    String version = form['version'];

    try {
      var result = 0;
      result = await LoggerUtil.logRunZone(() async{
        return await magpieGitPush(['-t',targetPath,'-m','release','-l',locationPath,'-s',sourceUrl,'-v',version]);
      });

      if(result == 1){
        return ResponseBean('iOS上传成功');
      }else {
        return ResponseBean('iOS上传失败',code: 0,msg: 'result:$result');
      }
    } catch (e) {
      return ResponseBean('iOS上传败',code: 0,msg: e.toString().replaceAll(RegExp(r'\n'),' '));//替换换行符，防止前端解析json失败
    }
  }

  Future uploadAndroid(Context ctx) async{
    Map form = ctx.query;
    String targetPath = form['tPath'];
    String versionTag = form['versionTag'];

    try {
      var result = 0;
      result = await LoggerUtil.logRunZone(() async{
        return await magpieMavenUpload(['-t',targetPath,'-v',versionTag,'-m','release']);
      });

      if(result == 1){
        return ResponseBean('AAR上传成功');
      }else {
        return ResponseBean('AAR上传失败',code: 0,msg: 'result:$result');
      }
    } catch (e) {
      return ResponseBean('AAR上传败',code: 0,msg: e.toString().replaceAll(RegExp(r'\n'),' '));//替换换行符，防止前端解析json失败
    }
  }

  @override
  FutureOr route(String path,Context ctx) async{
    if(match(path, '/build_android')){
      return buildAndroid(ctx);
    }else if(match(path, '/build_ios')){
      return buildIos(ctx);
    }else if(match(path, '/upload_ios')){
      return uploadIos(ctx);
    }else if(match(path, '/upload_android')){
      return uploadAndroid(ctx);
    }else{
      return DefaultErrorWriter().make404(ctx);
    }
  }

}

enum Platforms {
  Android,
  Ios
}