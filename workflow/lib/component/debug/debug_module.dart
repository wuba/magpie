import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workflow/component/log/log_utils.dart';
import 'package:workflow/provider/shared_data_provider.dart';
import 'package:workflow/utils/net_util.dart';
import 'package:workflow/utils/sp_util.dart';

import '../widget/button.dart';
import '../widget/container_extension.dart';
import '../widget/inputdecoration_extension.dart';

enum DebugBtnType { attach, refresh, reload }

class DebugModule extends StatefulWidget {
  final String workspaceDirectory;

  DebugModule({this.workspaceDirectory});

  @override
  _DebugModuleState createState() {
    return _DebugModuleState(workspaceDirectory);
  }
}

class _DebugModuleState extends State<DebugModule> {
  bool attached = false;

  /// 工程目录
  String workspaceText;
  final workspaceController = TextEditingController();

  /// 入口文件，如main.dart
  String mainFileText;
  final mainFileController = TextEditingController();

  String alertText = '';

  _DebugModuleState(this.workspaceText);

  @override
  void initState() {
    super.initState();
    if (workspaceText == null || workspaceText == '') {
      fetchInitialData();
    } else {
      updateMainAsDefault();
      workspaceController.text = workspaceText;
      mainFileController.text = mainFileText;
    }
  }

  void fetchInitialData() async {
    workspaceText = await SpUtil.getString(tPathSpKey);
    mainFileText = await SpUtil.getString(ePathSpKey);
    updateMainAsDefault();

    if (!mounted) {
      return;
    }
    setState(() {
      workspaceController.text = workspaceText;
      mainFileController.text = mainFileText;
    });
  }

  /// 自动填充
  void updateMainAsDefault() {
    var mainFileEmpty = mainFileText == null || mainFileText == '';
    var workspaceExist = workspaceText != null && workspaceText != '';
    // main为空，自动填充
    if (mainFileEmpty && workspaceExist) {
      mainFileText = '$workspaceText/lib/main.dart';
    } else if (!mainFileEmpty && !mainFileText.startsWith(workspaceText)) {
      // main路径与目录不符合，自动填充
      mainFileText = '$workspaceText/lib/main.dart';
    }
  }

  Widget debugTips() {
    const defaultColor = Color(0xFF999999);
    return Container(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.info_outline, color: defaultColor, size: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '使用说明：',
                    style: TextStyle(color: defaultColor, fontSize: 20),
                  ),
                ),
              ],
            ),
            Container(
              height: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: instructionWidgetList(),
            ),
          ],
        ));
  }

  List<Widget> instructionWidgetList() {
    const defaultColor = Color(0xFF999999);
    var widgetList = <Widget>[];
    var instructionList = <String>[
      '1. Debug之前请先通过<设备管理>模块选择目标设备；',
      '2. 通过<项目目录>和<入口文件>来设置Dart工程目录及工程入口文件；',
      '3. 如果需要进行断点调试，请使用IDE提供的Flutter Attach及Debug Attach功能；'
    ];
    instructionList.forEach((instructionStr) {
      var widget = Text(
        instructionStr,
        style: TextStyle(color: defaultColor, fontSize: 17),
      );
      widgetList.add(widget);
    });
    return widgetList;
  }

  _btnPress(DebugBtnType btnType) async {
    switch (btnType) {
      case DebugBtnType.attach:
        _requestAttach();
        break;
      case DebugBtnType.reload:
        _requestReload();
        break;
      case DebugBtnType.refresh:
        _requestRefresh();
        break;
      default:
        break;
    }
  }

  _requestAttach() async {
    var paramMap = <String, String>{};
    paramMap['directory'] = workspaceController.text.trim();
    paramMap['target'] = mainFileController.text.trim();
    paramMap['device'] = Provider.of<SharedDataProvider>(context, listen: false)
        .currentDevice()
        ?.deviceId;
    if (paramMap['directory'] == null || paramMap['directory'].length == 0) {
      alertText = '请先输入项目目录';
      showAlertDialog();
      return;
    }
    if (paramMap['target'] == null || paramMap['target'].length == 0) {
      alertText = '请先输入入口文件';
      showAlertDialog();
      return;
    }
    if (paramMap['device'] == null) {
      alertText = '请先选择需要连接设备';
      showAlertDialog();
      return;
    }
    showLoadingDialog();
    SpUtil.setString(tPathSpKey, paramMap['directory']);
    SpUtil.setString(ePathSpKey, paramMap['target']);
    NetUtils.get('/api/debug/attach', params: paramMap).then((dataStr) {
      hideLoadingDialog();
      Map map = json.decode(dataStr);
      Map dataMap = map['data'];
      alertText = dataMap['message'];
      showAlertDialog();
    }).timeout(Duration(seconds: 60), onTimeout: () {
      logger.error("connection timeout");
      hideLoadingDialog();
      alertText = '设备连接超时';
      showAlertDialog();
    });
  }

  _requestRefresh() async {
    String dataStr = await NetUtils.get('/api/debug/refresh',
        params: <String, String>{'directory': workspaceController.text ?? ''});
    Map map = json.decode(dataStr);
    Map dataMap = map['data'];
    alertText = dataMap['message'];
    showAlertDialog();
  }

  _requestReload() async {
    String dataStr = await NetUtils.get('/api/debug/reload',
        params: <String, String>{'directory': workspaceController.text ?? ''});
    Map map = json.decode(dataStr);
    Map dataMap = map['data'];
    alertText = dataMap['message'];
    showAlertDialog();
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.only(top: 26.0),
                child: Text("正在链接设备，请稍后..."),
              )
            ],
          ),
        );
      },
    );
  }

  void hideLoadingDialog() {
    Navigator.of(context).pop();
  }

  Future<bool> showAlertDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("提示"),
          content: Text(alertText ?? ''),
          actions: <Widget>[
            FlatButton(
              child: Text("确定"),
              onPressed: () => Navigator.of(context).pop(), // 关闭对话框
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final directoryFocusNode = FocusNode();
    directoryFocusNode.addListener(() {
      if (workspaceController.text != null &&
          workspaceController.text.trim().length > 0) {
        mainFileController.text = workspaceController.text + '/lib/main.dart';
      }
    });
    var hoverColor = Theme.of(context).hoverColor;
    return Expanded(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('开发编译', style: TextStyle(fontSize: 18)),
              Container(
                margin: EdgeInsets.only(top: 10),
                child: TextField(
                  maxLines: 1,
                  controller: workspaceController,
                  decoration: InputDecoration(
                          hintText: '请输入编译项目目录',
                          prefixIcon: Icon(Icons.folder, color: hoverColor))
                      .asMgpInputDecoration(
                          onClearTap: _handleClearWorkspace,
                          context: context,
                          onDirectoryChanged: _handleWorkspaceChanged),
                  focusNode: directoryFocusNode,
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 10),
                child: TextField(
                  maxLines: 1,
                  controller: mainFileController,
                  decoration: InputDecoration(
                      hintText: '入口文件lib/main.dart',
                      prefixIcon: Icon(
                        Icons.assignment_turned_in,
                        color: hoverColor,
                      )).asMgpInputDecoration(onClearTap: _handleMainFileClear),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  'Attach'.asButton(
                    onPress: () => _btnPress(DebugBtnType.attach),
                    circle: true,
                    trailing: Icon(Icons.developer_mode),
                    alignment: MainAxisAlignment.center,
                    builder: (_) {
                      return Container(child: _, width: 200);
                    },
                  ),
                  'Hot reload'.asButton(
                    onPress: () => _btnPress(DebugBtnType.refresh),
                    circle: true,
                    trailing: Icon(Icons.refresh),
                    alignment: MainAxisAlignment.center,
                    builder: (_) {
                      return Container(child: _, width: 200);
                    },
                  ),
                  'Restart'.asButton(
                    onPress: () => _btnPress(DebugBtnType.reload),
                    circle: true,
                    trailing: Icon(Icons.repeat),
                    alignment: MainAxisAlignment.center,
                    builder: (_) {
                      return Container(child: _, width: 200);
                    },
                  ),
                ],
              ),
            ],
          ),
        ).asCard,
        Expanded(child: Container()),
        debugTips(),
      ],
    ));
  }

  _handleMainFileClear() {
    setState(() {
      mainFileController.text = '';
    });
  }

  void _handleWorkspaceChanged(dir) => workspaceController.text = dir;

  _handleClearWorkspace() => setState(() => workspaceController.text = '');
}
