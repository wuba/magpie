import 'dart:async';
import 'dart:io';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../runner/mpcli_command.dart';
import '../base/os.dart' show os;
import '../../utils/util.dart';

class CreateCommand extends MpcliCommand {
  CreateCommand() {
    argParser.addOption(
      'description',
      defaultsTo: 'A new Flutter project.',
      help:
          'The description to use for your new Flutter project. This string ends up in the pubspec.yaml file.',
    );

    argParser.addOption(
      'project-name',
      defaultsTo: null,
      help:
          'The project name for this new Flutter project. This must be a valid dart package name.',
    );
    argParser.addOption(
      'ios-language',
      abbr: 'i',
      defaultsTo: 'swift',
      allowed: <String>['objc', 'swift'],
    );
    argParser.addOption(
      'android-language',
      abbr: 'a',
      defaultsTo: 'kotlin',
      allowed: <String>['java', 'kotlin'],
    );

    argParser.addFlag(
      'web',
      negatable: true,
      defaultsTo: false,
      hide: true,
      help: '(Experimental) Generate the web specific tooling. Only supported '
          'on non-stable branches',
    );

    argParser.addOption(
      'name',
      abbr: 'n',
      defaultsTo: '',
      help: 'create a template project',
    );
  }

  @override
  final String name = 'create';

  @override
  final String description = 'Create a new Flutter project.\n\n'
      'If run on a project that already exists, this will repair the project, recreating any files that are missing.';

  @override
  Future<MpcliCommandResult> runCommand() async {
    final String name = argResults['name'];
    if (name.length == 0) {
      throwToolExit('Please use "mgpcli create -n xxx" to create a template');
      return null;
    }

    final String currentPath = currentFolderPath();
    final Directory templateModule =
        fs.directory(fs.file(fs.path.join(currentPath, name)));

    final String fileRoot = userRootPath();
    final Directory srcDir =
        fs.directory(fs.path.join(fileRoot, 'template', 'module'));

    cliPrints('currentPath = ${currentPath}', false);
    cliPrints('fileRoot = ${fileRoot}', false);
    cliPrint('Downloading the template, wait a moment please...');

    try {
      templateModule.createSync(recursive: true);
      await copyDirectorySync(srcDir, templateModule);
      os.chmod(templateModule, '777');
      final Directory templateModuleMacFile =
          fs.directory(fs.file(fs.path.join(templateModule.path, '__MACOSX')));
      if (templateModuleMacFile.existsSync()) {
        templateModuleMacFile.deleteSync(recursive: true);
      }

      //magpie-SDK动态指定android目录下的local.properties内容
      await writeLocalProperties(fs.file(fs.path
          .join(templateModule.path, "android_magpie", "local.properties")));

      await replaceFilesText(
          fs.file(fs.path.join(
              templateModule.path, "android_magpie", "app", "build.gradle")),
          "wb_flutter_module",
          name);
      await replaceFilesText(
          fs.file(fs.path.join(templateModule.path, "android_magpie", "Flutter",
              "build.gradle")),
          "wb_flutter_module",
          name);
      await replaceFilesText(
          fs.file(fs.path.join(templateModule.path, "android_magpie", 'Flutter',
              'src', 'main', "AndroidManifest.xml")),
          "wb_flutter_module",
          name);
      await replaceFilesText(
          fs.file(fs.path.join(templateModule.path, "pubspec.yaml")),
          "wb_flutter_module",
          name);

      cliPrint(
          'New Project generated at => ' + fs.path.join(currentPath, name));
    } catch (e) {
      throwToolExit('Failed to fetch third-party artifact $templateModule: $e');
    }
    return null;
  }
}
