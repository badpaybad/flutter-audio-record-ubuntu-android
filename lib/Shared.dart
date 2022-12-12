import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

class ButtonAnimateIconUi extends StatefulWidget {
  VoidCallback? onPressed;
  double? fromSec;
  double? toSec;
  double? _iconSize;
  BoxDecoration? _inkDecoration;
  IconData? _iconFrom;
  IconData? _iconTo;
  String? _toolTipText;
  bool? _enable;

  ButtonAnimateIconUi(
      {VoidCallback? onPressed,
      double? fromSec,
      double? toSec,
      double? iconSize,
      IconData? iconFrom,
      IconData? iconTo,
      BoxDecoration? inkDecoration,
      String? toolTipText,
      bool? enable,
      super.key})
      : this.onPressed = onPressed,
        this.fromSec = fromSec,
        this.toSec = toSec,
        _enable = enable {
    _inkDecoration = inkDecoration;
    _iconSize = iconSize;
    if (iconFrom != null && iconTo == null) {
      iconTo = iconFrom;
    }
    if (iconFrom == null && iconTo != null) {
      iconFrom = iconTo;
    }
    _iconFrom = iconFrom ?? Icons.play_arrow;
    _iconTo = iconTo ?? Icons.pause;
    _toolTipText = toolTipText;
  }

  @override
  State<StatefulWidget> createState() {
    return ButtonAnimateIconUiState(onPressed, fromSec, toSec, _iconSize,
        _iconFrom, _iconTo, _toolTipText, _inkDecoration, _enable);
  }
}

class ButtonAnimateIconUiState extends State<ButtonAnimateIconUi> {
  VoidCallback? _onPressed;
  double? _from;
  double? _to;
  BoxDecoration? _inkDecoration;
  double? _iconSize = 32.0;
  IconData? _iconFrom = Icons.play_arrow;
  IconData? _iconTo = Icons.pause;
  String? _toolTipText;
  bool? _enable;

  ButtonAnimateIconUiState(
      VoidCallback? onPressed,
      double? from,
      double? to,
      double? iconSize,
      IconData? iconFrom,
      IconData? iconTo,
      String? toolTipText,
      BoxDecoration? inkDecoration,
      bool? enable)
      : _onPressed = onPressed,
        _enable = enable {
    _from = from;
    _to = to;
    _inkDecoration = inkDecoration;
    _iconSize = iconSize;
    _iconFrom = iconFrom;
    _iconTo = iconTo;
    _toolTipText = toolTipText;
  }

  var _playState = 0;

  @override
  Widget build(BuildContext context) {
    if (_toolTipText != null) {
      print(
          "ButtonAnimateIconUiState.build - $_toolTipText - enable - $_enable");
    }
    //var btn = ElevatedButton(
    //child:  Icon(_playState == 1 ? _iconTo : _iconFrom),
    var btn = IconButton(
      icon: Icon(_playState == 1 ? _iconTo : _iconFrom),
      iconSize: _iconSize,
      onPressed: (_enable == false)
          ? null
          : () async {
              _playState = 1;
              setState(() {});
              try {
                _onPressed!.call();
              } catch (ex) {
                print("ButtonPlayUiState:Error:");
                print(ex);
              }
              await Future.delayed(const Duration(milliseconds: 500));
              _playState = 0;
              setState(() {});
            },
    );

    var btnInk = _inkDecoration == null
        ? btn
        : Ink(
            decoration: _inkDecoration,
            child: btn,
          );

    var toolTipBtnInk = _toolTipText == null
        ? btnInk
        : Tooltip(
            message: _toolTipText,
            child: btnInk,
          );

    return toolTipBtnInk;
  }
}

class AudioSegmentItem {
  AudioSegmentItem({double from = 0, double to = 0, String filepath = ""}) {
    PathFile = filepath;
    FromSec = from;
    ToSec = to;
  }

  static AudioSegmentItem fromJson(Map<String, dynamic> val) {
    return AudioSegmentItem(
        from: val["FromSec"],
        to: val["ToSec"],
        filepath: val["PathFile"].toString());
  }

  static Map<String, dynamic> toJson(AudioSegmentItem val) {
    return {
      "PathFile": val.PathFile,
      "FromSec": val.FromSec,
      "ToSec": val.ToSec
    };
  }

  String PathFile = "";
  double FromSec = 0.0;
  double ToSec = 0.0;
}
