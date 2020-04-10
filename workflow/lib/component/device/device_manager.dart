import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workflow/component/log/log_utils.dart';
import 'package:workflow/model/simple_device.dart';
import 'package:workflow/provider/shared_data_provider.dart';
import 'package:workflow/utils/net_util.dart';
import 'package:workflow/utils/sp_util.dart';

import '../widget/button.dart';
import '../widget/container_extension.dart';

const noDevicesTips = '未检测到连接设备';

/// 设备管理client
class DeviceManager extends StatefulWidget {
  @override
  _DeviceManagerState createState() => _DeviceManagerState();

  /// 获取当前连接的设备
  static Future<SimpleDevice> currentDevice() async {
    // 需要兼容本地缓存版本的current_device新老版本格式
    var jsonString = await SpUtil.getString("current_device");
    try {
      if (jsonString != null && jsonString.isNotEmpty) {
        Map map = jsonDecode(jsonString);
        return SimpleDevice.fromJson(map);
      }
    } catch (e) {
      print(e);
    }
    return SimpleDevice.empty;
  }
}

class _DeviceManagerState extends State<DeviceManager> {
  List<SimpleDevice> deviceList = [];
  bool isLoading = false;
  bool isFilterWebDevices = false;

  @override
  void initState() {
    super.initState();
    deviceList = provider().deviceListCache;
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '设备列表/${deviceList != null ? deviceList.length : 0}',
            style: const TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          Flexible(
              child: deviceList.isNotEmpty
                  ? _generateDeviceList(deviceList)
                  : Center(child: Text(!isLoading ? noDevicesTips : ""))),
          SizedBox(height: 20),
          Center(child: _refreshBtn(refresh)),
        ],
      ),
    ).asCard);
  }

  Widget _generateDeviceList(List<SimpleDevice> devices) {
    if (isFilterWebDevices) {
      devices = devices.where((d) {
        return "web" != d.platform;
      }).toList();
    }
    var currentDevice = provider().currentDevice();
    var id = currentDevice != null ? currentDevice.deviceId : "";
    return ListView.builder(
      itemBuilder: (ctx, i) {
        var selected = devices[i].deviceId == id;
        return Column(children: <Widget>[
          DeviceItem(
            device: devices[i],
            selected: selected,
            onTap: (d) {
              setState(() {
                provider().changeDevice(d);
                String jsonString = jsonEncode(d.toJson());
                SpUtil.setString("current_device", jsonString);
              });
            },
          ),
          Divider(thickness: 1, height: 1)
        ]);
      },
      itemCount: devices.length,
    );
  }

  SharedDataProvider provider() =>
      Provider.of<SharedDataProvider>(context, listen: false);

  /// 刷新按钮
  Widget _refreshBtn(void Function() onClick) {
    var btnText = isLoading ? "刷新中..." : "刷新设备";
    return btnText.asButton(
        circle: true,
        builder: (child) => FractionallySizedBox(
            widthFactor: 0.33, alignment: Alignment.center, child: child),
        onPress: onClick,
        alignment: MainAxisAlignment.center,
        trailing: isLoading
            ? const SizedBox(
                child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white)),
                width: 13,
                height: 13,
              )
            : Icon(Icons.refresh));
  }

  Widget _filterCheckBox() {
    return "不看web设备".asButton(
      onPress: () {},
      circle: true,
      trailing: Theme(
        data: ThemeData(
            unselectedWidgetColor: Colors.white,
            toggleableActiveColor: Theme.of(context).primaryColor),
        child: Checkbox(
            value: isFilterWebDevices,
            onChanged: (b) {
              setState(() {
                isFilterWebDevices = b;
              });
            }),
      ),
      alignment: MainAxisAlignment.center,
      builder: (child) => Container(
        height: 48,
        width: 140,
        child: child,
      ),
    );
  }

  void refresh() {
    setState(() {
      isLoading = true;
    });
    fetchDeviceList().then((map) {
      deviceList = map['devices'];
      var currentDevice = map['selected'];
      provider().changeDevice(currentDevice);
      if (!mounted) {
        return;
      }
      setState(() {
        isLoading = false;
      });
    }).catchError(() {
      debugPrint('device parse error');
      setState(() {
        isLoading = false;
      });
    });
  }

  /// 拉取设备列表
  Future<Map> fetchDeviceList() async {
    var response = await NetUtils.get("/api/device/list");
    debugPrint("decvice => $response");
    var pre = await DeviceManager.currentDevice();
    debugPrint("pre decvice => $pre");
    var devices = SimpleDevice.parseDevices(response);
    debugPrint("decvices => $devices");
    var selected;
    if (devices.isNotEmpty) {
      selected = devices.firstWhere((item) => item.deviceId == pre.deviceId,
          orElse: () => devices[0]);
      String jsonString = jsonEncode(selected.toJson());
      SpUtil.setString("current_device", jsonString);
      logger.info("device list count : ${devices.length}");
      provider().deviceListCache = devices;
    } else {
      SpUtil.setString("current_device", "");
      logger.warning("device list empty");
    }
    return {"selected": selected, 'devices': devices};
  }
}

/// 设备item
class DeviceItem extends StatelessWidget {
  final SimpleDevice device;
  final bool selected;
  final DeviceItemClick onTap;

  const DeviceItem({Key key, this.device, this.onTap, this.selected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData leadingIcon;
    switch (device.platform) {
      case "android":
        leadingIcon = Icons.android;
        break;
      case "ios":
        leadingIcon = Icons.phone_iphone;
        break;
      case "web":
        leadingIcon = Icons.web;
        break;
      default:
        leadingIcon = Icons.device_unknown;
    }
    var primaryColor = Theme.of(context).primaryColor;
    return InkWell(
      hoverColor: Colors.black12,
      child: ListTile(
        leading: Icon(
          leadingIcon,
          color: selected ? primaryColor : null,
          size: 40,
        ),
        title: Text(device.deviceName),
        subtitle: Text(
            '${device.deviceName} • ${device.deviceId} • ${device.platformName} • ${device.emulator ? "模拟器" : "真机"}'),
        trailing: selected ? Icon(Icons.turned_in, color: primaryColor) : null,
      ),
      onTap: () => onTap(device),
    );
  }
}

typedef DeviceItemClick = void Function(SimpleDevice device);
