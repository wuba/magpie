## Release模块帮助文档
如果对MagpieSDK集成到App的操作不清楚，请查看项目说明 [https://github.com/wuba/magpie_sdk](https://github.com/wuba/magpie_sdk)

下面介绍基础的打包相关配置操作。

### 打包
1. 打包成功后请根据平台发布AAR(Android)，上传编译产物到git(iOS)
2. 安卓只支持打包aar，请确保flutter模板通过cli脚手架生成
3. iOS打包时请确保flutter项目中存在lib/main.dart文件
4. 打包上传之后安卓可通过gradle依赖，iOS可通过CocoaPods依赖，如需其他方式可通过打包产物手动添加

### 上传
#### Android上传
1. 发布aar之前请先构建 aar，在workflow左侧->构建->android打包
2. 发布之前请在模板工程中的android_magpie/gradle.properties中配置maven仓库及发布信息等相关信息,否则会发布失败，例如：
```
# 打包类型 release or debug,默认release
AAR_BUILD_TYPE=release
# 私有maven地址
MAVEN_URL=http://artifactory.xxx.com:8081/artifactory/android/
# 用户名
MAVEN_USER_NAME=username
# 密码
MAVEN_PWD=password
# artifactid
MAGPIE_CLIENT_ARTIFACTID=magpie_debug
# groupid
MAGPIE_CLIENT_GROUPID=com.wuba.magpie
# version
MAGPIE_CLIENT_VERSION=0.0.1
```
3. 发布成之后即可在原生工程中直接通过gradle dependencies替换magpie_flutter_debug_default，例如：
```
去掉默认的dart侧带有空载体页包
debugImplementation 'com.wuba.magpie:magpie_flutter_debug_default:1.0.1'

然后根据aar类型更改magpie-SDK依赖类型
debugImplementation 'com.wuba.magpie:magpie_debug:0.0.1'
或
releaseImplementation 'com.wuba.magpie:magpie_release:0.0.1'

```

#### iOS上传
1. iOS上传之前请先打包
2. iOS发布目前只支持上传到git仓库，仓库创建及后续集成Pods请手动完成

### iOS集成请参考
iOS相关帮助请查看，[iOS集成](doc/help/release_build_ios_help.md)