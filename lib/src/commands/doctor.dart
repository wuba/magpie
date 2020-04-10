import 'dart:async';

import '../doctor.dart';
import '../runner/mpcli_command.dart';

class DoctorCommand extends MpcliCommand {
  DoctorCommand({this.verbose = false}) {
    argParser.addFlag(
      'android-licenses',
      defaultsTo: false,
      negatable: false,
      help: 'Run the Android SDK manager tool to accept the SDK\'s licenses.',
    );
    argParser.addOption(
      'check-for-remote-artifacts',
      hide: !verbose,
      help: 'Used to determine if Flutter engine artifacts for all platforms '
          'are available for download.',
      valueHelp: 'engine revision git hash',
    );
  }

  final bool verbose;

  @override
  final String name = 'doctor';

  @override
  final String description = 'Show information about the installed tooling.';

  // @override
  // Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
  //   return <DevelopmentArtifact>{
  //     DevelopmentArtifact.universal,
  //     // This is required because we use gen_snapshot to check if the host
  //     // machine can execute the provided artifacts. See `_genSnapshotRuns`
  //     // in `doctor.dart`.
  //     DevelopmentArtifact.android,
  //   };
  // }

  @override
  Future<MpcliCommandResult> runCommand() async {
    // if (argResults.wasParsed('check-for-remote-artifacts')) {
    //   final String engineRevision = argResults['check-for-remote-artifacts'];
    //   if (engineRevision.startsWith(RegExp(r'[a-f0-9]{1,40}'))) {
    //     final bool success = await doctor.checkRemoteArtifacts(engineRevision);
    //     if (!success) {
    //       throwToolExit('Artifacts for engine $engineRevision are missing or are '
    //           'not yet available.', exitCode: 1);
    //     }
    //   } else {
    //     throwToolExit('Remote artifact revision $engineRevision is not a valid '
    //         'git hash.');
    //   }
    // }
    final bool success = await doctor.diagnose(
        androidLicenses: argResults['android-licenses'], verbose: verbose);
    return MpcliCommandResult(
        success ? ExitStatus.success : ExitStatus.warning);
  }
}
