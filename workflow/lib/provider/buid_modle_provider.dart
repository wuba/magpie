import 'package:flutter/foundation.dart';
import 'package:workflow/utils/sp_util.dart';

class BuildModeProvider extends ChangeNotifier {
  bool _debugMode = null;

  void setBuildMode(bool debug) {
    _debugMode = debug;
    SpUtil.setString("build_mode", debug ? 'debug' : 'release');
    notifyListeners();
  }

  void sync() async {
    var mode = SpUtil.getString('build_mode');
    _debugMode = mode == 'debug';
  }

  bool get mode {
    return _debugMode ?? false;
  }
}
