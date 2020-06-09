import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workflow/component/log/log_utils.dart';
import 'package:workflow/utils/dialog_util.dart';
import 'package:workflow/utils/net_util.dart';
import 'package:workflow/utils/sp_util.dart';

import '../widget/button.dart';
import '../widget/container_extension.dart';
import '../widget/inputdecoration_extension.dart';

class ReleaseBuild extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ReleaseBuildState();
  }
}

class _ReleaseBuildState extends State<ReleaseBuild> {
  bool isIosBuilding = false;
  bool isAndroidBuilding = false;
  bool debugMode = false;
  final _tPathController = TextEditingController(); //目标目录

  @override
  void initState() {
    super.initState();
    SpUtil.getString(tPathSpKey).then((onValue) {
      if (onValue != null) {
        setState(() {
          _tPathController.text = onValue;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Text('打包', style: TextStyle(fontSize: 18)),
            Container(
              margin: EdgeInsets.only(top: 10),
              child: TextField(
                maxLines: 1,
                controller: _tPathController,
                decoration: InputDecoration(
                    hintText: '请输入编译项目目录',
                    prefixIcon: Icon(
                      Icons.folder,
                      color: Theme.of(context).hoverColor,
                    )).asMgpInputDecoration(
                  onClearTap: _handleWorkspaceClear,
                  context: context,
                  onDirectoryChanged: _handleWorkspaceChange,
                ),
              ),
            ),
            Padding(padding: EdgeInsets.fromLTRB(0, 10, 0, 0)),
            Row(
              children: <Widget>[
                Checkbox(
                  checkColor: Colors.white,
                  activeColor: Theme.of(context).hoverColor,
                  value: debugMode,
                  onChanged: (v) {
                    setState(() {
                      debugMode = v;
                    });
                  },
                ),
                Text('勾选后，构建产物为Debug模式')
              ],
            ),
            Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 40,
                    width: 320,
                    margin: EdgeInsets.all(10),
                    child: 'Android打包'.asButton(
                      onPress: () => _build(true),
                      trailing: isAndroidBuilding
                          ? const SizedBox(
                              child: const CircularProgressIndicator(),
                              width: 13,
                              height: 13,
                            )
                          : Icon(
                              Icons.build,
                              color: Colors.white,
                              size: 16,
                            ),
                      alignment: MainAxisAlignment.center,
                      circle: true,
                      color:
                          _isBuilding() ? Theme.of(context).splashColor : null,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 40,
                    width: 320,
                    margin: EdgeInsets.all(10),
                    child: 'iOS打包'.asButton(
                      onPress: () => _build(false),
                      color:
                          _isBuilding() ? Theme.of(context).splashColor : null,
                      trailing: isIosBuilding
                          ? const SizedBox(
                              child: const CircularProgressIndicator(),
                              width: 13,
                              height: 13,
                            )
                          : Icon(
                              Icons.build,
                              color: Colors.white,
                              size: 16,
                            ),
                      alignment: MainAxisAlignment.center,
                      circle: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        )).asCard;
  }

  _build(bool isAndroid) async {
    if (_check()) return;

    _savePath();

    setState(() {
      isIosBuilding = !isAndroid;
      isAndroidBuilding = isAndroid;
    });
    var param = {
      'tPath': _tPathController.text,
      'debug': debugMode,
    };

    var url;
    if (isAndroid) {
      url = '/api/release/build_android';
    } else {
      url = '/api/release/build_ios';
    }
    String result = await NetUtils.post(url, param);
    logger.info('打包结果:$result');
    try {
      Map value = jsonDecode(result);
      if (mounted) {
        showInfoDialog(context, '${value['data']} ${value['msg']}');
      }
    } on Exception catch (error) {
      logger.info('编译错误:$error');
      if (mounted) {
        showInfoDialog(context, '编译失败');
      }
    } finally {
      if (mounted) {
        setState(() {
          isIosBuilding = false;
          isAndroidBuilding = false;
        });
      }
    }
  }

  bool _check() {
    if (_isBuilding() || !mounted) return true;

    return _checkEmpty(_tPathController.text, '编译目标目录不能为空');
  }

  bool _isBuilding() {
    return isAndroidBuilding || isIosBuilding;
  }

  bool _checkEmpty(String content, String tip) {
    if (content == null || content.isEmpty) {
      showInfoDialog(context, tip);
      return true;
    }
    return false;
  }

  ///保存目录，下次进来自动输入
  _savePath() {
    SpUtil.setString(tPathSpKey, _tPathController.text);
  }

  void _handleWorkspaceClear() {
    setState(() {
      _tPathController.text = '';
    });
  }

  void _handleWorkspaceChange(String directory) {
    setState(() {
      _tPathController.text = directory;
    });
  }
}
