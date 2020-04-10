import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:workflow/component/device/device_manager.dart';
import 'package:workflow/model/simple_device.dart';

class SharedDataProvider extends ChangeNotifier {
  String _buildNumber = '';
  SimpleDevice _selectedDevice;
  List<SimpleDevice> deviceListCache = [];

  void update() async {
    var num = await rootBundle.loadString('build_number');
    _buildNumber = num.trim();
    _selectedDevice = await DeviceManager.currentDevice();
    notifyListeners();
  }

  void changeDevice(SimpleDevice device) {
    _selectedDevice = device;
    notifyListeners();
  }

  bool get hasData {
    return _buildNumber != null;
  }

  String get buildNumber {
    return _buildNumber;
  }

  SimpleDevice currentDevice() {
    return _selectedDevice;
  }

}
