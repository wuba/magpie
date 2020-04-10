import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

extension ContainerExtension on Container {
  Widget get asCard {
    return Card(child: this, margin: this.margin??EdgeInsets.all(10));
  }
}
