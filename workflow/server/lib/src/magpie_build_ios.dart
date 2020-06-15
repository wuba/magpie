import 'dart:io';

import 'package:args/args.dart';

import 'magpie_plugin.dart';
import 'magpie_plugin_ios.dart';
import 'magpie_utils.dart';
import 'model.dart';
import 'tools/base/file_system.dart';
import 'tools/base/platform.dart';
import 'tools/base/process.dart';
import 'tools/macos/xcode.dart';

/*
 * Des: Build App.framework Release Version
 * Args:
    -t :  help: 'local dart project path' defaultsTo: '.'
    -f :  help: 'flutter path'
 * Example:
    "-f",
    "/Users/sac/flutter",
    "-t",
    "/Users/sac/magpie/example",
 */
Future<int> magpieBuildIOS(List<String> args) async {
  ArgResults argResults = await parseArgs(args);
  String flutterRoot = argResults['flutterroot'];
  String targetPath = argResults['targetPath'];
  if (targetPath == null) {
    targetPath = '.';
  }
  if (flutterRoot == null) {
    print('Error: Please use -f to locate the flutter install path');
    return Future.value(-1);
  }

  String buildMode = "release";
  String archArm = 'arm64,armv7';
  pathHelper.configWithData(targetPath, buildMode);
  String buildPath = pathHelper.buildPath;
  String productPath = pathHelper.productPath;
  String productAppPath = pathHelper.productAppPath;
  String targetFile = pathHelper.targetFile;

  final Map<String, String> iosDeployEnv =
      Map<String, String>.from(platform.environment);
  iosDeployEnv['BUILD_MODE'] = buildMode; //debug/release编译模式
  iosDeployEnv['FLUTTER_ROOT'] = flutterRoot; //编译的cpu平台
  iosDeployEnv['ARCHS_ARM'] = archArm;
  iosDeployEnv['BUILD_PATH'] = buildPath;
  iosDeployEnv['PRODUCT_PATH'] = productPath;
  iosDeployEnv['PRODUCT_APP_PATH'] = productAppPath;

  await pubGet(flutterRoot, iosDeployEnv, targetPath);
  await clean(flutterRoot, iosDeployEnv, targetPath);
  await cleanFolder(buildPath, iosDeployEnv, targetPath);
  await updatePackage(flutterRoot, iosDeployEnv, targetPath);

  //创建目录
  int mkdirResult = await processUtils.stream(
    ['mkdir', '-p', '--', "${productPath}"],
    trace: true,
    environment: iosDeployEnv,
    workingDirectory: targetPath,
  );
  if (mkdirResult == 0) {
    print('创建目录成功');
  }

  print('正在打包App.framework');
  final List<String> framworkBuildCommand = <String>[
    '${flutterRoot}/bin/flutter',
    '--suppress-analytics',
    '--verbose',
    'build',
    'aot',
    '--output-dir=${buildPath}',
    '--target-platform=ios',
    '--target=${targetFile}',
    '--${buildMode}',
    '--ios-arch=${archArm}'
  ];
  int framworkBuildResult = await processUtils.stream(
    framworkBuildCommand,
    trace: true,
    environment: iosDeployEnv,
    workingDirectory: targetPath,
  );
  if (framworkBuildResult == 0) {
    print('App.framework 成功打出');
  } else {
    print('App.framework 打包错误');
    return Future.value(-1);
  }

  //拷贝打包产物
  await copyFile(
      ['-r', '--'], '${buildPath}/App.framework', productPath, iosDeployEnv);
  //拷贝其他
  await copyOtherFiles(
      flutterRoot, iosDeployEnv, productPath, buildMode, targetPath);

  String precompilationFlag = "";
  if (buildMode != 'debug') {
    precompilationFlag = '--precompiled';
  }
  //build bundle
  final List<String> bundleBuildCommand = <String>[
    '${flutterRoot}/bin/flutter',
    '--suppress-analytics',
    '--verbose',
    'build',
    'bundle',
    '--target-platform=ios',
    '--target=${targetFile}',
    '--depfile=${buildPath}/snapshot_blob.bin.d',
    '--asset-dir=${buildPath}/flutter_assets',
    '${precompilationFlag}',
  ];

  int bundleBuildResult = await processUtils.stream(
    bundleBuildCommand,
    trace: true,
    environment: iosDeployEnv,
    workingDirectory: targetPath,
  );
  if (bundleBuildResult == 0) {
    print('资源bundle 成功打出');
  } else {
    print('资源bundle 打包错误');
    return Future.value(-1);
  }
  await copyFile(['-rf', '--'], '${buildPath}/flutter_assets',
      '${productPath}/App.framework', iosDeployEnv);

  var plugins = await projectPluginInfos(targetPath);
  await exportiOSPlugins(plugins, productPath: productPath);
  await generateRegistry(plugins, productPath: productPath);
  await writeScripts(productPath);

  await openBuildFolder(productPath, iosDeployEnv, targetPath);
  return Future.value(1);
}

/*
 *  Des: Build App.framework Debug Version
 *  Args:
    -t :  help: 'local dart project path' defaultsTo: '.'
    -f :  help: 'flutter path'
 * Example:
    "-f",
    "/Users/sac/flutter",
    "-t",
    "/Users/sac/magpie/example",
 */
Future<Pair<int, String>> magpieBuildIOSDebug(List<String> args) async {
  ArgResults argResults = await parseArgs(args);
  String flutterRoot = argResults['flutterroot'];
  String targetPath = argResults['targetPath'];

  if (targetPath == null) {
    targetPath = '.';
  }
  if (flutterRoot == null) {
    print('Error: Please use -f to locate the flutter install path');
    return Pair(-1, 'Please use -f to locate the flutter install path');
  }

  String buildMode = "debug";
  String archArm = 'arm64,armv7';
  pathHelper.configWithData(targetPath, buildMode);
  String buildPath = pathHelper.buildPath;
  String productPath = pathHelper.productPath;
  String productAppPath = pathHelper.productAppPath;
  String assetsPath = pathHelper.assetsPath;
  String targetFile = pathHelper.targetFile;
  String armPath = "${buildPath}/arm64";
  String x86Path = "${buildPath}/x86";

  final Map<String, String> iosDeployEnv =
      Map<String, String>.from(platform.environment);
  iosDeployEnv['BUILD_MODE'] = buildMode; //debug/release编译模式
  iosDeployEnv['FLUTTER_ROOT'] = flutterRoot; //编译的cpu平台
  iosDeployEnv['ARCHS_ARM'] = archArm;
  iosDeployEnv['BUILD_PATH'] = buildPath;
  iosDeployEnv['PRODUCT_PATH'] = productPath;
  iosDeployEnv['PRODUCT_APP_PATH'] = productAppPath;

  await pubGet(flutterRoot, iosDeployEnv, targetPath);
  await clean(flutterRoot, iosDeployEnv, targetPath);
  await cleanFolder(buildPath, iosDeployEnv, targetPath);
  await updatePackage(flutterRoot, iosDeployEnv, targetPath);
  await createStubAppFramework(armPath, SdkType.iPhone);
  await createStubAppFramework(x86Path, SdkType.iPhoneSimulator);
  await processUtils.stream(
    ['mkdir', '-p', '--', "${productPath}/App.framework"],
    trace: true,
    environment: iosDeployEnv,
    workingDirectory: targetPath,
  );

  final List<String> lipoCreatCommand = <String>[
    'lipo',
    '-create',
    '${armPath}/App.framework/App',
    '${x86Path}/App.framework/App',
    '-output',
    '${productPath}/App.framework/App',
  ];
  int lipoResult = await processUtils.stream(
    lipoCreatCommand,
    trace: true,
  );
  if (lipoResult == 0) {
    print('合并framework成功');
  } else {
    print('ERROR：合并framework成功失败');
  }

  final List<String> buildBundleCommand = <String>[
    '${flutterRoot}/bin/flutter',
    'build',
    'bundle',
    '--debug',
    '--asset-dir=${assetsPath}',
    '--target=${targetFile}',
  ];
  int buildResult = await processUtils.stream(
    buildBundleCommand,
    trace: true,
    environment: iosDeployEnv,
    workingDirectory: targetPath,
  );
  if (buildResult == 0) {
    print('打Debug包成功');
  } else {
    print('ERROR：打Debug包失败');
    return Pair(-1, '打Debug包失败');
  }

  await copyOtherFiles(
      flutterRoot, iosDeployEnv, productPath, buildMode, targetPath);
  var plugins = await projectPluginInfos(targetPath);
  await exportiOSPlugins(plugins, productPath: productPath);
  await generateRegistry(plugins, productPath: productPath);
  await writeScripts(productPath);

  await openBuildFolder(productPath, iosDeployEnv, targetPath);
  return Pair(1, productPath);
}

void openBuildFolder(
    String productPath, Map<String, String> iosDeployEnv, targetPath) async {
  if (platform.isWindows) {
    return print('构建产物位于:$productPath');
  }
  final List<String> openProductCommand = <String>['open', '${productPath}'];
  int openResult = await processUtils.stream(
    openProductCommand,
    trace: true,
    environment: iosDeployEnv,
    workingDirectory: targetPath,
  );
  if (openResult == 0) {
    print('打开输出目录成功');
  } else {
    print('ERROR：打开输出目录失败');
  }
}

//Flutter clean
void clean(String flutterRoot, Map<String, String> iosDeployEnv,
    String targetPath) async {
  final List<String> cleanCommand = <String>[
    '${flutterRoot}/bin/flutter',
    '--verbose',
    'clean'
  ];
  int cleanResult = await processUtils.stream(
    cleanCommand,
    trace: true,
    environment: iosDeployEnv,
    workingDirectory: targetPath,
  );
  if (cleanResult == 0) {
    print('clean 成功');
  }
}

//删除目标输出文件夹
void cleanFolder(String buildPath, Map<String, String> iosDeployEnv,
    String targetPath) async {
  final List<String> cleanCommand = <String>['rm', '-r', buildPath];
  int cleanResult = await processUtils.stream(
    cleanCommand,
    trace: true,
    environment: iosDeployEnv,
    workingDirectory: targetPath,
  );
  if (cleanResult == 0) {
    print('clean目标目录 成功');
  } else {
    print('目标目录不存在');
  }
}

//更新依赖
void updatePackage(String flutterRoot, Map<String, String> iosDeployEnv,
    String targetPath) async {
  //更新package
  final List<String> getPackagesCommand = <String>[
    '${flutterRoot}/bin/flutter',
    'packages',
    'get'
  ];

  int getPackagesResult = await processUtils.stream(
    getPackagesCommand,
    trace: true,
    environment: iosDeployEnv,
    workingDirectory: targetPath,
  );
  if (getPackagesResult == 0) {
    print('get packages 成功');
  }
}

//复制其他文件
void copyOtherFiles(String flutterRoot, Map<String, String> iosDeployEnv,
    String productPath, String buildMode, String targetPath) async {
  String artifactVariant = "unknown";
  switch (buildMode) {
    case 'release':
      artifactVariant = "ios-release";
      break;
    case 'profile':
      artifactVariant = "ios-profile";
      break;
    case 'debug':
      artifactVariant = "ios";
      break;
    default:
      print('ERROR: Unknown FLUTTER_BUILD_MODE: ${buildMode}.');
      return null;
      break;
  }
  //资源文件拷贝
  // String frameworkPath =
  //     '${flutterRoot}/bin/cache/artifacts/engine/${artifactVariant}';
  // String flutterFramework = '${frameworkPath}/Flutter.framework';
  // String flutterPodspec = '${frameworkPath}/Flutter.podspec';
  //拷贝Flutter引擎
  // await copyFile(['-r', '--'], flutterFramework, productPath, iosDeployEnv);
  //拷贝Flutter spec文件
  // await copyFile(['-r', '--'], flutterPodspec, productPath, iosDeployEnv);
  //拷贝App.framework的info.plist文件
  String appPlistPath =
      "${flutterRoot}/packages/flutter_tools/templates/app/ios.tmpl/Flutter/AppFrameworkInfo.plist";
  await copyFile(['--'], appPlistPath,
      '${productPath}/App.framework/Info.plist', iosDeployEnv);

  // final List<String> sedCommand = <String>[
  //   'sed',
  //   '-i',
  //   '',
  //   '-e',
  //   // 's/\'Flutter.framework\'/\'Flutter.framework\', \'App.framework\'/g',
  //   's/\'Flutter.framework\'/\'App.framework\'/g',
  //   '${productPath}/Flutter.podspec'
  // ];
  // int sedResult = await processUtils.stream(
  //   sedCommand,
  //   trace: true,
  //   environment: iosDeployEnv,
  //   workingDirectory: targetPath,
  // );
  // if (sedResult == 0) {
  //   print('spec修改成功');
  // } else {
  //   print('ERROR：spec修改失败');
  // }
}

//打App.framework空包
Future<RunResult> createStubAppFramework(
    String productPath, SdkType sdk) async {
  const String appFrameworkName = 'App.framework';
  const String binaryName = 'App';
  String output = fs.path.join(fs.currentDirectory.path, productPath);
  Directory outputDirectory = fs.directory(fs.path.normalize(output));
  // Directory iPhoneBuildOutput = outputDirectory.childDirectory('debug').childDirectory('iphoneos');
  Directory iPhoneAppFrameworkDirectory =
      outputDirectory.childDirectory(appFrameworkName);
  File outputFile = iPhoneAppFrameworkDirectory.childFile(binaryName);

  try {
    outputFile.createSync(recursive: true);
  } catch (e) {
    print('Failed to create App.framework stub at ${outputFile.path}');
  }

  final Directory tempDir =
      fs.systemTempDirectory.createTempSync('flutter_tools_stub_source.');
  try {
    final File stubSource = tempDir.childFile('debug_app.cc')
      ..writeAsStringSync(r'''
  static const int Moo = 88;
  ''');

    List<String> archFlags;
    if (sdk == SdkType.iPhone) {
      archFlags = <String>[
        '-arch',
        getNameForDarwinArch(DarwinArch.armv7),
        '-arch',
        getNameForDarwinArch(DarwinArch.arm64),
      ];
    } else {
      archFlags = <String>[
        '-arch',
        getNameForDarwinArch(DarwinArch.x86_64),
      ];
    }

    return await xcode.clang(<String>[
      '-x',
      'c',
      ...archFlags,
      stubSource.path,
      '-dynamiclib',
      '-fembed-bitcode-marker',
      '-Xlinker',
      '-rpath',
      '-Xlinker',
      '@executable_path/Frameworks',
      '-Xlinker',
      '-rpath',
      '-Xlinker',
      '@loader_path/Frameworks',
      '-install_name',
      '@rpath/App.framework/App',
      '-isysroot',
      await xcode.sdkLocation(sdk),
      '-o',
      outputFile.path,
    ]);
  } finally {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException catch (_) {
      // Best effort. Sometimes we can't delete things from system temp.
    } catch (e) {
      print('Failed to create App.framework stub at ${outputFile.path}');
    }
  }
}

String getNameForDarwinArch(DarwinArch arch) {
  switch (arch) {
    case DarwinArch.armv7:
      return 'armv7';
    case DarwinArch.arm64:
      return 'arm64';
    case DarwinArch.x86_64:
      return 'x86_64';
  }
  assert(false);
  return null;
}
