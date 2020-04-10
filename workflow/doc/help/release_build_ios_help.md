## iOS集成

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
- App           静态库文件
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