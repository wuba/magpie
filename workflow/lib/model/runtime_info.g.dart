// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'runtime_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RuntimeInfo _$RuntimeInfoFromJson(Map<String, dynamic> json) {
  return RuntimeInfo(
    json['runtime_title'] as String,
    json['runtime_value'] as String,
    json['version_title'] as String,
    json['data'] == null
        ? null
        : VersionData.fromJson(json['data'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$RuntimeInfoToJson(RuntimeInfo instance) =>
    <String, dynamic>{
      'runtime_title': instance.runtimeTitle,
      'runtime_value': instance.runtimeValue,
      'version_title': instance.versionTitle,
      'data': instance.data,
    };

VersionData _$VersionDataFromJson(Map<String, dynamic> json) {
  return VersionData(
    json['fltVersion'] as String,
    json['wbVersion'] as String,
    json['downUrl'] as String,
    json['docUrl'] as String,
  );
}

Map<String, dynamic> _$VersionDataToJson(VersionData instance) =>
    <String, dynamic>{
      'fltVersion': instance.flutterVersion,
      'wbVersion': instance.magpieVersion,
      'downUrl': instance.repoUrl,
      'docUrl': instance.docUrl,
    };
