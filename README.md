![](workflow/doc/images/logo-small.png)

[English](README.md) [中文说明](README-zh.md)

Magpie Workflow is a visualized platform which designed to create, develop and compile your 
standalone flutter module;

It's designed to manage the complexity of building mixed flutter apps,  connect developers and flutter like the magpie bridge. This project has three parts:
* cli: similar to flutter tool, used to create template project and start the web server;
* workflow web： A flutter-web application used to develop & compile the flutter module;
* workflow server：A dart server work with flutter-web;

![](workflow/doc/images/workflow-preview.gif)

![](workflow/doc/images/workflow-arc.png)

## How to use

### Install cli

> Make sure you have already installed the flutter sdk, the version should be **v1.12.x**

#### a. macOS ENV

```
export PATH=/*flutter directory*/flutter/bin:$PATH
```

You should set `dart` path too, so you can use `pub` directly;

```
export PATH="/*flutter directory*/flutter/bin/cache/dart-sdk/bin:$PATH"
export PATH="$PATH":"$HOME/.pub-cache/bin"
```
#### b. Windows ENV
Update windows `PATH` by appending the flutter bin

```
\*flutter directory*\flutter\bin;
```
`dart` configuration

```
\*flutter directory*\flutter\bin\cache\dart-sdk\bin;
C:\Users\{user home}\AppData\Roaming\Pub\Cache\bin
```

The pub cache path can be different when you use flutter pub or pub, make sure you've configured correctly; 

```shell
pub global activate magpie_cli
```

For details about cli development, go to [cli](CLI.md).

### Start Workflow

Since you've installed the `mgpcli`, you may start to create a flutter  module project now:
**1.Create module project**

```shell
mgpcli create -n flutter_sample
```

**2.Start service**

```shell
cd flutter_sample
mgpcli start
```

**3.Switch to browser**

The browser should  have been opened instantly，[http://127.0.0.1:8080](http://127.0.0.1:8080)

## Contribute
As we mentioned previously, `Magpie` has multiple sub-projects;

* cli: go to [cli](CLI.md)
* workflow web/server: go to [workflow](workflow/README.md)


## About

This project is maintained by **58 Magpie Tech Team**, thank you all for the contributions :)

[avenwu](https://github.com/avenwu), [CoCodeDZ](https://github.com/3aaap), [haijun](https://github.com/153493932), [hxinGood](https://github.com/hxinGood), [iamagirlforios](https://github.com/iamagirlforios), [Kcwind](https://github.com/Kcwind), [lyx0224](https://github.com/lyx0224), [MuYuLi](https://github.com/MuYuLi), [xiubojin](https://github.com/xiubojin), [zdl51go](https://github.com/zdl51go), [zhangkaixiao23](https://github.com/zhangkaixiao23)

Thanks to Alina_0516 for the design.

## LICENSE

This project is open source under the [BSD license](LICENSE).

We are using the `flutter tools` codebase and made some changes; There are many libraries we depend on, here is a short list, thanks you all:

[effective_dart](https://pub.dev/packages/effective_dart), [provider](https://pub.dev/packages/provider), [qr_flutter](https://pub.dev/packages/qr_flutter), [process_run](https://pub.dev/packages/process_run), [dio](https://pub.dev/packages/dio), [jaguar](https://pub.dev/packages/jaguar)

For more details please refer to pubspec.yaml

