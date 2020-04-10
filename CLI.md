# mgpcli 脚手架

通过命令行，快速创建Flutter工程和搭建调试环境......

## 快速使用
(以下是以macos系统为例，windows环境区分可以查看主工程Readme, 主要是目录路径的区别。)

### 下载 Flutter
    git clone https://github.com/flutter/flutter.git
    cd flutter
    git checkout -b stable origin/stable

### 配置 Flutter 环境变量
    export PATH=/**/flutter/bin:$PATH

### 检测 Flutter 环境
    flutter doctor

### 配置 Dart 和 Pub 环境变量

    export PATH=/**/flutter/bin/cache/dart-sdk/bin:$PATH
    export PATH=（用户目录下的）.pub-cache/bin:$PATH

### 安装 Mgpcli 脚手架

    Mgpcli 脚手架支持2种模式运行，1、Release模式 2、Debug 模式
#### Release模式

    Release 模式为Magpie开发小组对外发布的稳定版本，不支持断点等调试手段。感兴趣的同学可以在用户根目录下的 .pub-cache/hosted/ 下的pub.flutter-io.cn 或者 pub.dartlang.org 文件夹下找到对应版本的源码进行Review和调试。

##### Release 模式安装
    pub global activate mgpcli

#### Debug 模式
    Debug 模式为Magpie开发小组日常开发环境，感兴趣的同学也可以参与Magpie团队一起开发，大家一起创造更好的Flutter的开发环境。
##### 下载 Debug 源代码 & 本地发布
    1、git clone （待补充）
    2、pub global activate --source path **/magpie_workflow (**为magpie_workflow全路径) 
    本地发布后即可在命令行运行命令集，此后就可以修改magpie_workflow源码进行调试

##### 源码Debug环境配置
    1、进入workflow 和 template/module目录下分别运行 flutter pub get
    2、用vscode打开工程，定位到我们clone下来的源码路径"**/magpie_workflow/bin/mgpcli.dart，右键菜单中选择运行。至此Magpie工程就可以断点Debug了

##### 基于Pub安装后的Release版本切换到源码调试
    1、进入用户根目录下的.pub-cache/bin/mgpcli
    2、vi 打开mpcli脚本文件我们可以看到dart "**/**/.pub-cache/global_packages/mgpcli/bin/mgpcli.dart.snapshot.dart2" "$@"
    3、把文件中dart后面的路径指向我们clone下来的源码路径"**/magpie_workflow/bin/mgpcli.dart"

### 命令集 (Flutter工程化管理)
#### 注意: 除create命令外其他命令都必须在新建工程目录下运行
#### 新建工程
    mgpcli create
#### 环境检查
    cd your-project
    mgpcli doctor    
#### 进入新建工程目录，启动workflow
    cd your-project
    mgpcli start

#### 清理缓存和依赖
    mgpcli clean
#### 帮助
    mgpcli help
#### 版本信息
    mgpcli version
