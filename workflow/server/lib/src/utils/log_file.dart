import 'dart:io' as io;

import '../tools/base/file_system.dart';
import '../tools/base/platform.dart';

class LogFile {
  //单个文件大小限制
  static final int _maxFilesize = 2 * 1024 * 1024;
  //分别记录上一次IO时间，以及需要变更文件名的时间点
  DateTime _recent;
  final DateTime _identifier = DateTime.now();
  //用于文件名命名，主要是超出定制大小后索引自增，从1开始
  var _fileIndex = 1;
  String _fileName = '';
  io.File _file;
  io.IOSink _sink;
  String _folder;

  LogFile._();
  factory LogFile() => getInstance();
  static LogFile _instance;
  static LogFile getInstance() {
    if(_instance == null){
      _instance = LogFile._();
      _instance._init();
    }
    return _instance;
  }

  //初始化
  void _init(){
    _recent = DateTime.now();
    _fileName = filePathWithFolder();
  }

  int get identifier{
    return _identifier.hashCode;
  }

  String filePathWithFolder({String folder}){
    bool isWindows = platform.operatingSystem == 'windows';
    bool hasFolder = folder != null && folder.isNotEmpty;
    var dir;
    if(isWindows){
      dir = '${userHomePath()}\\.mgpcli\\log';
      dir = hasFolder?'$dir\\$folder\\':'$dir\\';
    }else{
      dir = '${userHomePath()}/.mgpcli/log';
      dir = hasFolder?'$dir/$folder/':'$dir/';
    }
    var directory = io.Directory(dir);
    directory.createSync(recursive: true);
    return '${directory.path}${_recent.year}-${_recent.month}-${_recent.day}_${identifier}_${_fileIndex}.log'; 
  }

  String _getFileName(String folder){
    folder = folder!=null ? folder.trim() : '';
    var change = false;
    //如果不是今天，重新生成文件
    if(_isToDay() == false || _folder != folder){
      _recent = DateTime.now();
      _fileIndex = 1;
      _folder = folder;
      _fileName = filePathWithFolder(folder: _folder);
      change = true;
    }else{
      //如果文件大于设定的最大值，新增文件
      var file = io.File(_fileName);
      var exists = file.existsSync();
      if(exists && file.lengthSync() > _maxFilesize){
        _fileIndex ++;
        _folder = folder;
        _recent = DateTime.now();
        _fileName = filePathWithFolder(folder: _folder);
        change = true;
      }
    }
    print(_fileName);
    if(change && _file != null) {
       _sink.close();
      _file = null;
      _sink = null;
    }
    return _fileName;
  }

  //写文件 folder文件夹名称，不传的话，默认写到log底下，否则写到log/folder下
  //如传入设备名作为folder ， log/iphone11
  void write(String log, {String folder}){
    var fileName = _getFileName(folder);
    if(_file == null) {
        _file = io.File(fileName);
        _sink = _file.openWrite(mode: FileMode.append);
      }
      _sink.writeln(log);
  }

  bool _isToDay(){
    var now = DateTime.now();
    return now.year==_recent.year && now.month == _recent.month && now.day == _recent.day;
  }

}