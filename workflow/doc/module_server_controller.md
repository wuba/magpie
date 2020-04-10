# Server Controller的使用

| 时间         | 说明        | 修改人  |
| ---------- | --------- | --------  |
|  2019.12.12     | Server Controller的使用       | 柯超     |

## 模块设计

### Controller的实现及注册
Server 采用jaguar提供的http请求分发处理的框架
具体的业务接口放在controller文件夹下，实现类controller在(/lib/request_route.dart)的handleController方法中添加

```
├── lib
│   └── controller
```

Controller具体实现参考(/lib/controller/release_controller.dart)

### Response返回值
返回值通过(/lib/response_bean.dart)中的ResponseBean封装，便于统一处理返回值


### http请求访问Controller的路径

以release_controller为例，访问其中的buildAndroid方法路径为

http://localhost:8080/api/release/build_android?param=dasda


## 参考文档
jaguar的更多用法可参考

[官方示例](https://pub.flutter-io.cn/packages/jaguar)

[简书教程](https://www.jianshu.com/p/32e2dcf5f391)

