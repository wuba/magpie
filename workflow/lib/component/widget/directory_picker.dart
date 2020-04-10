import 'dart:collection';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workflow/model/response_bean.dart';
import 'package:workflow/utils/net_util.dart';
import 'hovor_extension.dart';

///
/// ```dart
/// 'Choose Folder'.asButton(onPress: () {
///     showDialog(context: context, builder: (ctx) {
///       return DirectoryPicker(onDirectoryChanged: (dir)=> debugPrint(dir));
///     });
/// }),
///```
/// Why do we need a custom directory picker?
///
/// We can not pick a local directory through `input`, even hack with `webkitdirectory/directory` from draft proposal, the absolute path is still missing;
/// On the other side, web tech is mainly designed to work with server, while server side can never access to local path on client (except for local-server);
///
/// So in order to pick a directory we need a custom picker, the electron use some kind of native-bridge, here we simply reuse the local server to host filesystem;
///
/// For more detailed analysis, please refer to [Flutter Web directory picker](http://blog.hacktons.cn/2020/02/11/flutter-web-directory-picker/)
class DirectoryPicker extends StatefulWidget {
  final ChooseCallback onDirectoryChanged;
  final String title;
  final String confirmText;
  final String cancelText;

  const DirectoryPicker(
      {Key key,
      this.onDirectoryChanged,
      this.title,
      this.confirmText,
      this.cancelText})
      : super(key: key);

  static show(BuildContext context,
      {Key key,
      ChooseCallback onDirectoryChanged,
      String title,
      String confirmText,
      String cancelText}) {
    return showDialog(
        context: context,
        builder: (_) => DirectoryPicker(
              title: title ?? "Directory Picker",
              confirmText: confirmText ?? "Confirm",
              cancelText: cancelText ?? "Cancel",
              onDirectoryChanged: onDirectoryChanged,
            ));
  }

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<DirectoryPicker> {
  Map<String, List<_FileItem>> _cachedDir = {};
  String _current;
  Queue<String> _previous = Queue();

  @override
  void initState() {
    super.initState();
    updateDirectory();
  }

  void updateDirectory({String current}) {
    NetUtils.get('/api/directory', params: {"current": current}).then((result) {
      var response = jsonDecode(result);
      if (response is ResponseBean || response['code'] == 0) {
        Scaffold.of(context).showSnackBar(
          SnackBar(content: Text(response.msg)),
        );
        return;
      }
      var data = response['data'];
      String current = data['current'];
      var directory = (data['directory'] as List)
          .map((d) => _FileItem(name: d['name'], path: d['path']))
          .toList(growable: false);
      _cachedDir[current] = directory;
      refreshCurrent(current);
    });
  }

  void refreshCurrent(String current) {
    if (!mounted) {
      return;
    }
    setState(() {
      if (_current != null && _current != current) {
        _previous.add(_current);
      }
      _current = current;
    });
  }

  @override
  Widget build(BuildContext context) {
    var actions = <Widget>[];
    if (_previous.isNotEmpty) {
      actions.add(IconButton(
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              icon: Icon(
                Icons.arrow_back,
                size: 20,
              ),
              onPressed: handleBack)
          .pointer);
    }
    actions.add(IconButton(
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      icon: Icon(Icons.refresh),
      onPressed: handleRefresh,
    ).pointer);
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
          width: 400,
          padding: EdgeInsets.only(top: 8, left: 8),
          color: Colors.white,
          child: ListTile(
            title: Text(widget.title ?? 'Directory Picker'),
            subtitle: Text(_current ?? '', overflow: TextOverflow.ellipsis),
            trailing: Wrap(children: actions),
          )),
      contentPadding: EdgeInsets.zero,
      actions: <Widget>[
        FlatButton(
          child: Text(widget.confirmText ?? 'Confirm'),
          onPressed: () {
            if (widget.onDirectoryChanged != null) {
              widget.onDirectoryChanged(_current);
            }
            Navigator.pop(context);
          },
        ),
        FlatButton(
          child: Text(widget.cancelText ?? 'Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
      content: SizedBox(
          height: 300,
          width: 400,
          child: _current == null
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: ListBody(
                    children: _cachedDir[_current]
                        .map(
                          (f) => SimpleDialogOption(
                            onPressed: () => handleFolderClick(f.path),
                            child: Text(f.name),
                          ),
                        )
                        .toList(growable: false),
                  ),
                )),
    );
  }

  void handleFolderClick(String path) {
    if (_cachedDir.containsKey(path)) {
      refreshCurrent(path);
      return;
    }
    updateDirectory(current: path);
  }

  void handleBack() {
    setState(() {
      _current = _previous.removeLast();
    });
  }

  void handleRefresh() {
    updateDirectory(current: _current);
  }
}

class _FileItem {
  final String name;
  final String path;

  _FileItem({this.name, this.path});
}

typedef ChooseCallback = void Function(String directory);
