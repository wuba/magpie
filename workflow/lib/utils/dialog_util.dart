import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workflow/component/widget/markdown_doc.dart';

///仅仅是用来显示提示信息的dialog
void showInfoDialog(BuildContext context, String msg, {String titleStr}) {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(
            msg != null ? msg : '',
            style: TextStyle(color: Colors.black, fontSize: 16.0),
          ),
          title: Center(
              child: Text(
            titleStr != null ? titleStr : '提示',
            style: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
                fontWeight: FontWeight.bold),
          )),
          actions: <Widget>[
            FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('确定'))
          ],
        );
      });
}

///显示markdown内容的提示
void showMarkdownInfo(BuildContext context, String mPath, String mData) {
  showCupertinoDialog(
      context: context,
      builder: (_) {
        return Stack(
          children: <Widget>[
            Container(
              margin: EdgeInsets.all(100),
              color: Colors.white,
              child: MarkDownDoc(mdPath: mPath, mData: mData),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                child: Container(
                  padding: EdgeInsets.all(50),
                  child: Icon(
                    Icons.close,
                    color: Colors.orange,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            )
          ],
        );
      });
}
