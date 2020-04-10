import 'dart:async';
import 'package:logging/logging.dart';

class LoggerUtil {
  static final log = Logger('J');
  static bool debug = true;

  static void i(String msg) {
    if (debug) {
      log.log(Level.INFO, msg);
    }
  }

  static void w(String msg) {
    if (debug) {
      log.log(Level.WARNING, msg);
    }
  }

  static void e(String msg) {
    if (debug) {
      log.log(Level.SEVERE, msg);
    }
  }

  //拦截print方法中的打印信息，比如在跑客户端脚本时，可以拦截到log界面中显示所有日志
  static R logRunZone<R>(R body()) {
    return runZoned(body, zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
      // 很多错误都包含该前缀
      if (line.startsWith("Error:")) {
        LoggerUtil.e(line);
        return;
      }
      LoggerUtil.i(line);
    }));
  }
}
