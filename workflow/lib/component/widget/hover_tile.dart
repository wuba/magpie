import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'button.dart';

/// Add hover effect to text of [ListTile]
class HoverTile extends StatefulWidget {
  final String text;
  final TextStyle style;
  final GestureTapCallback onTap;
  final Color color;
  final Color hoverColor;
  final bool checked;

  HoverTile(this.text,
      {this.style,
      this.onTap,
      this.color = Colors.black,
      this.hoverColor = Colors.white,
      this.checked = false});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<HoverTile> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) {
        if (_hover) {
          return;
        }
        setState(() {
          _hover = true;
        });
      },
      onExit: (_) {
        if (!_hover) {
          return;
        }
        setState(() {
          _hover = false;
        });
      },
      child: (widget.checked || _hover)
          ? widget.text.asButton(
              onPress: widget.onTap,
              trailing: Icon(Icons.web),
            )
          : widget.text.asPlainButton(
              onPress: widget.onTap,
              trailing: Icon(Icons.web),
            ),
    );
  }
}
