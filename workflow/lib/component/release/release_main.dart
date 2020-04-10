import 'package:flutter/material.dart';
import 'package:workflow/utils/dialog_util.dart';
import 'release_build.dart';
import 'release_upload.dart';

class ReleaseMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          ReleaseBuild(),
          ReleaseUpload(),
          Container(
            padding: EdgeInsets.all(20),
            child: GestureDetector(
              child: Row(
                children: <Widget>[
                  Text(
                    "需要帮助",
                    style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(2, 0, 0, 0),
                  ),
                  Icon(
                    Icons.help,
                    color: Colors.blueGrey,
                    size: 18,
                  )
                ],
              ),
              onTap: () {
                _showHelp(context);
              },
            ),
          )
        ],
      ),
    );
  }

  _showHelp(BuildContext context) {
    showMarkdownInfo(context, 'doc/help/release_help.md', null);
  }
}
