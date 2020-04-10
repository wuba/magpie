# 模块标题

| 时间         | 说明        | 修改人  |
| ---------- | --------- | --------  |
|  2019.12.21     | debug服务       | songdezhong     |
|            |           |           |

## 模块设计
本服务提供三个接口供前台调用：
1. `/api/debug/attach` ： 提供attach功能，将dart工程与nativeapp链接；
2. `/api/debug/refresh`： 提供热更新功能，刷新界面；
3. `/api/debug/reload` ： 提供热重载功能，刷新界面并重置页面状态；

## 目录结构
```
├── doc
│   └── module_debug_server.md
├── server
│   └── lib
│       └── controller
│           └── debug_controller.dart
```

## 目前遗留问题
1. (已解决)attach命令暂时无法找到正确返回的方式，如果使用start吊起，则无法实现重载和刷新；使用stream吊起则无法返回；正在尝试其他方法解决。
2. 异常情况的处理及UI细节及反馈完善；
3. (实现由设备管理模块来实现选择设备功能)缺少选择设备的功能;

