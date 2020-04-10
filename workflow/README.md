![](doc/images/logo-small.png)
---

- [环境要求](#环境要求)
- [后端编译](#后端编译)
- [前端编译](#前端编译)
- [编码规范](#编码规范)
- [集成发布](#集成发布)

---

workflow采取了分层架构设计，进行源码开发时根据不同模块时，启动编译略有差异。请参照以下文档，以便快速进行源码开发和代码贡献。

## 环境要求

[Flutter-Web](https://flutter.dev/docs/get-started/web)目前并不完善，没有stable的版本，可参考使用`1.12.13+hotfix.3`版本，请务必切换至dev/master通道；如需版本升级请参考[Flutter Upgrade](https://flutter.dev/docs/development/tools/sdk/upgrading)。

| SDK     | 版本     | 备注                         |
| ------- | ------ | -------------------------- |
| Flutter | v1.12.x | 开发版dev，master |

```
aven$ flutter --version
Flutter 1.12.13+hotfix.3 • channel unknown • unknown source
Framework • revision 57f2df76d7 (3 days ago) • 2019-12-05 21:23:21 -0800
Engine • revision ac9391978e
Tools • Dart 2.7.0
```
打开FlutterSDK的web支持开关（enable web support）：
```
flutter config --enable-web
```

> 验证本地环境是否满足web开发？

执行flutter devices能够输出Chrome设备信息
```
user:~ aven$ flutter devices
4 connected devices:

Chrome                    • chrome        • web-javascript • Google Chrome 78.0.3904.108
Web Server                • web-server    • web-javascript • Flutter Tools
```

## 后端编译
workflow分为前后端，后端源码位于`server`下，是一个Dart工程，推荐通过VS Code进行开发。

## 前端编译
前端部分是一个flutter工程，采用了flutter-web技术栈，可以通过`VS Code`, `Android Studio`开发。

为了顺利联调，建议先启动workflow的后端部分，启动可以通过
> ./start-server

后端目前不支持热重载，如果您修改了server代码，需要重启server，也就是重新执行`./start-server`。

启动web可以走IDE，也可以走命令行：
 > flutter run -d chrome

## 编码规范

Dart编码遵守`Effective Dart`准则。项目已开启lint检测，不符合准则的代码，开发期间有会提示`warning`。

`Effective Dart`完整规范，请查看 [https://dart.dev/guides/language/effective-dart/style](https://dart.dev/guides/language/effective-dart/style)

举例常见的命名相关约定：
* 包名，目录，文件 =》 word_another_word.dart
* 类名 =》UpperCameCase
* 变量，常量 =》lowerCamelCase
* 私有=》 _lowerCamelCase
* 导包前缀 =》library_as_alias

## 集成发布

集成发布意味着把前后端workflow整体编译打包，用户可以通过mgpcli进行使用。

### 发布workflow
执行以下命令完成前后端资源的构建和内置：
> ./deploy -cli

### 本地验证cli
通过pub --source进行本地部署，执行以下命令：
> ./setup-cli

如果你本地有dart、flutter环境，但是不支持flutter-web，也可以使用预编译的workflow进行体验：
> ./setup-cli --dry-run

完成上述步骤后，你应当可以使用mpcli命令了。例如启动workflow可以执行：
> mgpcli start

## 鸣谢

感谢`@Alina_0516`提供的设计支持