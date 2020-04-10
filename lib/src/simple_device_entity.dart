class SimpleDeviceEntity {
  List<SimpleDevice> devices;

  SimpleDeviceEntity({this.devices});

  SimpleDeviceEntity.fromJson(Map<String, dynamic> json) {
    if (json['devices'] != null) {
      devices = new List<SimpleDevice>();
      (json['devices'] as List).forEach((v) {
        devices.add(new SimpleDevice.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.devices != null) {
      data['devices'] = this.devices.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

//MI 5s Plus • 18b15714 • android-arm64 • Android 8.0.0 (API 26)
class SimpleDevice {
  String category; // mobile
  String deviceId; // 18b15714
  String deviceName; // MI 5s Plus
  String platform; // android
  String platformName; // android-arm64
  String sdkNameVersion; // Android 8.0.0 (API 26)
  SimpleDevice({
    this.category,
    this.deviceId,
    this.deviceName,
    this.platform,
    this.platformName,
    this.sdkNameVersion,
  });

  SimpleDevice.fromJson(Map<String, dynamic> json) {
    category = json['category'];
    deviceId = json['deviceId'];
    deviceName = json['deviceName'];
    platform = json['platform'];
    platformName = json['platformName'];
    sdkNameVersion = json['sdkNameVersion'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['category'] = this.category;
    data['deviceId'] = this.deviceId;
    data['deviceName'] = this.deviceName;
    data['platform'] = this.platform;
    data['platformName'] = this.platformName;
    data['sdkNameVersion'] = this.sdkNameVersion;
    return data;
  }
}

class UserDemo {
  final String name;
  final String email;

  UserDemo(this.name, this.email);
}
