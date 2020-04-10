import 'package:flutter/material.dart';

//下拉选择框

typedef SelectedCallBack = void Function(String selectStr);

class DropDownMenu extends StatefulWidget {
  DropDownMenu(
      {@required this.menuList,
      this.title,
      this.normalColor = Colors.black,
      this.selectColor = Colors.orange,
      this.selectIcon = Icons.check_circle,
      this.titleTextStyle,
      this.onSelected});

  final String title;
  final List<String> menuList;
  final Color normalColor; //正常text的颜色
  final Color selectColor; //被选中后text的颜色
  final IconData selectIcon; //被选中的右侧的图片，默认是✅
  final TextStyle titleTextStyle;
  final SelectedCallBack onSelected;

  @override
  State<StatefulWidget> createState() => _DropDownMenuState();
}

class _DropDownMenuState extends State<DropDownMenu> {
  String _selectText = '';
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _selectText = widget.menuList.first;
  }

  //创建子item
  List<PopupMenuItem<String>> _itemBuilder(BuildContext context) {
    setState(() {
      _isOpen = true;
    });
    return widget.menuList.map((s) {
      return PopupMenuItem<String>(
        value: s,
        child: Row(
          children: <Widget>[
            Text(s,
                style: TextStyle(
                    color: (_selectText == s
                        ? widget.selectColor
                        : widget.normalColor))),
            Expanded(
              child: Text(''),
            ),
            _selectText == s
                ? Icon(
                    widget.selectIcon ?? Icons.check_circle,
                    color: widget.selectColor,
                    size: 20,
                  )
                : Container(
                    width: 20,
                    height: 20,
                  )
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text((widget.title != null ? '${widget.title}:' : ''),
                style: widget.titleTextStyle ?? TextStyle()),
            PopupMenuButton<String>(
              onSelected: (s) {
                if (widget.onSelected != null) {
                  widget.onSelected(s);
                }
                setState(() {
                  _selectText = s;
                  _isOpen = false;
                });
              },
              onCanceled: () {
                setState(() {
                  _isOpen = false;
                });
              },
              itemBuilder: _itemBuilder,
              offset: Offset(0, 60),
              child: Container(
                height: 25,
                margin: const EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  border: Border.all(color: Colors.black12, width: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  children: <Widget>[
                    Container(
                      alignment: Alignment.center,
                      constraints: BoxConstraints(minWidth: 70),
                      child: Text(_selectText == null ? '' : _selectText,
                          style: TextStyle(
                              color: widget.selectColor,
                              fontWeight: FontWeight.bold)),
                    ),
                    Icon(
                        _isOpen == true
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Colors.black54)
                  ],
                ),
              ),
            )
          ],
        ));
  }
}
