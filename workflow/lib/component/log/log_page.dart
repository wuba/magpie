import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workflow/component/log/filter_appbar.dart';
import 'package:workflow/component/log/log_listview.dart';
import 'package:workflow/component/log/log_utils.dart';
import 'package:workflow/provider/log_state_provider.dart';

import '../widget/container_extension.dart';

//日志界面
class LogPage extends StatefulWidget {
  final Color topBarColor; //顶部bar的颜色
  final EdgeInsets margin;  //间距
  final bool showFilter; //
  @override
  State<StatefulWidget> createState() => _LogPageState();
  LogPage({this.topBarColor = Colors.white, this.margin, this.showFilter = true});
}

class _LogPageState extends State<LogPage> {
  String level;
  var dataList = <WBLogRecord>[];
  var menus = const [
    '全部',
    WBLevel.INFO,
    WBLevel.ERROR,
    WBLevel.SUCCESS,
    WBLevel.WARNING,
    WBLevel.SERVER,
  ];

  @override
  void initState() {
    super.initState();
    logManager.onLogMsgUpdate = () {
      setState(() {});
    };
    updateLogList(level);
    menus = widget.showFilter!=null&&widget.showFilter==true ? menus: [];
  }

  @override
  void dispose() {
    super.dispose();
    logManager.onLogMsgUpdate = null;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: widget.margin,
        child: Column(children: <Widget>[
          FilterAppBar(menus,
              onMenuTap: updateLogList,
              onClearTap: clearLog,
              backgroundColor: widget.topBarColor ?? Colors.white),
          Consumer<LogStateProvider>(
            builder: (_, provider, __) =>
                LogListView(dataList, scroll: provider.needScroll),
          ),
        ]),
      ).asCard,
    );
  }

  void clearLog() {
    setState(() {
      logManager.removeAllLog();
    });
  }

  void updateLogList(String s) {
    level = s;
    var data = <WBLogRecord>[];
    if (level == null || level == '全部') {
      data = logManager.logList;
    } else {
      data = logManager.logList.where((item) => item.level == level).toList();
    }
    setState(() {
      dataList = data;
    });
  }
}
