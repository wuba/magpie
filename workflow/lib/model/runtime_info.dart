import 'package:json_annotation/json_annotation.dart';
part 'runtime_info.g.dart';

@JsonSerializable()
class RuntimeInfo {
  @JsonKey(name: 'runtime_title')
  final String runtimeTitle;
  @JsonKey(name: 'runtime_value')
  final String runtimeValue;
  @JsonKey(name: 'version_title')
  final String versionTitle;
  final VersionData data;

  RuntimeInfo(
      this.runtimeTitle, this.runtimeValue, this.versionTitle, this.data);

  factory RuntimeInfo.fromJson(Map<String, dynamic> json) =>
      _$RuntimeInfoFromJson(json);

  Map<String, dynamic> toJson() => _$RuntimeInfoToJson(this);
}

@JsonSerializable()
class VersionData {
  @JsonKey(name: 'fltVersion')
  final String flutterVersion;
  @JsonKey(name: 'wbVersion')
  final String magpieVersion;
  @JsonKey(name: 'downUrl')
  final String repoUrl;
  @JsonKey(name: 'docUrl')
  final String docUrl;

  VersionData(
      this.flutterVersion, this.magpieVersion, this.repoUrl, this.docUrl);
  factory VersionData.fromJson(Map<String, dynamic> json) =>
      _$VersionDataFromJson(json);

  Map<String, dynamic> toJson() => _$VersionDataToJson(this);
}