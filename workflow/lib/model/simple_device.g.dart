// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simple_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimpleDevice _$SimpleDeviceFromJson(Map<String, dynamic> json) {
  return SimpleDevice(
    json['category'] as String,
    json['id'] as String,
    json['name'] as String,
    json['platformType'] as String,
  )
    ..platformName = json['platform'] as String
    ..sdkNameVersion = json['sdkNameVersion'] as String
    ..emulator = json['emulator'] as bool;
}

Map<String, dynamic> _$SimpleDeviceToJson(SimpleDevice instance) =>
    <String, dynamic>{
      'category': instance.category,
      'id': instance.deviceId,
      'name': instance.deviceName,
      'platformType': instance.platform,
      'platform': instance.platformName,
      'sdkNameVersion': instance.sdkNameVersion,
      'emulator': instance.emulator,
    };
