import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ContentPanel extends StatefulWidget {
  final List<Widget> children;
  final Widget bottomBar;

  ContentPanel({
    Key key,
    @required this.children,
    this.bottomBar,
  })  : assert(children != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ContentPanelState();
  }
}

class ContentPanelState extends State<ContentPanel> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        widget.children[index],
        widget.bottomBar,
      ]),
    );
  }

  void changeIndex(int i) {
    setState(() {
      index = i;
    });
  }
}
