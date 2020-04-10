import 'dart:html' as html;

import 'package:flutter/material.dart';

/// https://www.filledstacks.com/post/flutter-web-hover-and-mouse-cursor/
extension HoverExtension on Widget {
  static final body = html.window.document.querySelector('body');

  Widget get pointer {
    return MouseRegion(
      child: this,
      onHover: (event) => body.style.cursor = 'pointer',
      onExit: (event) => body.style.cursor = 'default',
    );
  }
}
