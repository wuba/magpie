import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HelpInformation extends StatelessWidget {
  const HelpInformation({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10, top: 10, bottom: 10),
      child: Text(
        '友情提示：\n1. 如业务App尚未接入Magpie SDK，可临时使用二维码安装样例应用进行开发；\n'
        '2. Android样例为armeabi-v7a架构；\n'
        '3. iOS样例为x86_64架构，签名原因只适用于模拟器；下载后先解压，再安装；\n'
        '4. 如遇Mac警告无法运行Demo，请执行sudo spctl --master-disable\n',
        style: TextStyle(color: Colors.grey[700]),
      ),
    );
  }
}
