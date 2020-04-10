import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:workflow/component/log/log_utils.dart';
import 'package:workflow/utils/dialog_util.dart';
import 'package:workflow/utils/net_util.dart';
import 'package:workflow/utils/sp_util.dart';

import '../widget/inputdecoration_extension.dart';
import '../widget/button.dart';

///安卓aar发布
class ReleaseUploadAndroid extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ReleaseUploadAndroidState();
  }
}

class _ReleaseUploadAndroidState extends State<ReleaseUploadAndroid> {
  final _gitTagVersionController = TextEditingController();
  bool isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
          width: double.infinity,
          child: Text('Android',
              style: TextStyle(fontSize: 15, color: Colors.blueGrey)),
        ),
        Container(
            margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
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
            )),
        Container(
          height: 40,
          margin: EdgeInsets.all(20),
          alignment: Alignment.center,
          child: '发布AAR'.asButton(
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
                widthFactor: 0.33, alignment: Alignment.center, child: child),
          ),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  _upload() async {
    if (_check()) return;

    var tPath = await SpUtil.getString(tPathSpKey);

    setState(() {
      isUploading = true;
    });
    var param = {'tPath': tPath, 'versionTag': _gitTagVersionController.text};

    String result = await NetUtils.post('/api/release/upload_android', param);
    logger.info('AAR上传结果:$result');
    try {
      Map value = jsonDecode(result);
      if (mounted) {
        showInfoDialog(context, '${value['data']} ${value['msg']}');
      }
    } on Exception catch (error) {
      logger.info('编译错误:$error');
      if (mounted) {
        showInfoDialog(context, 'AAR上传失败');
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
    if (isUploading && !mounted) {
      return true;
    }
    return _checkEmpty(_gitTagVersionController.text, 'git Tag Version不能为空');
  }

  bool _checkEmpty(String content, String tip) {
    if (content == null || content.isEmpty) {
      showInfoDialog(context, tip);
      return true;
    }
    return false;
  }
}
