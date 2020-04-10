import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:workflow/component/log/log_utils.dart';
import 'package:workflow/utils/dialog_util.dart';
import 'package:workflow/utils/net_util.dart';
import 'package:workflow/utils/sp_util.dart';

import '../widget/button.dart';
import '../widget/inputdecoration_extension.dart';

///ios编译产物发布上传
class ReleaseUploadIos extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ReleaseUploadIosState();
  }
}

class _ReleaseUploadIosState extends State<ReleaseUploadIos> {
  bool isUploading = false;

  final _gitUrlController = TextEditingController();
  final _gitTagVersionController = TextEditingController();
  final _localGitPathController = TextEditingController();

  final _gitUrlSpKey = 'iosGitUrl';
  final _localGitPath = 'iosLocalGitPath';
  final _tPathSpKey = 'release_tPath';

  @override
  void initState() {
    super.initState();
    SpUtil.getString(_gitUrlSpKey).then((onValue) {
      if (onValue != null) {
        setState(() {
          _gitUrlController.text = onValue;
        });
      }
    });
    SpUtil.getString(_localGitPath).then((onValue) {
      if (onValue != null) {
        setState(() {
          _localGitPathController.text = onValue;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
          width: double.infinity,
          child: Text(
            'iOS',
            style: TextStyle(fontSize: 15, color: Colors.blueGrey),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
          height: 80,
          child: TextField(
            maxLines: 1,
            controller: _localGitPathController,
            decoration: InputDecoration(
                    hintText: '请输入本地git仓库目录',
                    prefixIcon: Icon(
                      Icons.folder,
                      color: Theme.of(context).hoverColor,
                    ))
                .asMgpInputDecoration(
                    onClearTap: _handleGitDirClear,
                    context: context,
                    onDirectoryChanged: _handleGitDirChanged),
          ),
        ),
        Container(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    maxLines: 1,
                    controller: _gitUrlController,
                    decoration: InputDecoration(
                        hintText: '请输入需要上传的git地址',
                        prefixIcon: Icon(
                          Icons.link,
                          color: Theme.of(context).hoverColor,
                        )).asMgpInputDecoration(onClearTap: () {
                      setState(() {
                        _gitUrlController.text = '';
                      });
                    }),
                  ),
                  flex: 2,
                ),
                Padding(padding: EdgeInsets.all(10)),
                Expanded(
                    child: TextField(
                  maxLines: 1,
                  controller: _gitTagVersionController,
                  decoration: InputDecoration(
                      hintText: '请输入Tag Version',
                      prefixIcon: Icon(
                        Icons.turned_in_not,
                        color: Theme.of(context).hoverColor,
                      )).asMgpInputDecoration(onClearTap: () {
                    setState(() {
                      _gitTagVersionController.text = '';
                    });
                  }),
                ))
              ],
            )),
        Container(
          height: 40,
          margin: EdgeInsets.all(20),
          alignment: Alignment.center,
          child: '提交到git'.asButton(
              onPress: _upload,
              color: isUploading ? Theme.of(context).splashColor : null,
              trailing: isUploading
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
              builder: (child) => FractionallySizedBox(
                  widthFactor: 0.33,
                  alignment: Alignment.center,
                  child: child)),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  _upload() async {
    if (_check()) return;

    _savePath();

    var tPath = await SpUtil.getString(_tPathSpKey);

    setState(() {
      isUploading = true;
    });
    var param = {
      'lPath': _localGitPathController.text,
      'tPath': tPath,
      'sourceUrl': _gitUrlController.text,
      'version': _gitTagVersionController.text
    };

    String result = await NetUtils.post('/api/release/upload_ios', param);
    logger.info('iOS上传结果:$result');
    try {
      Map value = jsonDecode(result);
      if (mounted) {
        showInfoDialog(context, '${value['data']} ${value['msg']}');
      }
    } on Exception catch (error) {
      logger.info('编译错误:$error');
      if (mounted) {
        showInfoDialog(context, 'iOS上传失败');
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  bool _check() {
    if (isUploading && !mounted) return true;

    return _checkEmpty(_localGitPathController.text, '本地git仓库目录不能为空') ||
        _checkEmpty(_gitUrlController.text, 'git地址不能为空') ||
        _checkEmpty(_gitTagVersionController.text, 'git Tag Version不能为空');
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
    SpUtil.setString(_gitUrlSpKey, _gitUrlController.text);
    SpUtil.setString(_localGitPath, _localGitPathController.text);
  }

  void _handleGitDirClear() {
    setState(() {
      _localGitPathController.text = '';
    });
  }

  void _handleGitDirChanged(String directory) {
    setState(() {
      _localGitPathController.text = directory;
    });
  }
}
