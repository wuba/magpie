import 'package:flutter/material.dart';
import 'package:workflow/component/log/log_page.dart';

//弹出的日志界面，放到Overlay上，保证在界面loading的时候，日志在最上层，能对日志进行操作和查看
class LogOverlay {
  static OverlayEntry _overlayEntry = null;
  static void showLogOverlay(BuildContext context) {
    OverlayState overlayState = Overlay.of(context);
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: (context) {
        return Positioned(
          left: 0,
          top: MediaQuery.of(context).size.height / 2 - 30,
          bottom: 0,
          right: 0,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                GestureDetector(
                  onTap: () => LogOverlay.dismissLogOverlay(),
                  child: Icon(Icons.close),
                ),
                LogPage(topBarColor: Color(0xffF3F3F3), margin: const EdgeInsets.all(0), showFilter: false)
              ],
            ),
        );
      });
      overlayState.insert(_overlayEntry);
    }
  }

  static void dismissLogOverlay() {
    if (_overlayEntry != null && _overlayEntry is OverlayEntry) {
      _overlayEntry.remove();
      _overlayEntry = null;
    }
  }
}

//页面左下角的日志按钮，放到Overlay上，保证界面在loading的时候还能使用这个按钮
class LogOverlayBtn {
  static OverlayEntry _overlayEntry = null;
  static void showLogOverlay(BuildContext context) {
    OverlayState overlayState = Overlay.of(context);
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: (context) {
        return Positioned(
          bottom: 10,
          left: 20,
          width: 40,
          height: 40,
          child: Container(
            child: FloatingActionButton(
              onPressed: () => LogOverlay.showLogOverlay(context),
              backgroundColor: Theme.of(context).primaryColor,
              child: Text('日志'),
            ),
          ),
        );
      });
      overlayState.insert(_overlayEntry);
    }
  }

  static void dismissLogOverlay() {
    if (_overlayEntry != null && _overlayEntry is OverlayEntry) {
      _overlayEntry.remove();
      _overlayEntry = null;
    }
    //关掉日志层
    LogOverlay.dismissLogOverlay();
  }
}
