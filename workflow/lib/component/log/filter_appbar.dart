import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workflow/component/widget/drop_down_menu.dart';
import 'package:workflow/provider/log_state_provider.dart';

/// 日志的表头
class FilterAppBar extends StatefulWidget {
  final List<String> menu;
  final void Function(String level) onMenuTap;
  final GestureTapCallback onClearTap;
  final Color backgroundColor;

  const FilterAppBar(this.menu,
      {Key key,
      this.onMenuTap,
      this.onClearTap,
      this.backgroundColor = Colors.white})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<FilterAppBar> {
  @override
  Widget build(BuildContext context) {
    var textColor = Color(0xFF666666);
    return Container(
      height: 60,
      color: widget.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: <Widget>[
          Icon(Icons.text_rotate_vertical, color: textColor),
          Container(width: 10),
          Text('日志', style: TextStyle(color: textColor)),
          Spacer(),
          widget.menu != null && widget.menu.length > 0
              ? DropDownMenu(
                  title: '过滤',
                  menuList: widget.menu,
                  titleTextStyle: TextStyle(color: textColor),
                  onSelected: widget.onMenuTap,
                )
              : Container(),
          Text('自动滚动', style: TextStyle(color: textColor)),
          Consumer<LogStateProvider>(
            builder: (ctx, provider, child) => Theme(
                data: ThemeData(
                    unselectedWidgetColor: textColor,
                    toggleableActiveColor: textColor),
                child: Checkbox(
                  checkColor: Colors.white,
                  value: provider.needScroll,
                  onChanged: (_) {
                    provider.setScroll(_);
                  },
                )),
          ),
          IconButton(
            icon: Icon(Icons.delete_forever, color: textColor),
            onPressed: widget.onClearTap,
          )
        ],
      ),
    );
  }
}
