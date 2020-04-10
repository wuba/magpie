import 'package:jaguar/jaguar.dart';

import '../daemon/device.dart';
import '../response_bean.dart';
import 'base_controller.dart';

final String api_devices_list = '/api/device/list';

class DeviceController extends BaseController {
  final _daemon = FlutterDaemon();

  Future<ResponseBean> getDeviceList(Context ctx) async {
    await _daemon.attach();
    var response = await _daemon.getDevice();
    var devices = response['result'];
    // [
    // {
    //   "id": "web-server",
    //   "name": "Web Server",
    //   "platform": "web-javascript",
    //   "emulator": false,
    //   "category": "web",
    //   "platformType": "web",
    //   "ephemeral": false,
    //   "emulatorId": null
    // }
    // ]
    // retry once if device is not ready
    if (devices == null || devices is Iterable && devices.length == 0) {
      await Future.delayed(Duration(seconds: 4));
      response = await _daemon.getDevice();
      devices = response['result'];
    }
    if (devices != null) {
      return ResponseBean(devices);
    } else {
      return ResponseBean.error("get device failed");
    }
  }

  @override
  route(String path, Context context) async {
    return getDeviceList(context);
  }
}
