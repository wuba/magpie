import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workflow/component/debug/debug_module.dart';
import 'package:workflow/component/device/device_manager.dart';
import 'package:workflow/component/home/bottom_bar.dart';
import 'package:workflow/component/home/content_panel.dart';
import 'package:workflow/component/home/sample_app.dart';
import 'package:workflow/component/home/sidebar.dart';
import 'package:workflow/component/info/baseinfo_page.dart';
import 'package:workflow/component/log/log_overlay.dart';
import 'package:workflow/component/log/log_page.dart';
import 'package:workflow/component/log/log_utils.dart';
import 'package:workflow/component/release/release_main.dart';
import 'package:workflow/model/menu_item.dart';
import 'package:workflow/provider/buid_modle_provider.dart';
import 'package:workflow/provider/log_state_provider.dart';
import 'package:workflow/provider/runtime_provider.dart';
import 'package:workflow/provider/shared_data_provider.dart';
import 'package:workflow/utils/dialog_util.dart';
import 'package:workflow/utils/net_util.dart';
import 'package:workflow/utils/sp_util.dart';

import 'model/response_bean.dart';
import 'component/widget/float_extension.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => SharedDataProvider()),
      ChangeNotifierProvider(create: (context) => LogStateProvider()),
      ChangeNotifierProvider(create: (context) => RuntimeProvider()),
      ChangeNotifierProvider(create: (context) => BuildModeProvider()),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magpie Workflow',
      theme: ThemeData(
        primaryColor: Color(0xFFFB5638),
        hoverColor: Color(0x88FB5638),
        dividerTheme: DividerThemeData().copyWith(thickness: 1),
      ),
      home: HomePage(title: 'Home'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _titles = [
    MenuItem('连接设备', Icons.devices),
    MenuItem('开发编译', Icons.extension),
    MenuItem('发布构建', Icons.cloud_upload),
    MenuItem('操作日志', Icons.text_rotate_vertical),
    MenuItem('环境信息', Icons.settings_system_daydream),
    MenuItem('安装样例', Icons.phone_android),
  ];
  final _children = [
    DeviceManager(),
    DebugModule(),
    ReleaseMain(),
    LogPage(),
    BaseInfoPage(),
    SampleApp(),
  ];

  @override
  void initState() {
    super.initState();
    logManager.connectSocketClient();
    Provider.of<SharedDataProvider>(context, listen: false).update();
    Provider.of<BuildModeProvider>(context, listen: false).sync();
    checkWorkspace().then((result) {
      var skipUpdate = result[0];
      var path = result[1];
      var current = result[2];
      if (skipUpdate) {
        return Future.value([false, '', current]);
      }
      return SpUtil.setString(tPathSpKey, path).then((_) => [_, path, current]);
    }).then((result) {
      var success = result[0];
      var path = result[1];
      var previous = result[2];
      if (!success) {
        return;
      }
      var bar = SnackBar(
        content: Text('检测到新的工作目录，已更新：$path'),
        action: SnackBarAction(
          label: "点击撤销",
          textColor: Colors.white,
          onPressed: () {
            SpUtil.setString(tPathSpKey, previous).then(
                (onValue) => debugPrint('path has been reset to $previous'));
          },
        ),
      );
      Scaffold.of(context).showSnackBar(bar);
    });
  }

  @override
  void dispose() {
    super.dispose();
    logManager.closeSocketClient();
  }

  GlobalKey<ContentPanelState> _contentKey = GlobalKey(debugLabel: 'content');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Row(
        children: <Widget>[
          Sidebar(
            menus: _titles,
            onTap: (index) {
              _contentKey.currentState?.changeIndex(index);
            },
          ),
          ContentPanel(
            key: _contentKey,
            children: _children,
            bottomBar: BottomBar(),
          )
        ],
      ),
      floatingActionButtonLocation: startFloat,
      floatingActionButton: Row(
        children: <Widget>[
          FloatingActionButton(
              child: Tooltip(
                child: Text('文档'),
                message: '产看SDK接入说明',
              ),
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () {
                showMarkdownInfo(context, 'doc/help/release_help.md', null);
              }),
          Padding(padding: EdgeInsets.only(right: 10)),
          FloatingActionButton(
              child: Tooltip(
                child: Text('日志'),
                message: '查看编译等日志',
              ),
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () {
                if (_contentKey.currentState?.index == 3) {
                  //当点击到了‘操作日志’时
                  return;
                }
                LogOverlay.showLogOverlay(context);
              }),
        ],
      ),
    );
  }

  Future<List> checkWorkspace() async {
    var response = await NetUtils.get('/api/path', withCode: true);
    var path = '';
    if (response is ResponseBean) {
      if (response.code == 1) {
        path = response.code == 0 ? (response.data as String) : '';
      }
    } else if (response is Response) {
      path = response.toString();
    }

    if (path == null || path == '') {
      // there is no updated path, ignore all
      return [true, '', ''];
    }
    var current = await SpUtil.getString(tPathSpKey);
    return [path == current, path, current];
  }
}
