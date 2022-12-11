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
  MessageBus _messageBus;

  MyApp({super.key}) : _messageBus = MessageBus() {}

  Future<void> nau_nuoc() async {
    await Future.delayed(Duration(seconds: 5));
  }

  Future<void> cat_gia_vi() async {
    await Future.delayed(Duration(seconds: 1));
  }

  Future<void> cat_rau() async {
    await Future.delayed(Duration(seconds: 1));
  }

  Future<void> bo_my() async {
    await Future.delayed(Duration(seconds: 1));
  }

  Future<void> tron_deu() async {
    await Future.delayed(Duration(seconds: 1));
  }

  Future<void> run() async {
    var dtsart = DateTime.now();
    print(dtsart);
    var step1 = nau_nuoc(); //var step1= await nau_nuoc();
    var step2 = cat_gia_vi(); // neu de await tung` line 1 thi
    var step3 = cat_rau(); // se ko phai la dong thoi
    var step4 = bo_my();
    // var listWaitAll=[step1,step2,step3,step4];
    // for(var t in listWaitAll){
    //   await t;
    // }
    //sau khi start concurrent het cac job
    // //-> done all task can thi moi dc tron_deu de an
    await Future.wait([step1, step2, step3, step4]);//similar and better to for ... listWaitAll { await t above
    var step5 = await tron_deu();
    var dtstop = DateTime.now();
    print(dtstop);
    print("done");
    print(dtstop.millisecondsSinceEpoch - dtsart.millisecondsSinceEpoch);
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
      }).whenComplete(() async {
        await run();
      });
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
