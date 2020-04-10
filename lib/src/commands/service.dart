import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

import '../base/file_system.dart';
import '../base/process.dart' as pmain;
import '../runner/mpcli_command.dart';
import '../base/utils.dart';
import '../version.dart';
import '../../utils/util.dart';
import '../base/os.dart';

class ServiceCommand extends MpcliCommand {
  static const timeout = 30;

  @override
  final String name = 'service';

  @override
  final String description = 'Start Workflow Web Service.';
  final domain = '127.0.0.1:8080';

  @override
  Future<MpcliCommandResult> runCommand() async {
    var response = await http
        .get('http://$domain/api/status')
        .catchError((_) => print('no server running'));
    if (response != null && response.statusCode == HttpStatus.ok) {
      print(response.body);
      print('server is already running...');
      return MpcliCommandResult(ExitStatus.success);
    }

    String entry = await serverEntryPoint();
    if (entry == null || entry.isEmpty) {
      return MpcliCommandResult(ExitStatus.fail);
    }
    Completer f = Completer<bool>();
    String workflowPath = null;
    try {
      workflowPath =
          fs.file(fs.path.join(homeResourcePath(), 'wpath')).readAsStringSync();
    } catch (e) {
      // ignored
      print('No workflow path file, exist code: $e');
      return const MpcliCommandResult(ExitStatus.fail);
    }
    final Process process = await pmain.runCommand(
      <String>['dart', entry, '-w', workflowPath],
      allowReentrantFlutter: true,
    );
    process.exitCode.then((exitCode) {
      print('server terminated, exist code: $exitCode');
    });
    StreamSubscription stdoutSubscription;
    Future.delayed(Duration(seconds: timeout), () {
      f?.complete(false);
      f = null;
      stdoutSubscription?.cancel();
    });
    stdoutSubscription = process.stdout.transform(utf8.decoder).listen((data) {
      if (data.contains('Serving on http')) {
        print(data);
        f?.complete(true);
        f = null;
      }
    });

    final StreamSubscription<String> stderrSubscription = process.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
      if (line != null) print(line);
    });

    var success = await f.future;
    if (success) {
      await os.launchWeb('http://$domain/index.html#/');
      var socket = await WebSocket.connect('ws://$domain/api/log/read_connect');
      socket.listen((event) {
        print("$event");
      });

      final FlutterVersion flutterVersion = FlutterVersion();
      final Map<String, String> jsonData = <String, String>{};
      jsonData['flutterSdkVersion'] = flutterVersion.frameworkVersion;
      jsonData['wbsdkVersion'] = cliVersion;
      jsonData['dartkVersion'] = flutterVersion.dartSdkVersion;
      jsonData['enginekVersion'] = flutterVersion.engineRevision;
      // 替换为开源地址
      jsonData['wbsdkDownloadUrl'] = 'https://github.com/wuba/magpie';
      jsonData['wbsdk_docUrl'] = 'https://github.com/wuba/magpie/blob/master/README.md';
      const JsonEncoder jsonEncoder = JsonEncoder.withIndent('  ');
      await http
          .get('http://$domain/api/baseinfo/sdk?data=' +
              jsonEncoder.convert(jsonData))
          .catchError((_) => print('post base info error.'));
    }

    // Wait for stdout to be fully processed
    // because process.exitCode may complete first causing flaky tests.
    await waitGroup<void>(<Future<void>>[
      stdoutSubscription.asFuture<void>(),
      stderrSubscription.asFuture<void>(),
    ]);

    await waitGroup<void>(<Future<void>>[
      stdoutSubscription.cancel(),
      stderrSubscription.cancel(),
    ]);

    return MpcliCommandResult(success ? ExitStatus.success : ExitStatus.fail);
  }

  /// workspace => ~/.mgpcli/server
  /// resources => bin/server.tar.gz
  /// entry point => $workspace/bin/www.dart
  Future<String> serverEntryPoint() async {
    final String fileRoot = userRootPath();
    final Directory destResourceDir = fs.directory(homeResourcePath());
    if (!destResourceDir.existsSync()) {
      destResourceDir.createSync();
    }
    print("fileRoot at $fileRoot");
    final workspace = fs.path.join(destResourceDir.path, 'server');
    final String webServerPath = fs.path.join(workspace, 'bin', 'www.dart');
    final String timestampPath =
        fs.path.join(workspace, 'bin', 'server.timestamp');
    print("try to launch server at $webServerPath");
    if (!fs.file(webServerPath).existsSync() ||
        await checkServeShouldRefresh(timestampPath)) {
      print('exatract resources ...');
      var tarGz = fs.path.join(fileRoot, 'bin', 'server.tar.gz');
      if (!fs.file(tarGz).existsSync()) {
        print('server.tar.gz not exsist, terminate...');
        return null;
      }
      // 注意不要删除wpath
      deleteFile(fs.directory(workspace));
      extractTarGzip(tarGz, destResourceDir.path);
      await writeTimestampFile(timestampPath);
    }
    var gen = fs.path.join(workspace, '.packages');
    if (!fs.file(gen).existsSync()) {
      var pubPath = os.which('pub').path;
      print("pub pubPath $pubPath");
      print("wait a moment please...");
      var output =
          pmain.runCheckedSync([pubPath, 'get'], workingDirectory: workspace);
      print(output);
    }
    return webServerPath;
  }

  void extractTarGzip(String path, String des) {
    var bytes = fs
        .file(
          path,
        )
        .readAsBytesSync();
    var gz = GZipDecoder().decodeBytes(bytes);
    var archive = TarDecoder().decodeBytes(gz);
    for (ArchiveFile file in archive) {
      String filename = file.name;
      if (file.isFile) {
        List<int> data = file.content;
        fs.file(fs.path.join(des, filename))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        fs.directory(fs.path.join(des, filename))..create(recursive: true);
      }
    }
  }
}
