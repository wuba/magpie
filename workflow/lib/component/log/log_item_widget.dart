import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workflow/component/log/log_utils.dart';
import 'package:workflow/utils/clipboard_compact.dart';
import 'package:workflow/utils/date_format_util.dart';

/// 单行日志展示控件
class LogItemWidget extends StatelessWidget {
  final WBLogRecord model;

  const LogItemWidget({Key key, this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var text =
        '${DateFormatter.stringWithDateString(dateStr: model.time)} ${model.level}  ${model.message}';
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, top: 10),

      /// 复制待优化，使用TextField有矛盾处：可修改，设为只读时有不可复制
      /// SelectableText 有bug, flutter-web不支持
      child: Tooltip(
        message: '单击复制',
        preferBelow: false,
        verticalOffset: 0,
        child: GestureDetector(
          child: Text(text, style: textStyle(model.level)),
          onTap: () {
            Clipboard.setData(text);
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('日志已拷贝至粘贴板'),
            ));
          },
        ),
      ),
    );
  }

  TextStyle textStyle(String level) {
    if (level == WBLevel.INFO) {
      return TextStyle(color: Colors.black, fontSize: 13);
    } else if (level == WBLevel.ERROR) {
      return TextStyle(color: Colors.red[700], fontSize: 13);
    } else if (level == WBLevel.SUCCESS) {
      return TextStyle(color: Colors.green[700], fontSize: 13);
    } else if (level == WBLevel.WARNING) {
      return TextStyle(color: Colors.yellow[700], fontSize: 13);
    } else {
      return TextStyle(color: Colors.black, fontSize: 13);
    }
  }
}
