
import 'base/process.dart';

///获取flutter安装目录
Future<String> getFlutterRootPath() async{
  RunResult flutterPathResult = await processUtils.run(['which','flutter']);
  if(flutterPathResult.exitCode == 0){
    return flutterPathResult.toString().replaceAll(RegExp('/+bin/+flutter'),'');
  }else{
    return null;
  }
}