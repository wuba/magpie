/*
时间格式化  如，给定format字符串
'yyyy-MM-dd HH:mm:ss'  ->     '2019-12-16 18:10:01'
yyyy 年
MM  月
dd  日
HH  时
mm  分
ss  秒
*/
import 'package:flutter/cupertino.dart';

class DateFormatter {
  static String stringWithDateString(
      {String format = 'yyyy-MM-dd HH:mm:ss', @required String dateStr}) {
    var date = DateTime.parse(dateStr);
    return stringWithDate(format: format, date: date);
  }

  static String stringWithDate(
      {String format = 'yyyy-MM-dd HH:mm:ss', @required DateTime date}) {
    if (date == null) return '';
    var dateS = '';
    //年
    if (format.contains('yyyy')) {
      dateS = date.year.toString();
      dateS = _appendSepString(format, dateS, 'yyyy');
    }

    //月
    if (format.contains('MM')) {
      dateS = dateS + date.month.toString().padLeft(2, '0');
      dateS = _appendSepString(format, dateS, 'MM');
    }

    //日
    if (format.contains('dd')) {
      dateS = dateS + date.day.toString().padLeft(2, '0');
      dateS = _appendSepString(format, dateS, 'dd');
    }

    //时
    if (format.contains('HH')) {
      dateS = dateS + date.hour.toString().padLeft(2, '0');
      dateS = _appendSepString(format, dateS, 'HH');
    }

    //分
    if (format.contains('mm')) {
      dateS = dateS + date.minute.toString().padLeft(2, '0');
      dateS = _appendSepString(format, dateS, 'mm');
    }

    //秒
    if (format.contains('ss')) {
      dateS = dateS + date.second.toString().padLeft(2, '0');
      dateS = _appendSepString(format, dateS, 'ss');
    }
    return dateS;
  }

  static String _appendSepString(
      String format, String oriString, String matchString) {
    var temp = ['y', 'M', 'd', 'H', 'm', 's'];
    var index = format.indexOf(matchString);
    var sepIndex = index + matchString.length;

    for (var i = sepIndex; i < format.length; i++) {
      var sep = (format.length > sepIndex)
          ? format.substring(sepIndex, sepIndex + 1)
          : '';
      if (!temp.contains(sep)) {
        oriString = oriString + sep;
      } else {
        break;
      }
      sepIndex++;
    }
    return oriString;
  }
}
