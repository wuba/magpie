// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import 'package:yaml/yaml.dart';

import 'base/common.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'flutter_manifest.dart';
import 'globals.dart';

FlutterProjectFactory get projectFactory => context.get<FlutterProjectFactory>() ?? FlutterProjectFactory();
const String defaultManifestPath = 'pubspec.yaml';
class FlutterProjectFactory {
  FlutterProjectFactory();

  final Map<String, FlutterProject> _projects =
      <String, FlutterProject>{};

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  FlutterProject fromDirectory(Directory directory) {
    assert(directory != null);
    return _projects.putIfAbsent(directory.path, /* ifAbsent */ () {
      final FlutterManifest manifest = FlutterProject._readManifest(
        directory.childFile(defaultManifestPath).path,
      );
      final FlutterManifest exampleManifest = FlutterProject._readManifest(
        FlutterProject._exampleDirectory(directory)
            .childFile(defaultManifestPath)
            .path,
      );
      return FlutterProject(directory, manifest, exampleManifest);
    });
  }
}

/// Represents the contents of a Flutter project at the specified [directory].
///
/// [FlutterManifest] information is read from `pubspec.yaml` and
/// `example/pubspec.yaml` files on construction of a [FlutterProject] instance.
/// The constructed instance carries an immutable snapshot representation of the
/// presence and content of those files. Accordingly, [FlutterProject] instances
/// should be discarded upon changes to the `pubspec.yaml` files, but can be
/// used across changes to other files, as no other file-level information is
/// cached.
class FlutterProject {
  @visibleForTesting
  FlutterProject(this.directory, this.manifest, this._exampleManifest)
    : assert(directory != null),
      assert(manifest != null),
      assert(_exampleManifest != null);

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject fromDirectory(Directory directory) => projectFactory.fromDirectory(directory);

  /// Returns a [FlutterProject] view of the current directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject current() => fromDirectory(fs.currentDirectory);

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject fromPath(String path) => fromDirectory(fs.directory(path));

  /// The location of this project.
  final Directory directory;

  /// The manifest of this project.
  final FlutterManifest manifest;

  /// The manifest of the example sub-project of this project.
  final FlutterManifest _exampleManifest;

  String _organizationNameFromPackageName(String packageName) {
    if (packageName != null && 0 <= packageName.lastIndexOf('.')) {
      return packageName.substring(0, packageName.lastIndexOf('.'));
    }
    return null;
  }


  /// The Android sub project of this project.
  AndroidProject _android;
  AndroidProject get android => _android ??= AndroidProject._(this);

  /// The MacOS sub project of this project.
  MacOSProject _macos;
  MacOSProject get macos => _macos ??= MacOSProject._(this);

  /// The Linux sub project of this project.
  LinuxProject _linux;
  LinuxProject get linux => _linux ??= LinuxProject._(this);

  /// The Windows sub project of this project.
  WindowsProject _windows;
  WindowsProject get windows => _windows ??= WindowsProject._(this);

  /// The Fuchsia sub project of this project.
  FuchsiaProject _fuchsia;
  FuchsiaProject get fuchsia => _fuchsia ??= FuchsiaProject._(this);

  /// The `pubspec.yaml` file of this project.
  File get pubspecFile => directory.childFile('pubspec.yaml');

  /// The `.packages` file of this project.
  File get packagesFile => directory.childFile('.packages');

  /// The `.flutter-plugins` file of this project.
  File get flutterPluginsFile => directory.childFile('.flutter-plugins');

  /// The `.flutter-plugins-dependencies` file of this project,
  /// which contains the dependencies each plugin depends on.
  File get flutterPluginsDependenciesFile => directory.childFile('.flutter-plugins-dependencies');

  /// The `.dart-tool` directory of this project.
  Directory get dartTool => directory.childDirectory('.dart_tool');

  /// The directory containing the generated code for this project.
  Directory get generated => directory
    .absolute
    .childDirectory('.dart_tool')
    .childDirectory('build')
    .childDirectory('generated')
    .childDirectory(manifest.appName);

  /// The example sub-project of this project.
  FlutterProject get example => FlutterProject(
    _exampleDirectory(directory),
    _exampleManifest,
    FlutterManifest.empty(),
  );

  /// True if this project is a Flutter module project.
  bool get isModule => manifest.isModule;

  /// True if the Flutter project is using the AndroidX support library
  bool get usesAndroidX => manifest.usesAndroidX;

  /// True if this project has an example application.
  bool get hasExampleApp => _exampleDirectory(directory).existsSync();

  /// The directory that will contain the example if an example exists.
  static Directory _exampleDirectory(Directory directory) => directory.childDirectory('example');

  /// Reads and validates the `pubspec.yaml` file at [path], asynchronously
  /// returning a [FlutterManifest] representation of the contents.
  ///
  /// Completes with an empty [FlutterManifest], if the file does not exist.
  /// Completes with a ToolExit on validation error.
  static FlutterManifest _readManifest(String path) {
    FlutterManifest manifest;
    try {
      manifest = FlutterManifest.createFromPath(path);
    } on YamlException catch (e) {
      printStatus('Error detected in pubspec.yaml:', emphasis: true);
      printError('$e');
    }
    if (manifest == null) {
      throwToolExit('Please correct the pubspec.yaml file at $path');
    }
    return manifest;
  }


  /// Return the set of builders used by this package.
  YamlMap get builders {
    if (!pubspecFile.existsSync()) {
      return null;
    }
    final YamlMap pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
    // If the pubspec file is empty, this will be null.
    if (pubspec == null) {
      return null;
    }
    return pubspec['builders'] as YamlMap;
  }

  /// Whether there are any builders used by this package.
  bool get hasBuilders {
    final YamlMap result = builders;
    return result != null && result.isNotEmpty;
  }
}

/// Represents an Xcode-based sub-project.
///
/// This defines interfaces common to iOS and macOS projects.
abstract class XcodeBasedProject {
  /// The parent of this project.
  FlutterProject get parent;

  /// Whether the subproject (either iOS or macOS) exists in the Flutter project.
  bool existsSync();

  /// The Xcode project (.xcodeproj directory) of the host app.
  Directory get xcodeProject;

  /// The 'project.pbxproj' file of [xcodeProject].
  File get xcodeProjectInfoFile;

  /// The Xcode workspace (.xcworkspace directory) of the host app.
  Directory get xcodeWorkspace;

  /// Contains definitions for FLUTTER_ROOT, LOCAL_ENGINE, and more flags for
  /// the Xcode build.
  File get generatedXcodePropertiesFile;

  /// The Flutter-managed Xcode config file for [mode].
  File xcodeConfigFor(String mode);

  /// The script that exports environment variables needed for Flutter tools.
  /// Can be run first in a Xcode Script build phase to make FLUTTER_ROOT,
  /// LOCAL_ENGINE, and other Flutter variables available to any flutter
  /// tooling (`flutter build`, etc) to convert into flags.
  File get generatedEnvironmentVariableExportScript;

  /// The CocoaPods 'Podfile'.
  File get podfile;

  /// The CocoaPods 'Podfile.lock'.
  File get podfileLock;

  /// The CocoaPods 'Manifest.lock'.
  File get podManifestLock;

  /// True if the host app project is using Swift.
  Future<bool> get isSwift;

  /// Directory containing symlinks to pub cache plugins source generated on `pod install`.
  Directory get symlinks;
}

/// Represents the Android sub-project of a Flutter project.
///
/// Instances will reflect the contents of the `android/` sub-folder of
/// Flutter applications and the `.android/` sub-folder of Flutter module projects.
class AndroidProject {
  AndroidProject._(this.parent);

  /// The parent of this project.
  final FlutterProject parent;

  static final RegExp _applicationIdPattern = RegExp('^\\s*applicationId\\s+[\'\"](.*)[\'\"]\\s*\$');
  static final RegExp _kotlinPluginPattern = RegExp('^\\s*apply plugin\:\\s+[\'\"]kotlin-android[\'\"]\\s*\$');
  static final RegExp _groupPattern = RegExp('^\\s*group\\s+[\'\"](.*)[\'\"]\\s*\$');

  /// The Gradle root directory of the Android host app. This is the directory
  /// containing the `app/` subdirectory and the `settings.gradle` file that
  /// includes it in the overall Gradle project.
  Directory get hostAppGradleRoot {
    if (!isModule || _editableHostAppDirectory.existsSync()) {
      return _editableHostAppDirectory;
    }
    return ephemeralDirectory;
  }

  /// The Gradle root directory of the Android wrapping of Flutter and plugins.
  /// This is the same as [hostAppGradleRoot] except when the project is
  /// a Flutter module with an editable host app.
  Directory get _flutterLibGradleRoot => isModule ? ephemeralDirectory : _editableHostAppDirectory;

  //Directory get ephemeralDirectory => parent.directory.childDirectory('.android');
  Directory get ephemeralDirectory => parent.directory.childDirectory('android_magpie');
  Directory get _editableHostAppDirectory => parent.directory.childDirectory('android');

  /// True if the parent Flutter project is a module.
  bool get isModule => parent.isModule;

  /// True if the Flutter project is using the AndroidX support library
  bool get usesAndroidX => parent.usesAndroidX;

  /// True, if the app project is using Kotlin.
  bool get isKotlin {
    final File gradleFile = hostAppGradleRoot.childDirectory('app').childFile('build.gradle');
    return _firstMatchInFile(gradleFile, _kotlinPluginPattern) != null;
  }

  File get appManifestFile {
    return isUsingGradle
        ? fs.file(fs.path.join(hostAppGradleRoot.path, 'app', 'src', 'main', 'AndroidManifest.xml'))
        : hostAppGradleRoot.childFile('AndroidManifest.xml');
  }

  File get gradleAppOutV1File => gradleAppOutV1Directory.childFile('app-debug.apk');

  Directory get gradleAppOutV1Directory {
    return fs.directory(fs.path.join(hostAppGradleRoot.path, 'app', 'build', 'outputs', 'apk'));
  }

  /// Whether the current flutter project has an Android sub-project.
  bool existsSync() {
    return parent.isModule || _editableHostAppDirectory.existsSync();
  }

  bool get isUsingGradle {
    return hostAppGradleRoot.childFile('build.gradle').existsSync();
  }

  String get applicationId {
    final File gradleFile = hostAppGradleRoot.childDirectory('app').childFile('build.gradle');
    return _firstMatchInFile(gradleFile, _applicationIdPattern)?.group(1);
  }

  String get group {
    final File gradleFile = hostAppGradleRoot.childFile('build.gradle');
    return _firstMatchInFile(gradleFile, _groupPattern)?.group(1);
  }

  /// The build directory where the Android artifacts are placed.
  Directory get buildDirectory {
    return parent.directory.childDirectory('build');
  }


//  bool _shouldRegenerateFromTemplate() {
//    return isOlderThanReference(entity: ephemeralDirectory, referenceFile: parent.pubspecFile)
//        || Cache.instance.isOlderThanToolsStamp(ephemeralDirectory);
//  }

  File get localPropertiesFile => _flutterLibGradleRoot.childFile('local.properties');

  Directory get pluginRegistrantHost => _flutterLibGradleRoot.childDirectory(isModule ? 'Flutter' : 'app');

  AndroidEmbeddingVersion getEmbeddingVersion() {
    if (isModule) {
      // A module type's Android project is used in add-to-app scenarios and
      // only supports the V2 embedding.
      return AndroidEmbeddingVersion.v2;
    }
    if (appManifestFile == null || !appManifestFile.existsSync()) {
      return AndroidEmbeddingVersion.v1;
    }
    xml.XmlDocument document;
    try {
      document = xml.parse(appManifestFile.readAsStringSync());
    } on xml.XmlParserException {
      throwToolExit('Error parsing $appManifestFile '
                    'Please ensure that the android manifest is a valid XML document and try again.');
    } on FileSystemException {
      throwToolExit('Error reading $appManifestFile even though it exists. '
                    'Please ensure that you have read permission to this file and try again.');
    }
    for (xml.XmlElement metaData in document.findAllElements('meta-data')) {
      final String name = metaData.getAttribute('android:name');
      if (name == 'flutterEmbedding') {
        final String embeddingVersionString = metaData.getAttribute('android:value');
        if (embeddingVersionString == '1') {
          return AndroidEmbeddingVersion.v1;
        }
        if (embeddingVersionString == '2') {
          return AndroidEmbeddingVersion.v2;
        }
      }
    }
    return AndroidEmbeddingVersion.v1;
  }
}

/// Iteration of the embedding Java API in the engine used by the Android project.
enum AndroidEmbeddingVersion {
  /// V1 APIs based on io.flutter.app.FlutterActivity.
  v1,
  /// V2 APIs based on io.flutter.embedding.android.FlutterActivity.
  v2,
}


/// Deletes [directory] with all content.
void _deleteIfExistsSync(Directory directory) {
  if (directory.existsSync()) {
    directory.deleteSync(recursive: true);
  }
}


/// Returns the first line-based match for [regExp] in [file].
///
/// Assumes UTF8 encoding.
Match _firstMatchInFile(File file, RegExp regExp) {
  if (!file.existsSync()) {
    return null;
  }
  for (String line in file.readAsLinesSync()) {
    final Match match = regExp.firstMatch(line);
    if (match != null) {
      return match;
    }
  }
  return null;
}

/// The macOS sub project.
class MacOSProject implements XcodeBasedProject {
  MacOSProject._(this.parent);

  @override
  final FlutterProject parent;

  static const String _hostAppBundleName = 'Runner';

  @override
  bool existsSync() => _macOSDirectory.existsSync();

  Directory get _macOSDirectory => parent.directory.childDirectory('macos');

  /// The directory in the project that is managed by Flutter. As much as
  /// possible, files that are edited by Flutter tooling after initial project
  /// creation should live here.
  Directory get managedDirectory => _macOSDirectory.childDirectory('Flutter');

  /// The subdirectory of [managedDirectory] that contains files that are
  /// generated on the fly. All generated files that are not intended to be
  /// checked in should live here.
  Directory get ephemeralDirectory => managedDirectory.childDirectory('ephemeral');

  /// The xcfilelist used to track the inputs for the Flutter script phase in
  /// the Xcode build.
  File get inputFileList => ephemeralDirectory.childFile('FlutterInputs.xcfilelist');

  /// The xcfilelist used to track the outputs for the Flutter script phase in
  /// the Xcode build.
  File get outputFileList => ephemeralDirectory.childFile('FlutterOutputs.xcfilelist');

  @override
  File get generatedXcodePropertiesFile => ephemeralDirectory.childFile('Flutter-Generated.xcconfig');

  @override
  File xcodeConfigFor(String mode) => managedDirectory.childFile('Flutter-$mode.xcconfig');

  @override
  File get generatedEnvironmentVariableExportScript => ephemeralDirectory.childFile('flutter_export_environment.sh');

  @override
  File get podfile => _macOSDirectory.childFile('Podfile');

  @override
  File get podfileLock => _macOSDirectory.childFile('Podfile.lock');

  @override
  File get podManifestLock => _macOSDirectory.childDirectory('Pods').childFile('Manifest.lock');

  @override
  Directory get xcodeProject => _macOSDirectory.childDirectory('$_hostAppBundleName.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  Directory get xcodeWorkspace => _macOSDirectory.childDirectory('$_hostAppBundleName.xcworkspace');

  @override
  Directory get symlinks => ephemeralDirectory.childDirectory('.symlinks');

  @override
  Future<bool> get isSwift async => true;

  /// The file where the Xcode build will write the name of the built app.
  ///
  /// Ideally this will be replaced in the future with inspection of the Runner
  /// scheme's target.
  File get nameFile => ephemeralDirectory.childFile('.app_filename');

}

/// The Windows sub project
class WindowsProject {
  WindowsProject._(this.project);

  final FlutterProject project;

  bool existsSync() => _editableDirectory.existsSync();

  Directory get _editableDirectory => project.directory.childDirectory('windows');

  /// The directory in the project that is managed by Flutter. As much as
  /// possible, files that are edited by Flutter tooling after initial project
  /// creation should live here.
  Directory get managedDirectory => _editableDirectory.childDirectory('flutter');

  /// The subdirectory of [managedDirectory] that contains files that are
  /// generated on the fly. All generated files that are not intended to be
  /// checked in should live here.
  Directory get ephemeralDirectory => managedDirectory.childDirectory('ephemeral');

  /// Contains definitions for FLUTTER_ROOT, LOCAL_ENGINE, and more flags for
  /// the build.
  File get generatedPropertySheetFile => ephemeralDirectory.childFile('Generated.props');

  // The MSBuild project file.
  File get vcprojFile => _editableDirectory.childFile('Runner.vcxproj');

  // The MSBuild solution file.
  File get solutionFile => _editableDirectory.childFile('Runner.sln');

  /// The file where the VS build will write the name of the built app.
  ///
  /// Ideally this will be replaced in the future with inspection of the project.
  File get nameFile => ephemeralDirectory.childFile('exe_filename');

  Future<void> ensureReadyForPlatformSpecificTooling() async {}
}

/// The Linux sub project.
class LinuxProject {
  LinuxProject._(this.project);

  final FlutterProject project;

  Directory get _editableDirectory => project.directory.childDirectory('linux');

  /// The directory in the project that is managed by Flutter. As much as
  /// possible, files that are edited by Flutter tooling after initial project
  /// creation should live here.
  Directory get managedDirectory => _editableDirectory.childDirectory('flutter');

  /// The subdirectory of [managedDirectory] that contains files that are
  /// generated on the fly. All generated files that are not intended to be
  /// checked in should live here.
  Directory get ephemeralDirectory => managedDirectory.childDirectory('ephemeral');

  bool existsSync() => _editableDirectory.existsSync();

  /// The Linux project makefile.
  File get makeFile => _editableDirectory.childFile('Makefile');

  /// Contains definitions for FLUTTER_ROOT, LOCAL_ENGINE, and more flags for
  /// the build.
  File get generatedMakeConfigFile => ephemeralDirectory.childFile('generated_config.mk');

  Future<void> ensureReadyForPlatformSpecificTooling() async {}
}

/// The Fuchsia sub project
class FuchsiaProject {
  FuchsiaProject._(this.project);

  final FlutterProject project;

  Directory _editableHostAppDirectory;
  Directory get editableHostAppDirectory =>
      _editableHostAppDirectory ??= project.directory.childDirectory('fuchsia');

  bool existsSync() => editableHostAppDirectory.existsSync();

  Directory _meta;
  Directory get meta =>
      _meta ??= editableHostAppDirectory.childDirectory('meta');
}
