import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:workflow/utils/net_util.dart';

import '../widget/hovor_extension.dart';

class ApplicationInstall extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<ApplicationInstall> {
  String _androidUrl;
  String _iosUrl;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    NetUtils.get('/api/app').then((data) {
      if (mounted) {
        Map map = json.decode(data);
        if (map['code'] == 1) {
          setState(() {
            _androidUrl = map['data']['android'] as String;
            _iosUrl = map['data']['ios'] as String;
            _loadFailed = false;
          });
        } else {
          setState(() {
            _loadFailed = true;
          });
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(map['msg']),
          ));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        DownloadWidget(
          url: _androidUrl,
          error: _loadFailed,
          text: 'Android下载包',
          errorString: 'Android地址加载失败',
          size: 200,
        ),
        Padding(padding: EdgeInsets.only(left: 80)),
        DownloadWidget(
          url: _iosUrl,
          error: _loadFailed,
          text: 'iOS下载包',
          errorString: 'iOS地址加载失败',
          size: 200,
        )
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }
}

class DownloadWidget extends StatelessWidget {
  const DownloadWidget({
    Key key,
    this.url,
    this.error,
    this.errorString,
    this.text,
    this.size,
  });

  final String url;
  final bool error;
  final String errorString;
  final text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (url != null && url.startsWith("http")) {
          html.window.open(url, text);
        }
      },
      child: Card(
        child: Column(children: <Widget>[
          Container(
            height: size ?? 122,
            width: size ?? 122,
            child: url != null
                ? QrImage(
                    data: url, version: QrVersions.auto, size: size ?? 122.0)
                : Center(
                    child:
                        error ? Text(errorString) : CircularProgressIndicator(),
                  ),
          ),
          Center(child: Text(text, style: TextStyle(color: Colors.blue))),
        ]),
      ).pointer,
    );
  }
}
