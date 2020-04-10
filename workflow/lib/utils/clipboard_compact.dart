import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' as service;

/// flutter web
class Clipboard {
  static Future<bool> setData(String text) async {
    if (kIsWeb) {
      return Future.microtask(() {
        final textArea = new TextAreaElement();
        document.body.append(textArea);
        textArea.style.border = '0';
        textArea.style.margin = '0';
        textArea.style.padding = '0';
        textArea.style.opacity = '0';
        textArea.style.position = 'absolute';
        textArea.readOnly = true;
        textArea.value = text;
        textArea.select();
        final result = document.execCommand('copy');
        textArea.remove();
        return result;
      });
    }
    return service.Clipboard.setData(service.ClipboardData(text: text))
        .then((_) => true);
  }
}
