import 'package:flutter/cupertino.dart';

import 'application_install.dart';
import 'help_information.dart';
import '../widget/container_extension.dart';

class SampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              child: Text('安装样例', style: TextStyle(fontSize: 18)),
              padding: EdgeInsets.only(bottom: 50),
            ),
            ApplicationInstall(),
            Padding(
              child: HelpInformation(),
              padding: EdgeInsets.only(top: 100),
            ),
          ],
        ),
      ).asCard,
    );
  }
}
