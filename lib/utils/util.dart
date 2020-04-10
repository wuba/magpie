import '../src/android/android_sdk.dart';
import '../src/base/file_system.dart';
import '../src/base/logger.dart';
import '../src/base/platform.dart';
import '../src/base/process.dart';
import '../src/base/utils.dart';
import '../src/cache.dart';
import '../src/globals.dart';
import 'generated_config.dart';

final String cliVersion = VERSION_NAME;

enum CliEnvironment { debug, release }

CliEnvironment cliEnvironment() {
  return RELEASE == 1 ? CliEnvironment.release : CliEnvironment.debug;
}

Future<void> writeContent2Path(
    String path, String fileName, String content) async {
  var file = fs.file('$path/$fileName');

  var sink = file.openWrite();
  sink.write(content);
  await sink.flush();
  await sink.close();
  return Future.value();
}

void writeLocalProperties(File properties) {
  final SettingsFile settings = SettingsFile();
  if (androidSdk != null) {
    settings.values['sdk.dir'] = escapePath(androidSdk.directory);
    settings.values['flutter.sdk'] = escapePath(Cache.flutterRoot);
  }

  settings.writeContents(properties);
}

void cliUnzip(File file, String targetPath) {
  runSync(<String>['unzip', '-o', '-q', file.path, '-d', targetPath]);
}

/*
* cli打印信息
* logString
* */
void cliPrint(String logString) {
  cliPrints(logString, true);
}

/*
* cli打印信息
* logString
* isReleasePrint release版本是否打印信息
* */
void cliPrints(String logString, bool isReleasePrint) {
  if (cliEnvironment() == CliEnvironment.debug) {
    print(logString);
  } else {
    if (isReleasePrint) {
      printStatus(logString);
    }
  }
}

/*
* 模板工程默认字段替换
*
* */
void replaceFilesText(File file, String replaceValue, String newValue) async {
  if (!file.existsSync()) {
    return;
  }

  String fileContent = file.readAsStringSync();
  if (fileContent.contains(replaceValue)) {
    fileContent = fileContent.replaceAll(replaceValue, newValue);
    file = await file.writeAsString(fileContent);
  }
}

void deleteFile(FileSystemEntity file) {
  // This will throw a FileSystemException if the directory is missing permissions.
  try {
    if (!file.existsSync()) {
      return;
    }
  } on FileSystemException catch (err) {
    printError('Cannot clean ${file.path}.\n$err');
    return;
  }
  final Status deletionStatus = logger.startProgress(
      'Deleting ${file.basename}...',
      timeout: timeoutConfiguration.fastOperation);
  try {
    file.deleteSync(recursive: true);
  } on FileSystemException catch (error) {
    final String path = file.path;
    if (platform.isWindows) {
      printError('Failed to remove $path. '
          'A program may still be using a file in the directory or the directory itself. '
          'To find and stop such a program, see: '
          'https://superuser.com/questions/1333118/cant-delete-empty-folder-because-it-is-used');
    } else {
      printError('Failed to remove $path: $error');
    }
  } finally {
    deletionStatus.stop();
  }
}

/*
* 检查serve.tar.gz是否需要解压
* */
bool checkServeShouldRefresh(String timestampPath) {
  String servePath = fs.path.join(userRootPath(), 'bin', 'server.tar.gz');
  File timestampFile = fs.file(timestampPath);
  DateTime time = fs.file(servePath).lastModifiedSync();
  String serveTimeValue = time.millisecondsSinceEpoch.toString();
  if (!timestampFile.existsSync()) {
    return true;
  } else {
    String timestampContent = timestampFile.readAsStringSync();
    if (int.parse(serveTimeValue) > int.parse(timestampContent)) {
      return true;
    }
  }
  return false;
}

/*
* 写入时间戳文件
* */
Future writeTimestampFile(String timestampPath) async {
  String servePath = fs.path.join(userRootPath(), 'bin', 'server.tar.gz');
  File timestampFile = fs.file(timestampPath);
  if (!timestampFile.existsSync()) {
    timestampFile.createSync(recursive: true);
  }
  DateTime time = fs.file(servePath).lastModifiedSync();
  String serveTimeValue = time.millisecondsSinceEpoch.toString();
  timestampFile = await timestampFile.writeAsString(serveTimeValue);
}
