# 主界面排版

| 时间         | 说明        | 修改人  |
| ---------- | --------- | --------  |
|  2019.12.18     | 日志server及client Log实现      | 吴丹     |
|  2019.12.18     | 写日志文件处理      | 吴丹     |

# 模块设计
#### web client:  
添加LogUtil类，用于web跟server进行socket通信，以及web中打日志使用，用法：
logManager.connectSocketClient();  与服务器建立socket连接
打日志：Logger.info('点击了按钮啦'); 
       Logger.error('报错啦'); 

若需要监听日志变化：
Logger.onLogUpdate.listen((logRecord){
});

#### 其他client，如脚手架
只需与server建立socket，监听日志更新即可（'ws://127.0.0.1:8080/api/log/read_connect'）

#### server：
server提供接受日志，日志写入文件，分发日志读能力；
连接服务器socket分为，只写，只读，可读写三种类型读socket，若连接的是只写socket，服务器不会给该类型的连接返回任何数据；若连接的是只读socket，服务器不会接受该连接读任何消息。
连接地址：
'ws://127.0.0.1:8080/api/log/connect'
'ws://127.0.0.1:8080/api/log/read_connect'
'ws://127.0.0.1:8080/api/log/write_connect'


#### 日志收发逻辑：
client给server发送日志，server将日志写入文件，然后将日志分发给可读日志的所有socket连接

服务器本身要发送日志，直接调用logToClient() 方法；（因为服务器用了第三方的logging.dart组件，所以只需要在logging的listen中调用）
例：
  Logger.root.onRecord.listen((rec) {
    print('${rec.level}::${rec.time}::${rec.message}');
    logToClient(Level.INFO.name, rec.message, rec.time);
  });


#### 日志文件：
LogFile类用于将日志写入文件，文件路径：主工程/log/$folder/filename.log
文件夹命名规则：$folder 可传入自定义文件夹命名，如不同的设备名称：iPhone11 -> log/iPhone11/xxx.log
文件命名规则：year-month-day_hashcode_index.log
hashcode：是启动当前server的日期的hashcode，作为唯一标志
index：便于日志太多，用于分文件存储的index下标


#### 格式化日期类：
DateFormatter：用于格式化日志，
比如输入'yyyy-MM-dd HH:mm:ss' 可将输入日志格式话为:'2019-12-18 17:21:11'
比如输入'HH:mm:ss' 可将输入日志格式话为:'17:21:11'

```
lib下
├── component
│   └── log_utils.dart
│   └── log_page.dart
├── utils
│   └── date_format_util.dart

server下
├── controller
│   └── log_controller.dart
├── utils
│   └── log_file.dart

```
## 预览
设计
![](images/log_server.png)