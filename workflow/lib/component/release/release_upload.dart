import 'package:flutter/material.dart';

import '../widget/container_extension.dart';
import 'release_upload_android.dart';
import 'release_upload_ios.dart';

///上传发布
class ReleaseUpload extends StatelessWidget {
  bool debugMode = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(20),
            width: double.infinity,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '上传',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          ReleaseUploadAndroid(),
          ReleaseUploadIos(),
        ],
      ),
    ).asCard;
  }
}
