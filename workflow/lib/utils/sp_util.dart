import 'package:shared_preferences/shared_preferences.dart';

class SpUtil {
  static Future<bool> setString(String key, String value) async {
    var prefs = await SharedPreferences.getInstance();
    return await prefs.setString(key, value);
  }

  static Future<String> getString(String key) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<bool> remove(String key) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  static Future<bool> clear(String key) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
}

// 工程目录
final tPathSpKey = 'project_Path';
// 工程入口
final ePathSpKey = 'project_entrance';
