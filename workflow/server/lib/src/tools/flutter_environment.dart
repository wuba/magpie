import 'base/os.dart';
import 'base/platform.dart';

///获取flutter安装目录
Future<String> getFlutterRootPath() async {
  var flutterPath = os.which('flutter')?.path;
  var midPath = platform.isWindows ? '\\bin\\' : '/bin/';
  if (flutterPath.contains(midPath)) {
    var flutterRoot =
        flutterPath.substring(0, flutterPath.lastIndexOf(midPath));
    return flutterRoot;
  } else {
    print('init flutter root path error ...');
  }
  return null;
}
