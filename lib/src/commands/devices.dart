import 'dart:async';
import 'dart:convert';

import '../base/common.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../device.dart';
import '../doctor.dart';
import '../globals.dart';
import '../runner/mpcli_command.dart';
import '../simple_device_entity.dart';

class DevicesCommand extends MpcliCommand {
  @override
  final String name = 'devices';

  @override
  final String description = 'List all connected devices.';

  @override
  Future<MpcliCommandResult> runCommand() async {
    if (!doctor.canListAnything) {
      throwToolExit(
          "Unable to locate a development device; please run 'mgpcli doctor' for "
          'information about installing additional components.',
          exitCode: 1);
    }

    final List<Device> devices =
        await deviceManager.getAllConnectedDevices().toList();

    if (devices.isEmpty) {
      printStatus('No devices detected.');
      final List<String> diagnostics =
          await deviceManager.getDeviceDiagnostics();
      if (diagnostics.isNotEmpty) {
        printStatus('');
        for (String diagnostic in diagnostics) {
          printStatus('• $diagnostic', hangingIndent: 2);
        }
      }
    } else {
      printStatus(
          '${devices.length} connected ${pluralize('device', devices.length)}:\n');
      await Device.printDevices(devices);
    }
    await _printCustomDevice(devices);
    return null;
  }

  void _printCustomDevice(List<Device> devices) async {
    SimpleDeviceEntity entity = SimpleDeviceEntity();
    List<SimpleDevice> sDevices = [];
    for (Device d in devices) {
      var sdkNameVersion = await d.sdkNameAndVersion;
      var targetPlatform = await d.targetPlatform;
      var platformName = getNameForTargetPlatform(targetPlatform);
      SimpleDevice sd = SimpleDevice(
          category: d.category.value,
          deviceId: d.id,
          deviceName: d.name,
          platform: d.platformType.value,
          platformName: platformName,
          sdkNameVersion: sdkNameVersion);
      sDevices.add(sd);
    }
    ;
    entity.devices = sDevices;

    String jsonString = jsonEncode(entity.toJson());
    printStatus("__device_start__${jsonString}__device_end__");
  }
}
