import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workflow/model/menu_item.dart';

import '../widget/button.dart';

// 按需扩展
class Sidebar extends StatefulWidget {
  final TapCallback onTap;
  final List<MenuItem> menus;
  final Widget child;

  const Sidebar({
    Key key,
    this.menus,
    this.onTap,
    this.child,
  })  : assert(onTap != null),
        assert(menus != null && menus.length > 0),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<Sidebar> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[
      Container(
        padding: EdgeInsets.all(20),
        child: Image.asset('data/magpie.png'),
      ),
    ];
    children.addAll(List.generate(
      widget.menus.length,
      (i) {
        var m = widget.menus[i];
        if (i == index) {
          return m.title.asButton(
              onPress: () {
                widget.onTap(i);
                setState(() {
                  index = i;
                });
              },
              trailing: Icon(m.icon));
        }
        return m.title.asPlainButton(
            onPress: () {
              widget.onTap(i);
              setState(() {
                index = i;
              });
            },
            trailing: Icon(m.icon));
      },
    ));
    children.add(Padding(padding: EdgeInsets.only(bottom: 40)));
    if(widget.child!=null) {
      children.add(widget.child);
    }
    return Container(
      width: 300,
      padding: EdgeInsets.only(left: 20, right: 20),
      child: ListView(
        children: children,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

//HoverTile(_menus[i], onTap: () => _onTap(i))
typedef TapCallback = void Function(int index);
