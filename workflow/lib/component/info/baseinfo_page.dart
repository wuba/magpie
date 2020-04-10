import 'dart:html' as html;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:workflow/provider/runtime_provider.dart';
import 'package:workflow/provider/shared_data_provider.dart';

import '../widget/container_extension.dart';
import '../widget/hovor_extension.dart';

class BaseInfoPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BaseInfoPageState();
}

class _BaseInfoPageState extends State<BaseInfoPage> {

  @override
  void initState() {
    super.initState();
    Provider.of<RuntimeProvider>(context,listen: false).loadData();
  }

  //创建item
  Widget _buildItem(String title, String content) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title ?? '',
            style: TextStyle(fontSize: 18.0),
            textAlign: TextAlign.left,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: Text(content ?? "", style: TextStyle(fontSize: 15.0)),
          ),
        ],
      ),
    ).asCard;
  }

  //创建Cli item
  Widget _buildCliItem(String title, String fltVersion, String wbVersion,
      String downUrl, String docUrl) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title ?? '', style: TextStyle(fontSize: 18)),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          Text('Flutter SDK: $fltVersion'),
          Consumer<SharedDataProvider>(
            builder: (ctx, provider, _) {
              return Text('Magpie Workflow: Beta v1.${provider.buildNumber}');
            },
          ),
          _buildCliItemColumnOption(
              _buildText('Magpie SDK: '),
              _buildText(
                downUrl,
                fontColor: Colors.blue,
              ),
              downUrl),
          _buildCliItemColumnOption(
              _buildText('Magpie Doc: '),
              _buildText(
                docUrl,
                fontColor: Colors.blue,
              ),
              docUrl),
        ],
      ),
    ).asCard;
  }

  Widget _buildCliItemColumnOption(
      Widget prefixText, Widget suffixText, String url) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Row(
        children: <Widget>[
          prefixText,
          url != null
              ? GestureDetector(
                  child: suffixText,
                  onTap: () {
                    if (url != null) {
                      html.window.open(url, url);
                    }
                  },
                ).pointer
              : suffixText,
        ],
      ),
    );
  }

  Widget _buildText(String text, {Color fontColor, double fontSize = 15}) {
    return Text(
      text ?? "",
      textAlign: TextAlign.left,
      style: TextStyle(color: fontColor, fontSize: fontSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer<RuntimeProvider>(builder: (_, provider, child) {
        if (provider.hasData) {
          var runtime = provider.data;
          var children = <Widget>[
            _buildItem(runtime.runtimeTitle, runtime.runtimeValue)
          ];
          var data = runtime.data;
          if (data != null) {
            children.add(_buildCliItem(
              runtime.versionTitle,
              data.flutterVersion,
              data.magpieVersion,
              data.repoUrl,
              data.docUrl,
            ));
          }
          return ListView(children: children);
        }
        return child;
      },
          child: Center(child: CircularProgressIndicator())),
    );
  }
}
