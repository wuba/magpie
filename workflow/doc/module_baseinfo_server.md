# 工程结构初始化

| 时间         | 说明        | 修改人  |
| ---------- | --------- | --------  |
| 2019.12.17 | Server直接返回flutter命令结果  | 金修博  |

## 模块设计

提供了两个接口。

##### 接口1：'/api/baseinfo/doctor'
直接返回`flutter doctor`命令的结果。

##### 接口2：'/api/baseinfo/info'
返回`flutter --version`命令的结果，额外返回相关SDK信息。

目录结构如下：
```
├── doc
│   └── module_baseinfo_server.md
├── server
│   └── lib
│       └── controller
│           └── baseinfo_controller.dart
```