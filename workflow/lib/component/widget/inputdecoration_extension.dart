import 'package:flutter/material.dart';

import 'directory_picker.dart';

extension MgpInputDecorationExtension on InputDecoration {
  InputDecoration asMgpInputDecoration({
    Function onClearTap,
    BuildContext context,
    ChooseCallback onDirectoryChanged,
  }) {
    assert(
        onDirectoryChanged == null ||
            (onDirectoryChanged != null && context != null),
        'To use folder picker, provide the context');
    return this.copyWith(
      contentPadding: EdgeInsets.zero,
      labelStyle: const TextStyle(color: Colors.grey),
      focusColor: const Color(0x88FB5638),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFF2F4F7)),
      ),
      suffix: IconButton(
        icon: Icon(Icons.clear, size: 18, color: Colors.grey),
        onPressed: onClearTap,
      ),
      suffixIcon: onDirectoryChanged != null
          ? Tooltip(
              child: GestureDetector(
                child: Icon(Icons.folder_open),
                onTap: () => DirectoryPicker.show(context,
                    onDirectoryChanged: onDirectoryChanged),
              ),
              message: 'Open folder picker',
            )
          : null,
    );
  }
}
