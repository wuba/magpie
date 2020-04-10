import 'package:yaml/yaml.dart';
import 'dart:async';
import 'magpie_utils.dart';
import 'tools/base/file_system.dart';

class MagpiePluginInfo {
  String name; //插件名
  String localPath; //插件本地位置
  String productPath;  //插件导出后的位置
  String iosPrefix;  //iOS的插件类前缀
  String pluginClass; //插件类名
}

//Flutter 获取插件列表
Future<List<MagpiePluginInfo>> projectPluginInfos(String targetPath) async {
  // var file = fs.file('${targetPath}/.flutter-plugins');
  bool exsit = await fileExsit('${targetPath}/.flutter-plugins');
  if(!exsit){
    return Future.value([]);
  }
  var file = fs.file('${targetPath}/.flutter-plugins');
  // 从文件中读取变量作为字符串，一次全部读完存在内存里面
  var contents = file.readAsStringSync();
  var contentsLines = contents.split('\n');
  List<MagpiePluginInfo> plugins = List();
  contentsLines.forEach((String line) {
    List<String> element = line.split('=');
    var name = element[0];
    var localPath = '';
    element.forEach((pathElement) {
      if (element.indexOf(pathElement) == 0) {
        return;
      }
      if (localPath != '') {
        localPath + '=' + pathElement;
      } else {
        localPath = pathElement;
      }
    });
    var plugin = MagpiePluginInfo();
    plugin.localPath = localPath;
    plugin.name = name;
    if (localPath==null|| localPath == '' || name == '' || name == 'magpie') {
      return null;
    }
    final dynamic pubspec = loadYaml(fs.file('${localPath}/pubspec.yaml').readAsStringSync());
    if (pubspec == null) {
      return null;
    }
    final dynamic flutterConfig = pubspec['flutter'];
    if (flutterConfig == null || !(flutterConfig.containsKey('plugin') as bool)) {
      return null;
    }
    final dynamic pluginYaml = flutterConfig['plugin'];
    final YamlMap platformsYaml = pluginYaml['platforms'] as YamlMap;
    //有平台区分的插件
    if(platformsYaml!=null){
      const String kiOSConfigKey = 'ios';
      if (!platformsYaml.containsKey(kiOSConfigKey)||(platformsYaml[kiOSConfigKey] as YamlMap).containsKey('default_package')) {
        return null;
      }
      final YamlMap iosYaml = platformsYaml[kiOSConfigKey];
      final dynamic iosPrefix = iosYaml['iosPrefix'];
      final dynamic pluginClass = iosYaml['pluginClass'];
      plugin.iosPrefix = iosPrefix;
      plugin.pluginClass = pluginClass;
    }else{
      final dynamic iosPrefix = pluginYaml['iosPrefix'];
      final dynamic pluginClass = pluginYaml['pluginClass'];
      plugin.iosPrefix = iosPrefix;
      plugin.pluginClass = pluginClass;
    }
    plugins.add(plugin);
  });

  print(contents);
  return Future.value(plugins);
  
}



