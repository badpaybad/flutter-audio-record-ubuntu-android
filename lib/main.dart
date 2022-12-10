import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

//https://pub.dev/packages/just_audio
import 'package:just_audio/just_audio.dart';

// https://pub.dev/packages/microphone
import 'package:microphone/microphone.dart';

//https://flutterawesome.com/flutter-audio-cutter-package-for-flutter/
import 'package:flutter_audio_cutter/audio_cutter.dart';

//https://pub.dev/packages/flutter_audio_capture
import 'package:flutter_audio_capture/flutter_audio_capture.dart';

//https://stackoverflow.com/questions/70241682/flutter-audio-trim

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

import 'package:baseflow_plugin_template/baseflow_plugin_template.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path_provider/path_provider.dart';


void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

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
                  MicrecorderUi(),
                ],
              ),
              Text(
                "Your file",
                textDirection: TextDirection.ltr,
                style: TextStyle(color: Colors.red, fontSize: 32),
              ),
            ],
          )),
        ));
  }
}

class MicrecorderUi extends StatefulWidget {
  MicrecorderUi() {}

  @override
  State<MicrecorderUi> createState() {
    return MicrecorderUiState();
  }
}

class MicrecorderUiState extends State<MicrecorderUi> {
  var _workingDir = "";
  var _tempRecordedFromMicDir = "";

  MicrecorderUiState() {}

  FlutterAudioCapture? _micCapturer;

  int? audiorCapturer_state = 0;

  ElevatedButton? _btnMicCapStart;

  ElevatedButton? _btnMicCapStop;

  var listToRecorded = <double>[];

  @override
  void initSate() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _micCapturer = new FlutterAudioCapture();

    _btnMicCapStop = ElevatedButton(
      onPressed: audiorCapturer_state != 1
          ? null
          : () async {
              await _micCapturer!.stop();

              setState(() => audiorCapturer_state = 2);

              await saveRecorded();

              showToast("Stop record from mic: ${audiorCapturer_state}");
            },
      child: Text('Record - Stop'),
    );

    _btnMicCapStart = ElevatedButton(
      onPressed: (audiorCapturer_state == 1)
          ? null
          : () async {
              listToRecorded = <double>[];

              await _micCapturer!.start(listener, onError,
                  sampleRate: 16000, bufferSize: 3000);

              setState(() {
                audiorCapturer_state = 1;
              });
              showToast("Start record from mic: ${audiorCapturer_state}");
            },
      child: Text('Record - Start'),
    );

    return Container(
      child: Row(
        children: [_btnMicCapStart!, _btnMicCapStop!],
      ),
    );
  }

  // Callback function if device capture new audio stream.
  // argument is audio stream buffer captured through mictophone.
  // Currentry, you can only get is as Float64List.
  void listener(dynamic obj) {
    if (audiorCapturer_state == 1) {
      var buffer = Float64List.fromList(obj.cast<double>());
      listToRecorded.addAll(buffer.toList());
    }
  }

// Callback function if flutter_audio_capture failure to register
// audio capture stream subscription.
  void onError(Object e) {
    print(e);
  }

  Future<void> saveRecorded() async {
    var _workingDir = "";
    var _tempRecordedFromMicDir = "";
    Directory? appDocDirectory = await getExternalStorageDirectory();

    if (appDocDirectory == null) {
      appDocDirectory = await getApplicationDocumentsDirectory();
    }

    print(appDocDirectory);
    _workingDir = appDocDirectory!.path;

    _tempRecordedFromMicDir = "$_workingDir/temprecorded";

    var filepath = "$_tempRecordedFromMicDir/1.wav";

    await Directory(_tempRecordedFromMicDir).create(recursive: true);

    await save(filepath,listToRecorded.map((i) => i.toInt()).toList(),16000);

    print(filepath);
    showToast("Save to file : $filepath");

    final player = AudioPlayer();                   // Create a player
    final duration = await player.setFilePath( filepath);                 // Schemes: (https: | file: | asset: )
    await player.play();
  }


  Future<void> save(filepath, List<int> data, int sampleRate) async {
    //File recordedFile = File("/storage/emulated/0/recordedFile.wav");
    File recordedFile = File(filepath);
    var channels = 1;

    int byteRate = ((16 * sampleRate * channels) / 8).round();

    var size = data.length;

    var fileSize = size + 36;

    Uint8List header = Uint8List.fromList([
      // "RIFF"
      82, 73, 70, 70,
      fileSize & 0xff,
      (fileSize >> 8) & 0xff,
      (fileSize >> 16) & 0xff,
      (fileSize >> 24) & 0xff,
      // WAVE
      87, 65, 86, 69,
      // fmt
      102, 109, 116, 32,
      // fmt chunk size 16
      16, 0, 0, 0,
      // Type of format
      1, 0,
      // One channel
      channels, 0,
      // Sample rate
      sampleRate & 0xff,
      (sampleRate >> 8) & 0xff,
      (sampleRate >> 16) & 0xff,
      (sampleRate >> 24) & 0xff,
      // Byte rate
      byteRate & 0xff,
      (byteRate >> 8) & 0xff,
      (byteRate >> 16) & 0xff,
      (byteRate >> 24) & 0xff,
      // Uhm
      ((16 * channels) / 8).round(), 0,
      // bitsize
      16, 0,
      // "data"
      100, 97, 116, 97,
      size & 0xff,
      (size >> 8) & 0xff,
      (size >> 16) & 0xff,
      (size >> 24) & 0xff,
      ...data
    ]);
    return recordedFile.writeAsBytesSync(header, flush: true);
  }

}
