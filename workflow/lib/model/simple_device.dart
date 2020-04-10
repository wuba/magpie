import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'simple_device.g.dart';

@JsonSerializable()
class SimpleDevice extends Object {
  @JsonKey(name: 'category')
  String category;

  @JsonKey(name: 'id')
  String deviceId;

  @JsonKey(name: 'name')
  String deviceName;

  @JsonKey(name: 'platformType')
  String platform;

  @JsonKey(name: 'platform')
  String platformName; // android-arm64

  @JsonKey(name: 'sdkNameVersion')
  String sdkNameVersion; // Android 8.0.0 (API 26)

  @JsonKey(name: 'emulator')
  bool emulator;

  SimpleDevice(
    this.category,
    this.deviceId,
    this.deviceName,
    this.platform,
  );

  static SimpleDevice get empty => SimpleDevice("", "", "", "");

  factory SimpleDevice.fromJson(Map<String, dynamic> srcJson) =>
      _$SimpleDeviceFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SimpleDeviceToJson(this);

  static List<SimpleDevice> parseDevices(String origin) {
    Map map = jsonDecode(origin);
    var array = map["data"];
    if (array is Iterable) {
      var r = array.map<SimpleDevice>((item) {
        return SimpleDevice.fromJson(item);
      });
      return r.toList();
    }
    return [];
  }
}
