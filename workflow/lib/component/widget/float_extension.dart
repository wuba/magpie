import 'package:flutter/material.dart';

const FloatingActionButtonLocation startFloat =
    _StartFloatFloatingActionButtonLocation();

class _StartFloatFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  const _StartFloatFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    var dx =
        FloatingActionButtonLocation.startTop.getOffset(scaffoldGeometry).dx;
    var dy =
        FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry).dy;
    return Offset(dx, dy);
  }
}
