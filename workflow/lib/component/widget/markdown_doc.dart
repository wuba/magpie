import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkDownDoc extends StatelessWidget {
  final String mdPath;
  final String mData;

  ///path和data必须传一个，优先加载data中内容
  const MarkDownDoc({Key key, this.mdPath, this.mData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _buildContent(context),
    );
  }

  _buildContent(BuildContext context) {
    if (mData != null) {
      return _buildMarkdown(context, mData);
    } else if (mdPath != null) {
      return FutureBuilder(
        future: rootBundle.loadString(mdPath),
        builder: (context, data) {
          return _buildMarkdown(context, data.data);
        },
      );
    } else {
      return Container(
        padding: EdgeInsets.fromLTRB(50, 100, 50, 100),
        child: Text(
          'no data',
          style:
              TextStyle(decoration: TextDecoration.none, color: Colors.black),
        ),
      );
    }
  }

  _buildMarkdown(BuildContext context, String data) {
    return Markdown(
      data: data ?? "no md",
      onTapLink: (href) {
        _handleHref(context, href);
      },
      imageBuilder: (Uri uri) {
        try {
          return Image.asset('doc/${uri.path}');
        } catch (e) {
          return Text('');
        }
      },
    );
  }

  /// 处理markdown点击事件
  _handleHref(BuildContext context, String href) {
    debugPrint("$href");
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MarkDownDoc(
                  mdPath: href,
                  mData: null,
                )));
  }
}
