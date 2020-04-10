import 'package:args/args.dart';
import 'package:mustache/mustache.dart' as mustache;
import 'magpie_plugin.dart';
import 'magpie_utils.dart';
import 'tools/base/file_system.dart';

Future<int> exportiOSPlugins(List<MagpiePluginInfo> plugins,
    {String productPath = ''}) {
  if (productPath == '') {
    return Future.value(-1);
  }
  plugins.forEach((MagpiePluginInfo plugin) {
    var pluginPath = '${productPath}/Plugins';
    var name = plugin.name;
    fs.directory(pluginPath).createSync(recursive: true);
    plugin.productPath = '${pluginPath}/${name}';
    copyFile(
        ['-f', '-P', '-R'], '${plugin.localPath}/ios', plugin.productPath, {});
  });
  return Future.value(0);
}

/*
 * Des: Generate Objective-C Plugins Register Files.
 */
void generateRegistry(List<MagpiePluginInfo> plugins,
    {String productPath = ''}) async {
  //写入.h 文件
  File fileH =
      fs.file(fs.path.join(productPath, 'GeneratedPluginRegistrant.h'));
  fileH.createSync(recursive: true);
  fileH.writeAsStringSync(_objcPluginRegistryHeaderTemplate);

  //修改.m 文件
  String methodTemplate =
      obtainiOSTemplate(_objcPluginRegistryImplementationTemplate, plugins);
  //写入.m 文件
  File fileM =
      fs.file(fs.path.join(productPath, 'GeneratedPluginRegistrant.m'));
  fileM.createSync(recursive: true);
  fileM.writeAsStringSync(methodTemplate);

  //修改 写入.podspec文件
  String podspecTemplate =
      obtainiOSTemplate(_pluginRegistrantPodspecTemplate, plugins);
  File fileP = fs.file(fs.path.join(productPath, 'FlutterBusiness.podspec'));
  fileP.createSync(recursive: true);
  fileP.writeAsStringSync(podspecTemplate);
}

String obtainiOSTemplate(
    String sourceTemplate, List<MagpiePluginInfo> plugins) {
  final List<Map<String, dynamic>> pluginConfigs = <Map<String, dynamic>>[];
  for (MagpiePluginInfo p in plugins) {
    pluginConfigs.add(<String, dynamic>{
      'name': p.name,
      'prefix': p.iosPrefix,
      'class': p.pluginClass,
    });
  }
  final Map<String, dynamic> context = <String, dynamic>{
    'os': 'ios',
    'deploymentTarget': '8.0',
    'framework': 'Flutter',
    'plugins': pluginConfigs,
  };
  final String template =
      mustache.Template(sourceTemplate, htmlEscapeValues: false)
          .renderString(context);
  return template;
}

void writeScripts(String productPath) async {
  File fileP = fs.file(fs.path.join(productPath, 'podhelper.rb'));
  fileP.createSync(recursive: true);
  fileP.writeAsStringSync(_podhelperTemplate);

  File fileR = fs.file(fs.path.join(productPath, 'README.md'));
  fileR.createSync(recursive: true);
  fileR.writeAsStringSync(_readmeTemplate);
}

const String _objcPluginRegistryHeaderTemplate = '''//
//  Generated file. Do not edit.
//

#ifndef GeneratedPluginRegistrant_h
#define GeneratedPluginRegistrant_h

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface GeneratedPluginRegistrant : NSObject
+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;
@end

NS_ASSUME_NONNULL_END
#endif /* GeneratedPluginRegistrant_h */
''';

const String _objcPluginRegistryImplementationTemplate = '''//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"

{{#plugins}}
#if __has_include(<{{name}}/{{class}}.h>)
#import <{{name}}/{{class}}.h>
#else
@import {{name}};
#endif
{{/plugins}}

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
{{#plugins}}
  [{{prefix}}{{class}} registerWithRegistrar:[registry registrarForPlugin:@"{{prefix}}{{class}}"]];
{{/plugins}}
}

@end
''';

const String _pluginRegistrantPodspecTemplate = '''
#
# Generated file, do not edit.
#

Pod::Spec.new do |s|
  s.name             = 'FlutterBusiness'
  s.version          = '0.0.1'
  s.summary          = 'App.framework PluginRegistary'
  s.description      = <<-DESC
App.framework
Depends on all your plugins, and provides a function to register them.
                       DESC
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.{{os}}.deployment_target = '{{deploymentTarget}}'
  s.source_files =  "*.{h,m}"
  s.source           = { :path => '.' }
  s.public_header_files = './Classes/**/*.h'
  s.vendored_frameworks = 'App.framework'
  s.dependency 'Flutter'
  {{#plugins}}
  s.dependency '{{name}}'
  {{/plugins}}
end
''';

const String _readmeTemplate = '''

## 平台工程集成Workflow Product

### 1.配置Podfile
#### 环境要求
- Ruby 2.5版本及其以上
#### 本地依赖
在Podfile的 target 'xxx' do 上面加入:

    load File.join(<path>,'podhelper.rb')
<path>为Workflow Product的绝对路径或于当前工程的相对路径
<path> = 'product' 表示Workflow Product目录在当前工程product目录下

在Podfile的 target 'xxx' do 下面加入:

    install_flutter_business_pods

#### 远端依赖
在Podfile的 target 'xxx' do 上面加入:

      def load_workflow_podhelper (path,tag=nil)
        if (path.start_with?('git')||path.start_with?('http'))
          if !tag
            puts('远端依赖必须指定branch或tag ! ')
            return
          end
          workflow_dir="Pods/workFlow_temp"
          git_path="git clone -b #{tag} #{path} #{workflow_dir}"
          system "rm -rf #{workflow_dir}"
          system "mkdir -p #{workflow_dir}"
          system git_path
          path="#{workflow_dir}/product"
        end
        load File.join(path,'podhelper.rb')
      end
      load_workflow_podhelper( <gitpath>, <tag>)
<gitpath>为Workflow Product的git地址，Workflow Product在此git的product目录
<tag> 为git的 branch 或 tag

在Podfile的 target 'xxx' do 下面加入:

    install_flutter_business_pods

### 2.pod install

## Workflow Product 文件说明
- App.framework  Dart业务产物
- FlutterBusiness.podspec  podsepc
- GeneratedPluginRegistrant.h  插件注册h文件
- GeneratedPluginRegistrant.m  插件注册m文件
- podhelper.rb  Podfile配置脚本
- Plugins  插件目录，可能不存在

## App.framework规范
### 文件说明
- App          库文件
- Info.plist
- flutter_assets 资源目录
  - isolate_snapshot_data  debug模式下用于加速isolate启动
  - kernel_blob.bin  debug模式下Dart代码产物
  - vm_snapshot_data  debug模式下用于加速dart vm启动

### 环境
App.framework必须与Flutter.framework保持环境一致

### 调试
debug模式下可通过attach命令调试Dart代码
  1.安装iOS app并运行。
  2.在Dart侧运行Flutter attach（建议使用IDE的attach功能）
  3.输入R后进入Flutter页面
  4.输入 r: hotreload  R: hotrestart

### Podspec配置
    s.vendored_frameworks = 'App.framework'

''';

const String _podhelperTemplate = '''

require 'find'
# Install pods needed to embed Flutter application.
# from the host application Podfile.
#
# @example
#   target 'MyApp' do
#     install_flutter_business_pods
#   end
def install_flutter_business_pods
  install_business_pods
  install_plugin_pods
end

# Install App.framework & Plugin Registry
#
# @example
#   target 'MyApp' do
#     install_business_pods
#   end
def install_business_pods
  current_dir = Pathname.new __dir__
  project_dir= Pathname.new Dir.pwd
  relative = current_dir.relative_path_from project_dir
  pod 'FlutterBusiness', :path => relative
end

# Install Flutter plugin pods.
#
# @example
#   target 'MyApp' do
#     install_plugin_pods
#   end
def install_plugin_pods
  current_dir = Pathname.new __dir__
  project_dir= Pathname.new Dir.pwd
  relative = current_dir.relative_path_from project_dir
  if File::directory?(relative.to_s + '/Plugins') then
    puts(relative.to_s)
    pluginDir = File.join(relative.to_s, 'Plugins')
    plugins = Dir.children(pluginDir).each{}
    plugins.map do |r|
      if r != '.DS_Store' then
        podDir = File.join(pluginDir, r)
        pod r, :path => podDir, :nhibit_warnings => true
        puts(r)
      end
    end
  end
end

''';
