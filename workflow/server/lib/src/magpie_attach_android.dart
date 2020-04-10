
import 'dart:async';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'tools/base/common.dart';
import 'tools/base/file_system.dart';
import 'tools/base/io.dart';
import 'tools/base/utils.dart';
import 'tools/convert.dart';

//import 'src/tools/base/io.dart';

final StreamController<String> _stdout = StreamController<String>.broadcast();
final StreamController<String> _stderr = StreamController<String>.broadcast();
final StreamController<String> _allMessages = StreamController<String>.broadcast();


final DateTime startTime = DateTime.now();
String lastTime = '';
const bool _printDebugOutputToStdOut = true;
String _logPrefix = 'ATTACH  ';
bool _hasExited = false;
final StringBuffer _errorBuffer = StringBuffer();
Process _process;
int _processPid;
Uri _vmServiceWsUri;

Future<Isolate> resume({ bool waitForNextPause = false }) => _resume(null, waitForNextPause);
const Duration defaultTimeout = Duration(seconds: 5);
const Duration appStartTimeout = Duration(seconds: 120);
const Duration quitTimeout = Duration(seconds: 10);
String _lastResponse;
String _currentRunningAppId;
VmService _vmService;
String _flutterIsolateId;
String get defaultMainPath => fs.path.join('lib', 'main.dart');

Future<void> magpieAttachAndroid(List<String> args) async {

  ArgParser argParser = ArgParser();
  argParser.addOption('flutter-root',
      abbr: 'f', defaultsTo: null, help: 'local flutter install path');

//  argParser.addOption('target-path',
//      abbr: 't', defaultsTo: null, help: 'local flutter project path');
//
  argParser.addOption('project-root',
    abbr: 'p', hide: true, help: 'Normally used only in run target',
  );

  argParser.addOption('target',
      abbr: 't',
      defaultsTo: defaultMainPath,
      help: 'The main entry-point file of the application, as run on the device.\n'
          'If the --target option is omitted, but a file name is provided on '
          'the command line, then that is used instead.',
      valueHelp: 'path');

  var argResults = argParser.parse(args);
  final String flutterRoot = argResults['flutter-root'];
  final String flutterBin = fs.path.join(flutterRoot, 'bin', 'flutter');

  String projectRoot = argResults['project-root'];
  print('project-root:$projectRoot');
  if(projectRoot == null) {
    print('Error: Please use -p to locate the flutter project-root');
    return Future.value(-1);
  }


  //int port = 12345;
  //await _run(targetPath,flutterBin);
  await _attach(projectRoot,flutterBin);
  //await _restart();
  //await attach1(flutterRoot,targetPath);
}

Future<void> _run(
    String targetPath,
    String  flutterBin,
    {
      bool withDebugger = false,
      bool startPaused = false,
      bool pauseOnExceptions = false,
      File pidFile,
    }) async {

  List<String> arguments = <String>[
    '${flutterBin}',
    'run',
//    '--disable-service-auth-codes',
//    '--machine',
//    '-d',
//    'flutter-tester',
  ].toList();

  await _readySetupProcess(
    targetPath,
    arguments,
    withDebugger: withDebugger,
    startPaused: startPaused,
    pauseOnExceptions: pauseOnExceptions,
    pidFile: pidFile,
  );
}

Future<void> _attach(
    String projectRoot,
    String flutterBin,
    //int port,s
        {
      bool withDebugger = false,
      bool startPaused = false,
      bool pauseOnExceptions = false,
      File pidFile,
    }) async {

  List<String> arguments = <String>[
    '${flutterBin}',
    'attach',
//    '--project-root',
//    '$projectRoot',
//    '--target',
//    '$projectRoot/$defaultMainPath',
//    '--machine',
//    '-d',
//    'flutter-tester',
//    '--debug-port',
//    '$port',
  ].toList();

  await _readySetupProcess(
    projectRoot,
    arguments,
    withDebugger: withDebugger,
    startPaused: startPaused,
    pauseOnExceptions: pauseOnExceptions,
    pidFile: pidFile,
  );
}


@override
Future<void> _readySetupProcess(
    String projectRoot,
    List<String> arguments,
    {
      String script,
      bool withDebugger = false,
      bool startPaused = false,
      bool pauseOnExceptions = false,
      File pidFile,
    }) async {

  assert(!startPaused || withDebugger);
  await _setupProcess(
    projectRoot,
    arguments,
    script: script,
    withDebugger: withDebugger,
    pidFile: pidFile,
  );

  final Completer<void> prematureExitGuard = Completer<void>();

  // If the process exits before all of the `await`s below are done, then it
  // exited prematurely. This causes the currently suspended `await` to
  // deadlock until the test times out. Instead, this causes the test to fail
  // fast.
  unawaited(_process.exitCode.then((_) {
    if (!prematureExitGuard.isCompleted) {
      prematureExitGuard.completeError('Process existed prematurely: ${arguments.join(' ')}');
    }
  }));

  unawaited(() async {
    try {
      // Stash the PID so that we can terminate the VM more reliably than using
      // _process.kill() (`flutter` is a shell script so _process itself is a
      // shell, not the flutter tool's Dart process).
      final Map<String, dynamic> connected = await _waitFor(event: 'daemon.connected');
      _processPid = connected['params']['pid'] as int;

      // Set this up now, but we don't wait it yet. We want to make sure we don't
      // miss it while waiting for debugPort below.
      final Future<Map<String, dynamic>> started = _waitFor(event: 'app.started', timeout: appStartTimeout);

      if (withDebugger) {
        final Map<String, dynamic> debugPort = await _waitFor(event: 'app.debugPort', timeout: appStartTimeout);
        final String wsUriString = debugPort['params']['wsUri'] as String;
        _vmServiceWsUri = Uri.parse(wsUriString);
        await connectToVmService(pauseOnExceptions: pauseOnExceptions);
        if (!startPaused) {
          await resume(waitForNextPause: false);
        }
      }

      // Now await the started event; if it had already happened the future will
      // have already completed.
      _currentRunningAppId = (await started)['params']['appId'] as String;
      prematureExitGuard.complete();
    } catch(error, stackTrace) {
      prematureExitGuard.completeError(error, stackTrace);
    }
  }());

  return prematureExitGuard.future;
}

Future<void> _setupProcess(String projectRoot,List<String> arguments, {
  String script,
  bool withDebugger = false,
  bool pauseOnExceptions = false,
  bool startPaused = false,
  File pidFile,
}) async {
  const ProcessManager _processManager = LocalProcessManager();
  Directory tempDir = createResolvedTempDirectorySync('attach_test.');
  print('Spawning flutter $arguments in ${tempDir.path}');

  if (withDebugger) {
    arguments.add('--start-paused');
  }
  arguments.add('--verbose');

  if(pidFile == null) {
    pidFile = tempDir.childFile('test.pid');
  }

  if (pidFile != null) {
    arguments.addAll(<String>['--pid-file', pidFile.path]);
  }
  if (script != null) {
    arguments.add(script);
  }

  _process = await _processManager.start(
    arguments,
    //workingDirectory: tempDir.path,
    workingDirectory: projectRoot,
    environment: <String, String>{'FLUTTER_TEST': 'true'},
  );

  // This class doesn't use the result of the future. It's made available
  // via a getter for external uses.
  unawaited(_process.exitCode.then((int code) {
    _debugPrint('Process exited ($code)');
    if(code == 0) {
      print("attach success");
    }
    _hasExited = true;
  }));
  transformToLines(_process.stdout).listen((String line) => _stdout.add(line));
  transformToLines(_process.stderr).listen((String line) => _stderr.add(line));

  // Capture stderr to a buffer so we can show it all if any requests fail.
  _stderr.stream.listen(_errorBuffer.writeln);

  // This is just debug printing to aid running/debugging tests locally.
  _stdout.stream.listen((String message) => _debugPrint(message, topic: '<=stdout='));
  _stderr.stream.listen((String message) => _debugPrint(message, topic: '<=stderr='));

}

Future<void> _restart({ bool fullRestart = false, bool pause = false }) async {
  print('开始 _restart...');
  if (_currentRunningAppId == null) {
    throw Exception('App has not started yet');
  }

  _debugPrint('Performing ${ pause ? "paused " : "" }${ fullRestart ? "hot restart" : "hot reload" }...');
  final dynamic hotReloadResponse = await _sendRequest(
    'app.restart',
    <String, dynamic>{'appId': _currentRunningAppId, 'fullRestart': fullRestart, 'pause': pause},
  );
  _debugPrint('${ fullRestart ? "Hot restart" : "Hot reload" } complete.');

  if (hotReloadResponse == null || hotReloadResponse['code'] != 0) {
    _throwErrorResponse('Hot ${fullRestart ? 'restart' : 'reload'} request failed');
  }
}

int id = 1;
Future<dynamic> _sendRequest(String method, dynamic params) async {
  final int requestId = id++;
  final Map<String, dynamic> request = <String, dynamic>{
    'id': requestId,
    'method': method,
    'params': params,
  };
  final String jsonEncoded = json.encode(<Map<String, dynamic>>[request]);
  _debugPrint(jsonEncoded, topic: '=stdin=>');

  // Set up the response future before we send the request to avoid any
  // races. If the method we're calling is app.stop then we tell _waitFor not
  // to throw if it sees an app.stop event before the response to this request.
  final Future<Map<String, dynamic>> responseFuture = _waitFor(
    id: requestId,
    ignoreAppStopEvent: method == 'app.stop',
  );
  _process.stdin.writeln(jsonEncoded);
  final Map<String, dynamic> response = await responseFuture;

  if (response['error'] != null || response['result'] == null) {
    _throwErrorResponse('Unexpected error response');
  }

  return response['result'];
}

void _throwErrorResponse(String message) {
  throw '$message\n\n$_lastResponse\n\n${_errorBuffer.toString()}'.trim();
}

Future<Isolate> _resume(String step, bool waitForNextPause) async {
  assert(waitForNextPause != null);
  await _timeoutWithMessages<dynamic>(
        () async => _vmService.resume(await _getFlutterIsolateId(), step: step),
    task: 'Resuming isolate (step=$step)',
  );
  return waitForNextPause ? waitForPause() : null;
}

Future<String> _getFlutterIsolateId() async {
  // Currently these tests only have a single isolate. If this
  // ceases to be the case, this code will need changing.
  if (_flutterIsolateId == null) {
    final VM vm = await _vmService.getVM();
    _flutterIsolateId = vm.isolates.first.id;
  }
  return _flutterIsolateId;
}

Future<Isolate> _getFlutterIsolate() async {
  final Isolate isolate = await _vmService.getIsolate(await _getFlutterIsolateId()) as Isolate;
  return isolate;
}

// This method isn't racy. If the isolate is already paused,
// it will immediately return.
Future<Isolate> waitForPause() async {
  return _timeoutWithMessages<Isolate>(
        () async {
      final String flutterIsolate = await _getFlutterIsolateId();
      final Completer<Event> pauseEvent = Completer<Event>();

      // Start listening for pause events.
      final StreamSubscription<Event> pauseSubscription = _vmService.onDebugEvent
          .where((Event event) {
        return event.isolate.id == flutterIsolate
            && event.kind.startsWith('Pause');
      })
          .listen((Event event) {
        if (!pauseEvent.isCompleted) {
          pauseEvent.complete(event);
        }
      });

      // But also check if the isolate was already paused (only after we've set
      // up the subscription) to avoid races. If it was paused, we don't need to wait
      // for the event.
      final Isolate isolate = await _vmService.getIsolate(flutterIsolate) as Isolate;
      if (isolate.pauseEvent.kind.startsWith('Pause')) {
        _debugPrint('Isolate was already paused (${isolate.pauseEvent.kind}).');
      } else {
        _debugPrint('Isolate is not already paused, waiting for event to arrive...');
        await pauseEvent.future;
      }

      // Cancel the subscription on either of the above.
      await pauseSubscription.cancel();

      return _getFlutterIsolate();
    },
    task: 'Waiting for isolate to pause',
  );
}


Future<Map<String, dynamic>> _waitFor({
  String event,
  int id,
  Duration timeout = defaultTimeout,
  bool ignoreAppStopEvent = false,
}) async {
  assert(timeout != null);
  assert(event != null || id != null);
  assert(event == null || id == null);
  final String interestingOccurrence = event != null ? '$event event' : 'response to request $id';
  final Completer<Map<String, dynamic>> response = Completer<Map<String, dynamic>>();
  StreamSubscription<String> subscription;
  subscription = _stdout.stream.listen((String line) async {
    final Map<String, dynamic> json = parseFlutterResponse(line);
    _lastResponse = line;
    if (json == null) {
      return;
    }
    if ((event != null && json['event'] == event) ||
        (id    != null && json['id']    == id)) {
      await subscription.cancel();
      _debugPrint('OK ($interestingOccurrence)');
      response.complete(json);
    } else if (!ignoreAppStopEvent && json['event'] == 'app.stop') {
      await subscription.cancel();
      final StringBuffer error = StringBuffer();
      error.write('Received app.stop event while waiting for $interestingOccurrence\n\n');
      if (json['params'] != null && json['params']['error'] != null) {
        error.write('${json['params']['error']}\n\n');
      }
      if (json['params'] != null && json['params']['trace'] != null) {
        error.write('${json['params']['trace']}\n\n');
      }
      response.completeError(error.toString());
    }
  });

  return _timeoutWithMessages(
        () => response.future,
    timeout: timeout,
    task: 'Expecting $interestingOccurrence',
  ).whenComplete(subscription.cancel);
}

Future<T> _timeoutWithMessages<T>(
    Future<T> Function() callback, {
      @required String task,
      Duration timeout = defaultTimeout,
    }) {
  assert(task != null);
  assert(timeout != null);

  if (_printDebugOutputToStdOut) {
    _debugPrint('$task...');
    return callback()..timeout(timeout, onTimeout: () {
      _debugPrint('$task is taking longer than usual...');
      return null;
    });
  }

  // We're not showing all output to the screen, so let's capture the output
  // that we would have printed if we were, and output it if we take longer
  // than the timeout or if we get an error.
  final StringBuffer messages = StringBuffer('$task\n');
  final DateTime start = DateTime.now();
  bool timeoutExpired = false;
  void logMessage(String logLine) {
    final int ms = DateTime.now().difference(start).inMilliseconds;
    final String formattedLine = '[+ ${ms.toString().padLeft(5)}] $logLine';
    messages.writeln(formattedLine);
  }
  final StreamSubscription<String> subscription = _allMessages.stream.listen(logMessage);

  final Future<T> future = callback();

  future.timeout(timeout ?? defaultTimeout, onTimeout: () {
    _debugPrint(messages.toString());
    timeoutExpired = true;
    _debugPrint('$task is taking longer than usual...');
    return null;
  });

  return future.catchError((dynamic error) {
    if (!timeoutExpired) {
      timeoutExpired = true;
      _debugPrint(messages.toString());
    }
    throw error;
  }).whenComplete(() => subscription.cancel());

}

Map<String, dynamic> parseFlutterResponse(String line) {
  if (line.startsWith('[') && line.endsWith(']')) {
    try {
      final Map<String, dynamic> response = castStringKeyedMap(json.decode(line)[0]);
      return response;
    } catch (e) {
      // Not valid JSON, so likely some other output that was surrounded by [brackets]
      return null;
    }
  }
  return null;
}

Future<void> connectToVmService({ bool pauseOnExceptions = false }) async {
  _vmService = await vmServiceConnectUri('$_vmServiceWsUri');
  _vmService.onSend.listen((String s) => _debugPrint(s, topic: '=vm=>'));
  _vmService.onReceive.listen((String s) => _debugPrint(s, topic: '<=vm='));

  final Completer<void> isolateStarted = Completer<void>();
  _vmService.onIsolateEvent.listen((Event event) {
    if (event.kind == EventKind.kIsolateStart) {
      isolateStarted.complete();
    } else if (event.kind == EventKind.kIsolateExit && event.isolate.id == _flutterIsolateId) {
      // Hot restarts cause all the isolates to exit, so we need to refresh
      // our idea of what the Flutter isolate ID is.
      _flutterIsolateId = null;
    }
  });

  await Future.wait(<Future<Success>>[
    _vmService.streamListen('Isolate'),
    _vmService.streamListen('Debug'),
  ]);

  if ((await _vmService.getVM()).isolates.isEmpty) {
    await isolateStarted.future;
  }

  await waitForPause();
  if (pauseOnExceptions) {
    await _vmService.setExceptionPauseMode(
      await _getFlutterIsolateId(),
      ExceptionPauseMode.kUnhandled,
    );
  }
}



Directory createResolvedTempDirectorySync(String prefix) {
  assert(prefix.endsWith('.'));
  final Directory tempDirectory = fs.systemTempDirectory.createTempSync('flutter_$prefix');
  return fs.directory(tempDirectory.resolveSymbolicLinksSync());
}

void _debugPrint(String message, { String topic = '' }) {
  const int maxLength = 2500;
  final String truncatedMessage = message.length > maxLength ? message.substring(0, maxLength) + '...' : message;
  final String line = '${topic.padRight(10)} $truncatedMessage';
  _allMessages.add(line);
  final int timeInSeconds = DateTime.now().difference(startTime).inSeconds;
  String time = timeInSeconds.toString().padLeft(5) + 's ';
  if (time == lastTime) {
    time = ' ' * time.length;
  } else {
    lastTime = time;
  }
  if (_printDebugOutputToStdOut) {
    print('$time$_logPrefix$line');
  }
}


Stream<String> transformToLines(Stream<List<int>> byteStream) {
  return byteStream.transform<String>(utf8.decoder).transform<String>(const LineSplitter());
}




//Future<void> attach(String flutterRoot,String targetPath) async {
//  Directory projectDir = fs.directory(targetPath);
//  //FlutterProject project = FlutterProject.fromDirectory(projectDir);
//  final List<String> command = <String>[
//    fs.path.join('$flutterRoot', 'bin', 'flutter'),
//    'attach',
//  ];
//  final ProcessResult result = await processManager.run(command, workingDirectory: projectDir.path);
//  if (result.exitCode != 0) {
//    throw Exception('attach failed: ${result.stderr}\n${result.stdout}');
//  }
//}

//Future<void> attach1(String flutterRoot,String targetPath) async {
//  final Map<String, String> iosDeployEnv =
//  Map<String, String>.from(platform.environment);
//
//  final List<String> attachCommand = <String>[
//    '${flutterRoot}/bin/flutter',
//    'attach'
//  ];
//
//  int attachResult = await processUtils.stream(
//    attachCommand,
//    trace: true,
//    environment: iosDeployEnv,
//  );
//  if (attachResult == 0) {
//    print('设备连接成功');
//  } else {
//    print('设备连接失败');
//  }
//}

