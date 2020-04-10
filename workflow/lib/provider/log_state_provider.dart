import 'package:flutter/material.dart';

class LogStateProvider extends ChangeNotifier {
  bool _autoScroll = false;

  void setScroll(bool scroll) {
    _autoScroll = scroll;
    notifyListeners();
  }
  
  bool get needScroll {
    return _autoScroll;
  }
}
