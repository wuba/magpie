import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workflow/model/simple_device.dart';
import 'package:workflow/provider/shared_data_provider.dart';

class BottomBar extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<BottomBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Consumer<SharedDataProvider>(
        builder: (ctx, provider, child) {
          SimpleDevice device = provider.currentDevice();
          String text;
          Color color = Colors.red;
          if (device != null && device.deviceName != null) {
            text = device.deviceName.trim();
            color = Colors.blue;
          } else {
            text = '未连接';
          }
          return Text.rich(
            TextSpan(
                text: '构建版本: Beta v1.${provider.buildNumber}\t',
                children: [
                  TextSpan(text: '当前链接设备: '),
                  TextSpan(text: text, style: TextStyle(color: color))
                ]),
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.end,
          );
        },
      ),
    );
  }
}
