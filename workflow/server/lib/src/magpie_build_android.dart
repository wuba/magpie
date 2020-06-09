import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';

import 'controller/log_controller.dart';
import 'tools/android/gradle_utils.dart';
import 'tools/base/common.dart';
import 'tools/base/file_system.dart';
import 'tools/base/platform.dart';
import 'tools/base/process.dart';
import 'tools/build_info.dart';
import 'tools/cache.dart';
import 'tools/flutter_manifest.dart';
import 'tools/globals.dart';
import 'tools/project.dart';

const String kFlutterRootEnvironmentVariableName = 'FLUTTER_ROOT'; // should point to //flutter/ (root of flutter/flutter repo)
const String kFlutterEngineEnvironmentVariableName = 'FLUTTER_ENGINE'; // should point to //engine/src/ (root of flutter/engine repo)
const String kSnapshotFileName = 'flutter_tools.snapshot'; // in //flutter/bin/cache/
const String kFlutterToolsScriptFileName = 'flutter_tools.dart'; // in //flutter/packages/flutter_tools/bin/
const String kFlutterEnginePackageName = 'sky_engine';


class FlutterOptions {

  static const String kExtraFrontEndOptions = 'extra-front-end-options';
  bool _usesPubOption = false;
  ArgParser _argParser = ArgParser();

  /// The parsed argument results for this command.
  ///
  /// This will be `null` until just before [Command.run] is called.
  ArgResults _argResults;

  FlutterOptions() {

  }

  void usesPubOption() {
    _argParser.addFlag('pub',
        defaultsTo: false,
        help: 'Whether to run "flutter pub get" before executing this command.');
    _usesPubOption = true;
  }

  void usesFlavorOption() {
    _argParser.addOption(
      'flavor',
      help: 'Build a custom app flavor as defined by platform-specific build setup.\n'
          'Supports the use of product flavors in Android Gradle scripts, and '
          'the use of custom Xcode schemes.',
    );
  }

  void useCommonOption() {
    _argParser
      ..addMultiOption('target-platform',
        splitCommas: true,
        defaultsTo: <String>['android-arm', 'android-arm64'],
        allowed: <String>['android-arm', 'android-arm64', 'android-x86', 'android-x64'],
        help: 'The target platform for which the project is compiled.',
      )
      ..addOption('output-dir',
        help: 'The absolute path to the directory where the repository is generated.'
            'By default, this is \'<current-directory>android/build\'. ',
      )
      ..addOption('target-path',
          abbr: 't',
          defaultsTo: null,
          help: 'local flutter project path');

    _argParser
        .addOption('flutter-root',abbr:'f',defaultsTo: null,
        help:'local flutter install path');

    _argParser
        .addOption('build-mode',abbr:'b',defaultsTo: 'debug',
        help:'Build a build debug/profile/release version of the current project');

  }

  bool boolArg(String name) => _argResults[name] as bool;
  /// Gets the parsed command-line option named [name] as `List<String>`.
  List<String> stringsArg(String name) => _argResults[name] as List<String>;
  /// Gets the parsed command-line option named [name] as `String`.
  String stringArg(String name) => _argResults[name] as String;
}

/**
 * 构建入口方法
 * magpieBuildAndroid
 */
Future<int> magpieBuildAndroid(List<String> args) async {
  FlutterOptions flutterOptions = FlutterOptions();

  flutterOptions.usesFlavorOption();
  flutterOptions.usesPubOption();
  flutterOptions.useCommonOption();
  //flutterOptions.addBuildModeFlags();

  var argResults = flutterOptions._argParser.parse(args);
  flutterOptions._argResults = argResults;


  print(args);

  final Iterable<AndroidArch> targetArchitectures = flutterOptions.stringsArg('target-platform')
      .map<AndroidArch>(getAndroidArchForName);
  /**
   * 设置构建模式
   */
  final Set<AndroidBuildInfo> androidBuildInfo = <AndroidBuildInfo>{};
  String buildMode = argResults["build-mode"];
  if (buildMode != null) {
    androidBuildInfo.add(
        AndroidBuildInfo(
          //BuildInfo(BuildMode.fromName(buildMode), flutterOptions.stringArg('flavor')),
          BuildInfo(BuildMode.fromName(buildMode), null),
          targetArchs: targetArchitectures,
        )
    );
  }

  if (androidBuildInfo.isEmpty) {
    throwToolExit('Please specify a build mode and try again.');
  }

  // We must set Cache.flutterRoot early because other features use it (e.g.
  // enginePath's initializer uses it).
  //final String flutterRoot = argResults['flutter-root'] as String ?? FlutterOptions.defaultFlutterRoot;
  final String flutterRoot = argResults['flutter-root'];
  Cache.flutterRoot = fs.path.normalize(fs.path.absolute(flutterRoot));
  print('flutterRoot:$flutterRoot');
  if(Cache.flutterRoot == null) {
    print('Error: Please use -f to locate the flutter install path');
    return Future.value(-1);
  }

  String targetPath = flutterOptions.stringArg('target-path');
  print('targetPath:$targetPath');
  Directory projectDir = null;
  FlutterProject project = null;
  if(targetPath == null) {
    project = FlutterProject.current();
    targetPath = fs.currentDirectory.path;
    projectDir = fs.directory(targetPath);
  } else {
    projectDir = fs.directory(targetPath);
    project = FlutterProject.fromDirectory(projectDir);
  }

  if (projectDir.existsSync()) {
//    print('目录: ' + projectDir.path + " 权限修改");
    //os.chmod(projectDir, '777');
  }

  //pub get
  //if(flutterOptions.boolArg('pub')) {
    await pubGet(flutterRoot, targetPath);
  //}

  //删除旧文件
  await cleanCommand(project);

  String outputDirectoryPath = flutterOptions.stringArg('output-dir');
  Directory outputDirectory =
  fs.directory(outputDirectoryPath ?? project.android.buildDirectory);
  if (project.isModule) {
    // Module projects artifacts are located in `build/host`.
    outputDirectory = outputDirectory.childDirectory('host');
  }

  try {
    logToClient("INFO", '开始构建...', DateTime.now());
    for (AndroidBuildInfo androidBuildInfo in androidBuildInfo) {
      await buildGradleAar(
          project:project,
          androidBuildInfo:androidBuildInfo,
          target:'',
          outputDirectory:outputDirectory);
    }
    logToClient("INFO", '构建完成...', DateTime.now());
    if(outputDirectoryPath == null) {
      outputDirectoryPath = fs.directory(targetPath).childDirectory('build').childDirectory('host').path;
    }
    await openBuildFolder(outputDirectoryPath,platform.environment,targetPath);
    return Future.value(1);
  } catch (e) {
    logToClient("ERROR", e.toString(), DateTime.now());
  } finally {
    //androidSdk.reinitialize();
  }
  return Future.value(0);
}

//Flutter pub get
void pubGet(String flutterRoot, String targetPath) async {

  Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': flutterRoot,
  };

  print('pub get开始...');
  final List<String> pubGetCommand = <String>[
    fs.directory(flutterRoot).childDirectory('bin').childFile('flutter').path,
    'pub',
    'get'
  ];

  int result = await processUtils.stream(
    pubGetCommand,
    trace: true,
    environment: environment,
    workingDirectory: targetPath,
  );
  if (result == 0) {
    print('pub get 成功');
  } else {
    logToClient("ERROR", "pub get 执行失败", DateTime.now());
  }
}


void openBuildFolder(
    String productPath, Map<String, String> androidDeployEnv, targetPath) async {

  final List<String> openProductCommand = <String>['open', '${productPath}'];
  int openResult = await processUtils.stream(
    openProductCommand,
    trace: true,
    environment: androidDeployEnv,
    workingDirectory: targetPath,
  );
  if (openResult == 0) {
    print('打开输出目录');
  } else {
    logToClient("ERROR", "打开输出目录失败", DateTime.now());
  }
}

Future<int> cleanCommand(FlutterProject flutterProject) async {

  final Directory buildDir = fs.directory(getBuildDirectory());
  deleteFile(buildDir);

  deleteFile(flutterProject.dartTool);

//  final Directory androidEphemeralDirectory = flutterProject.android.ephemeralDirectory;
//  deleteFile(androidEphemeralDirectory);

//  final Directory windowsEphemeralDirectory = flutterProject.windows.ephemeralDirectory;
//  deleteFile(windowsEphemeralDirectory);

  return Future.value(1);
}



/// Builds AAR and POM files.
///
/// * [project] is typically [FlutterProject.current()].
/// * [androidBuildInfo] is the build configuration.
/// * [outputDir] is the destination of the artifacts,
Future<RunResult> buildGradleAar({
  @required FlutterProject project,
  @required AndroidBuildInfo androidBuildInfo,
  @required String target,
  @required Directory outputDirectory,
}) async {
  assert(project != null);
  assert(target != null);
  assert(androidBuildInfo != null);
  assert(outputDirectory != null);

//  if (androidSdk == null) {
//    exitWithNoSdkMessage();
//  }

  final FlutterManifest manifest = project.manifest;
  if (!manifest.isModule && !manifest.isPlugin) {
    throwToolExit('AARs can only be built for plugin or module projects.');
  }

  final String aarTask = getAarTaskFor(androidBuildInfo.buildInfo);
//  final Status status = logger.startProgress(
//    'Running Gradle task \'$aarTask\'...',
//    timeout: timeoutConfiguration.slowOperation,
//    multilineOutput: true,
//  );

  final String flutterRoot = fs.path.absolute(Cache.flutterRoot);
  final String initScript = fs.path.join(
    flutterRoot,
    'packages',
    'flutter_tools',
    'gradle',
    'aar_init_script.gradle',
  );
  final List<String> command = <String>[
    GradleUtils().getExecutable(project),
    '-I=$initScript',
    '-Pflutter-root=$flutterRoot',
    '-Poutput-dir=${outputDirectory.path}',
    '-Pis-plugin=${manifest.isPlugin}',
  ];

  if (target != null && target.isNotEmpty) {
    command.add('-Ptarget=$target');
  }

  if (androidBuildInfo.targetArchs.isNotEmpty) {
    final String targetPlatforms = androidBuildInfo.targetArchs
        .map(getPlatformNameForAndroidArch).join(',');
    command.add('-Ptarget-platform=$targetPlatforms');
  }

  command.add(aarTask);

  RunResult result;
  try {
    result = await processUtils.run(
      command,
      workingDirectory: project.android.hostAppGradleRoot.path,
      allowReentrantFlutter: true,
      environment: gradleEnvironment,
    );
  } finally {
    //status.stop();
  }
  //flutterUsage.sendTiming('build', 'gradle-aar', sw.elapsed);

  if (result.exitCode != 0) {
    //printStatus(result.stdout, wrap: false);
    //printError(result.stderr, wrap: false);
    throwToolExit(
      'Gradle task $aarTask failed with exit code $exitCode.',
      exitCode: exitCode,
    );
  }
  final Directory repoDirectory = getRepoDirectory(outputDirectory);
  if (!repoDirectory.existsSync()) {
    //printStatus(result.stdout, wrap: false);
    //printError(result.stderr, wrap: false);
    throwToolExit(
      'Gradle task $aarTask failed to produce $repoDirectory.',
      exitCode: exitCode,
    );
  }
//  printStatus(
//    '$successMark Built ${fs.path.relative(repoDirectory.path)}.',
//    color: TerminalColor.green,
//  );
}


String getAarTaskFor(BuildInfo buildInfo) {
  return _taskFor('assembleAar', buildInfo);
}

String _taskFor(String prefix, BuildInfo buildInfo) {
  final String buildType = camelCase(buildInfo.modeName);
  final String productFlavor = buildInfo.flavor ?? '';
  return '$prefix${toTitleCase(productFlavor)}${toTitleCase(buildType)}';
}

/// Convert `foo_bar` to `fooBar`.
String camelCase(String str) {
  int index = str.indexOf('_');
  while (index != -1 && index < str.length - 2) {
    str = str.substring(0, index) +
        str.substring(index + 1, index + 2).toUpperCase() +
        str.substring(index + 2);
    index = str.indexOf('_');
  }
  return str;
}

String toTitleCase(String str) {
  if (str.isEmpty) {
    return str;
  }
  return str.substring(0, 1).toUpperCase() + str.substring(1);
}

/// The directory where the repo is generated.
/// Only applicable to AARs.
Directory getRepoDirectory(Directory buildDirectory) {
  return buildDirectory
      .childDirectory('outputs')
      .childDirectory('repo');
}

void deleteFile(FileSystemEntity file) {
  // This will throw a FileSystemException if the directory is missing permissions.
  try {
    if (file == null || !file.existsSync()) {
      return;
    }
  } on FileSystemException catch (err) {
    printError('Cannot clean ${file.path}.\n$err');
    return;
  }
  try {
    file.deleteSync(recursive: true);
  } on FileSystemException catch (error) {
    final String path = file.path;
    if (platform.isWindows) {
      printError(
          'Failed to remove $path. '
              'A program may still be using a file in the directory or the directory itself. '
              'To find and stop such a program, see: '
              'https://superuser.com/questions/1333118/cant-delete-empty-folder-because-it-is-used');
    } else {
      printError('Failed to remove $path: $error');
    }
  }
}







