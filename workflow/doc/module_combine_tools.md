# magpie_tool融合

| 时间         | 说明        | 修改人  |
| ---------- | --------- | --------  |
|  2019.12.21     | 合并tool与server       | 吴朝彬     |

## 模块说明
减少源码仓，将基于flutter-tools开发的magpie-tool整合进server仓库，源码直接关联使用，不在单独维护package。

tool相关源码归档与`server/lib/src/tools`

```
├── lib
│   ├── src
│   │   ├── controller
│   │   │   ├── base_controller.dart
│   │   │   ├── baseinfo_controller.dart
│   │   │   ├── device_controller.dart
│   │   │   ├── log_controller.dart
│   │   │   └── release_controller.dart
│   │   ├── magpie_attach.dart
│   │   ├── magpie_attach_android.dart
│   │   ├── magpie_build_android.dart
│   │   ├── magpie_build_ios.dart
│   │   ├── request_route.dart
│   │   ├── response_bean.dart
│   │   ├── tools
│   │   │   ├── android
│   │   │   │   ├── android_sdk.dart
│   │   │   │   ├── android_studio.dart
│   │   │   │   └── gradle_utils.dart
│   │   │   ├── artifacts.dart
│   │   │   ├── base
│   │   │   │   ├── common.dart
│   │   │   │   ├── config.dart
│   │   │   │   ├── context.dart
│   │   │   │   ├── file_system.dart
│   │   │   │   ├── io.dart
│   │   │   │   ├── logger.dart
│   │   │   │   ├── net.dart
│   │   │   │   ├── os.dart
│   │   │   │   ├── platform.dart
│   │   │   │   ├── process.dart
│   │   │   │   ├── process_manager.dart
│   │   │   │   ├── terminal.dart
│   │   │   │   ├── time.dart
│   │   │   │   ├── user_messages.dart
│   │   │   │   ├── utils.dart
│   │   │   │   └── version.dart
│   │   │   ├── build_info.dart
│   │   │   ├── cache.dart
│   │   │   ├── convert.dart
│   │   │   ├── dart
│   │   │   │   ├── analysis.dart
│   │   │   │   ├── package_map.dart
│   │   │   │   └── sdk.dart
│   │   │   ├── features.dart
│   │   │   ├── flutter_manifest.dart
│   │   │   ├── globals.dart
│   │   │   ├── ios
│   │   │   │   └── plist_parser.dart
│   │   │   ├── macos
│   │   │   │   └── xcode.dart
│   │   │   ├── persistent_tool_state.dart
│   │   │   ├── project.dart
│   │   │   └── version.dart
│   │   └── utils
│   │       ├── log_file.dart
│   │       └── logger.dart
│   └── www.dart

```
