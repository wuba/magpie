import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'hovor_extension.dart';

/// Button扩展，方便使用自定义的按钮样式
extension Button on String {
  /// 1.Simple button
  /// 'New Button'.asButton(onPress: () => debugPrint('clicked')),
  ///
  /// 2.Button with circle radius
  /// 'Round Button'.asButton(onPress: () => debugPrint('clicked'), circle: true),

  /// 3.Button with custom container
  ///
  /// ```dart
  /// 'Round Button'.asButton(
  ///    onPress: () => debugPrint('clicked'),
  ///    circle: true,
  ///    builder: (child) => Container(
  ///      width: 200, alignment: Alignment.center, child: child)),
  /// ```
  Widget asButton({
    @required VoidCallback onPress,
    double borderRadius = 3,
    bool circle = false,
    Color color,
    Widget trailing,
    Builder builder,
    MainAxisAlignment alignment = MainAxisAlignment.start,
  }) {
    return RaisedButton(
      color: color ?? Color(0xFFFB5638),
      textColor: Colors.white,
      elevation: 1,
      hoverElevation: 1,
      highlightElevation: 1,
      shape: circle
          ? StadiumBorder()
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
      onPressed: onPress,
      child: builder != null
          ? builder(_concat(trailing, Text(this), alignment: alignment))
          : _concat(trailing, Text(this), alignment: alignment),
    ).pointer;
  }

  Widget asPlainButton({
    @required VoidCallback onPress,
    Color color,
    double borderRadius = 3,
    bool circle = false,
    Widget trailing,
    Builder builder,
    MainAxisAlignment alignment = MainAxisAlignment.start,
  }) {
    return RaisedButton(
      textColor: color ?? Colors.grey[700],
      color: Colors.transparent,
      elevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: circle
          ? StadiumBorder()
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
      onPressed: onPress,
      child: builder != null
          ? builder(_concat(trailing, Text(this), alignment: alignment))
          : _concat(trailing, Text(this), alignment: alignment),
    ).pointer;
  }

  Widget _concat(Widget trailing, Widget child, {MainAxisAlignment alignment}) {
    if (trailing == null) {
      return child;
    }
    return Row(mainAxisAlignment: alignment, children: [
      trailing,
      Padding(padding: EdgeInsets.only(right: 8)),
      Text(this)
    ]);
  }
}

typedef Builder = Widget Function(Widget child);
