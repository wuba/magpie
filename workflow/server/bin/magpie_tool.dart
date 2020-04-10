import '../lib/src/magpie_plugin_ios.dart';

import '../lib/src/magpie_attach.dart';
import '../lib/src/magpie_build_android.dart';
import '../lib/src/magpie_build_ios.dart';
import '../lib/src/magpie_git_push.dart';

void main(List<String> args) {
  String cmd = args.length > 0 ? args.first : null;
  if (cmd == null) {
    print("There must have a command after magpie_tool.");
    return;
  }
  switch (cmd) {
    case "buildIOS":
      magpieBuildIOS(args);
      break;
    case "buildIOSdebug":
      magpieBuildIOSDebug(args);
      break;
    case "buildAndroid":
      magpieBuildAndroid(args);
      break;
    case "attach":
      magpieAttach(args, null);
      break;
    case "gitPush":
      magpieGitPush(args);
      break;
    case "injectPlugin": // test
      // generateRegistry(null);
      break;
    default:
  }
}
