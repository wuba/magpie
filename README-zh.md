![](workflow/doc/images/logo-small.png)

[English](README.md) [中文说明](README-zh.md)

[![Pub](https://img.shields.io/pub/v/magpie_cli.svg)](https://pub.dartlang.org/packages/magpie_cli)
[![Platform](https://img.shields.io/badge/platform-mac%7Cwin%7Clinux-blue)](https://github.com/wuba/magpie)
[![License](https://img.shields.io/badge/license-BSD-green.svg)](LICENSE)

Magpie Workflow 是一个Flutter开发的工具流，实现独立Flutter模块的创建，开发，编译，打包，上传流程。
Magpie Workflow is a visualized platform which is designed to create, develop and compile your 
standalone flutter module.

希望通过这种方式来简化Flutter混合开发的复杂度，成为连接开发者与Flutter的桥梁，因此取名为Magpie Workflow。项目整体包含三部分：

* 脚手架：命令行工具，如创建工程，启动可视化界面等
* workflow前端： 开发编译的可视化页面
* workflow后端： 为前端提供服务的server

![](workflow/doc/images/workflow-preview.gif)

![](workflow/doc/images/workflow-arc.png)

## 使用说明

### 脚手架安装

确保您安装并正确配置了flutter环境与dart相关路径[Magpie 脚手架#环境配置](CLI.md)，flutter版本支持**1.12.x**。

```shell
pub global activate magpie_cli
```

### workflow使用

通过`mgpcli`命令工具可以创建一个flutter项目，并启动workflow进行编译。

1.创建flutter模块工程

```shell
# 创建模板工程
mgpcli create -n flutter_sample
```

2.启动workflow

```shell
# 进入新创建的工程目录内
cd flutter_sample
# 启动workflow
mgpcli start
```

3.进入workflow

**现在已经为您打开了一个浏览器窗口**，请移步至窗口进行：[编译、Attach](http://127.0.0.1:8080)

## 开发贡献

源码开发和编译，根据模块不同请参考对应文档：
* CLi部分，请参考[脚手架](CLI.md)
* Workflow部分，请参考[Workflow](workflow/README.md)

Magpie包含了一系列的开源项目，访问对应仓库以便了解更多。

> Magpie Native&Dart SDK

与Workflow配套，用于接入App，Flutter的SDK。[https://github.com/wuba/magpie_sdk](https://github.com/wuba/magpie_sdk)

> Magpie Fly 

所见即所得的Flutter UI组件库。[https://github.com/wuba/magpie_fly](https://github.com/wuba/magpie_fly)

> Magpie Log

适用于Flutter平台下的圈选埋点库。[https://github.com/wuba/magpie_log](https://github.com/wuba/magpie_log)

## 关于我们

本项目由58Magpie技术团队开发/维护，项目离不开所有小伙伴们的积极参与(排序不分先后)：

[avenwu](https://github.com/avenwu), [CoCodeDZ](https://github.com/3aaap), [haijun](https://github.com/153493932), [hxinGood](https://github.com/hxinGood),  [iamagirlforios](https://github.com/iamagirlforios), [Kcwind](https://github.com/Kcwind), [lyx0224](https://github.com/lyx0224), [MuYuLi](https://github.com/MuYuLi), [xiubojin](https://github.com/xiubojin), [zdl51go](https://github.com/zdl51go),  [zhangkaixiao23](https://github.com/zhangkaixiao23)

感谢Alina_0516提供的设计支持。

## LICENSE & 致谢
Magpie项目基于[BSD协议](LICENSE)开源。

我们对Flutter Tools做了二次开发，同时使用了一些社区提供的依赖库，在此特别感谢Flutter&Dart社区的开发者们。
[effective_dart](https://pub.dev/packages/effective_dart), [provider](https://pub.dev/packages/provider), [qr_flutter](https://pub.dev/packages/qr_flutter), [process_run](https://pub.dev/packages/process_run), [dio](https://pub.dev/packages/dio), [jaguar](https://pub.dev/packages/jaguar)

我们使用的更多依赖库详见pubspec.yaml
