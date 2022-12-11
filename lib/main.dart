import 'dart:io';
import 'dart:typed_data';
import 'package:audio_cutter/MessageBus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
// https://pub.dev/packages/microphone
import 'package:microphone/microphone.dart';
//https://stackoverflow.com/questions/70241682/flutter-audio-trim
//import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
//import 'package:baseflow_plugin_template/baseflow_plugin_template.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oktoast/oktoast.dart';
import 'MicrecorderUi.dart';
import 'AudioSegmentManagementUi.dart';
import "MessageBus.dart";

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MessageBus  _messageBus;
  MyApp( {super.key}):_messageBus=MessageBus(){

  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      var asyncRequest = [
        Permission.location,
        Permission.camera,
        Permission.microphone,
        Permission.mediaLibrary,
        Permission.manageExternalStorage,
        Permission.storage,
        //add more permission to request here.
      ].request();

      asyncRequest.then((statuses) {
        for (final k in statuses.keys) {
          print(k);
          print(statuses[k]);
        }
      }).whenComplete(() async {});
    }

    return MaterialApp(
        builder: (_, Widget? child) => OKToast(child: child!),
        home: Scaffold(
          body: SafeArea(
              child: Column(
            children: [
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {},
                    child: Text('Choose file ..'),
                  ),
                  Text(' Mic: '),
                  MicrecorderUi(_messageBus),
                ],
              ),
              AudioSegmentManagementUi(_messageBus!),
            ],
          )),
        ));
  }
}
