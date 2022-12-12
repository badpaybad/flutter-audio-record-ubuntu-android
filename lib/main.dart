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
  runApp(MyAppUi());
}

class MyAppUi extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyAppUiState();
  }
}

class MyAppUiState extends State<MyAppUi> {
  MessageBus _messageBus;

  bool _canManipulateFile = false;

  MyAppUiState() : _messageBus = MessageBus() {
    _messageBus!.Subscribe(MessageBus.Channel_CurrentAudio_State,
        "MyAppUiState/AudioSegmentManagementUiState", (data) async {
      var type = data["type"].toString();

      if (type == "File") {
        _canManipulateFile = true;
        setState(() {});
      }
      if (type == "State") {}
      if (type == "Reset") {
        _canManipulateFile = false;
        setState(() {});
      }
    });
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
        //await run();
      });
    }

    return MaterialApp(
        builder: (_, Widget? child) => OKToast(child: child!),
        home: Scaffold(
          //resizeToAvoidBottomInset: false,
          body: SafeArea(
              child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(15, 5, 15, 13),
                //margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
                child: Row(
                  children: [
                    // ElevatedButton(
                    //   onPressed: () async {},
                    //   child: Text('From file ...'),
                    // ),
                    Text(' Mic: '),
                    MicrecorderUi(_messageBus),
                  ],
                ),
              ),
              Expanded(
                  child: Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 3),
                child: AudioSegmentManagementUi(_messageBus),
              )
              ),
            ],
          )),
        ));
  }
}

class TestAsyncAwait {
  Future<bool> nau_nuoc() async {
    try {
      await Future.delayed(Duration(seconds: 5));
      return true;
    } catch (ex) {
      return false;
    }
  }

  Future<bool> cat_gia_vi() async {
    try {
      await Future.delayed(Duration(seconds: 1));
      return true;
    } catch (ex) {
      return false;
    }
  }

  Future<bool> cat_rau() async {
    try {
      await Future.delayed(Duration(seconds: 1));
      return true;
    } catch (ex) {
      return false;
    }
  }

  Future<bool> bo_my() async {
    try {
      await Future.delayed(Duration(seconds: 1));
      return true;
    } catch (ex) {
      return false;
    }
  }

  Future<bool> tron_deu() async {
    try {
      await Future.delayed(Duration(seconds: 1));
      return true;
    } catch (ex) {
      return false;
    }
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
    var res = await Future.wait([step1, step2, step3, step4]);

    if (res.any((element) => element == false)) {
      print("Error");
    } else {
      var step5 = await tron_deu();
      print("done");
    }
    var dtstop = DateTime.now();
    print(dtstop);
    print(dtstop.millisecondsSinceEpoch - dtsart.millisecondsSinceEpoch);
  }
}
