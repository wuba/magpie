import 'package:flutter/cupertino.dart';
import 'package:workflow/component/log/log_item_widget.dart';
import 'package:workflow/component/log/log_utils.dart';

class LogListView extends StatefulWidget {
  final List<WBLogRecord> logList;
  final bool scroll;

  LogListView(this.logList, {this.scroll});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<LogListView> {
  var scrolling = false;
  ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();
    updateScroll();
  }

  @override
  Widget build(BuildContext context) {
    updateScroll();
    return Expanded(
      child: NotificationListener(
        child: ListView.builder(
          controller: controller,
          itemCount: widget.logList.length,
          itemBuilder: (_, index) =>
              LogItemWidget(model: widget.logList[index]),
        ),
        onNotification: _onChanged,
      ),
    );
  }

  bool _onChanged(Notification notification) {
    switch (notification.runtimeType) {
      case ScrollEndNotification:
        scrolling = false;
        updateScroll(duration: Duration(seconds: 2));
        break;
      default:
        scrolling = true;
    }
    return false;
  }

  void updateScroll({Duration duration}) {
    if (!scrolling && widget.scroll) {
      Future.delayed(duration ?? Duration(milliseconds: 20), () {
        if (!mounted) {
          return;
        }
        controller.jumpTo(controller.position.maxScrollExtent);
      });
    }
  }
}
