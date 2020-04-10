// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import '../base/common.dart';
import '../base/terminal.dart';
import '../globals.dart';

/// User message when no development certificates are found in the keychain.
///
/// The user likely never did any iOS development.
const String noCertificatesInstruction = '''
════════════════════════════════════════════════════════════════════════════════
No valid code signing certificates were found
You can connect to your Apple Developer account by signing in with your Apple ID
in Xcode and create an iOS Development Certificate as well as a Provisioning\u0020
Profile for your project by:
$fixWithDevelopmentTeamInstruction
  5- Trust your newly created Development Certificate on your iOS device
     via Settings > General > Device Management > [your new certificate] > Trust

For more information, please visit:
  https://developer.apple.com/library/content/documentation/IDEs/Conceptual/
  AppDistributionGuide/MaintainingCertificates/MaintainingCertificates.html

Or run on an iOS simulator without code signing
════════════════════════════════════════════════════════════════════════════════''';

/// User message when there are no provisioning profile for the current app bundle identifier.
///
/// The user did iOS development but never on this project and/or device.
const String noProvisioningProfileInstruction = '''
════════════════════════════════════════════════════════════════════════════════
No Provisioning Profile was found for your project's Bundle Identifier or your\u0020
device. You can create a new Provisioning Profile for your project in Xcode for\u0020
your team by:
$fixWithDevelopmentTeamInstruction

It's also possible that a previously installed app with the same Bundle\u0020
Identifier was signed with a different certificate.

For more information, please visit:
  https://flutter.dev/setup/#deploy-to-ios-devices

Or run on an iOS simulator without code signing
════════════════════════════════════════════════════════════════════════════════''';

/// Fallback error message for signing issues.
///
/// Couldn't auto sign the app but can likely solved by retracing the signing flow in Xcode.
const String noDevelopmentTeamInstruction = '''
════════════════════════════════════════════════════════════════════════════════
Building a deployable iOS app requires a selected Development Team with a\u0020
Provisioning Profile. Please ensure that a Development Team is selected by:
$fixWithDevelopmentTeamInstruction

For more information, please visit:
  https://flutter.dev/setup/#deploy-to-ios-devices

Or run on an iOS simulator without code signing
════════════════════════════════════════════════════════════════════════════════''';
const String fixWithDevelopmentTeamInstruction = '''
  1- Open the Flutter project's Xcode target with
       open ios/Runner.xcworkspace
  2- Select the 'Runner' project in the navigator then the 'Runner' target
     in the project settings
  3- In the 'General' tab, make sure a 'Development Team' is selected.\u0020
     You may need to:
         - Log in with your Apple ID in Xcode first
         - Ensure you have a valid unique Bundle ID
         - Register your device with your Apple Developer Account
         - Let Xcode automatically provision a profile for your app
  4- Build or run your project again''';

final RegExp _securityFindIdentityDeveloperIdentityExtractionPattern =
    RegExp(r'^\s*\d+\).+"(.+Develop(ment|er).+)"$');
final RegExp _securityFindIdentityCertificateCnExtractionPattern =
    RegExp(r'.*\(([a-zA-Z0-9]+)\)');
final RegExp _certificateOrganizationalUnitExtractionPattern =
    RegExp(r'OU=([a-zA-Z0-9]+)');

Future<String> _chooseSigningIdentity(
    List<String> validCodeSigningIdentities, bool usesTerminalUi) async {
  // The user has no valid code signing identities.
  if (validCodeSigningIdentities.isEmpty) {
    printError(noCertificatesInstruction, emphasis: true);
    throwToolExit(
        'No development certificates available to code sign app for device deployment');
  }

  if (validCodeSigningIdentities.length == 1)
    return validCodeSigningIdentities.first;

  if (validCodeSigningIdentities.length > 1) {
    final String savedCertChoice = config.getValue('ios-signing-cert');

    if (savedCertChoice != null) {
      if (validCodeSigningIdentities.contains(savedCertChoice)) {
        printStatus(
            'Found saved certificate choice "$savedCertChoice". To clear, use "flutter config".');
        return savedCertChoice;
      } else {
        printError(
            'Saved signing certificate "$savedCertChoice" is not a valid development certificate');
      }
    }

    // If terminal UI can't be used, just attempt with the first valid certificate
    // since we can't ask the user.
    if (!usesTerminalUi) return validCodeSigningIdentities.first;

    final int count = validCodeSigningIdentities.length;
    printStatus(
      'Multiple valid development certificates available (your choice will be saved):',
      emphasis: true,
    );
    for (int i = 0; i < count; i++) {
      printStatus('  ${i + 1}) ${validCodeSigningIdentities[i]}',
          emphasis: true);
    }
    printStatus('  a) Abort', emphasis: true);

    final String choice = await terminal.promptForCharInput(
      List<String>.generate(count, (int number) => '${number + 1}')..add('a'),
      prompt: 'Please select a certificate for code signing',
      displayAcceptedCharacters: true,
      defaultChoiceIndex: 0, // Just pressing enter chooses the first one.
    );

    if (choice == 'a') {
      throwToolExit(
          'Aborted. Code signing is required to build a deployable iOS app.');
    } else {
      final String selectedCert =
          validCodeSigningIdentities[int.parse(choice) - 1];
      printStatus('Certificate choice "$selectedCert" saved');
      config.setValue('ios-signing-cert', selectedCert);
      return selectedCert;
    }
  }

  return null;
}
