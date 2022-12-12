
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

//https://flutterawesome.com/flutter-audio-cutter-package-for-flutter/
import 'package:flutter_audio_cutter/audio_cutter.dart';

//https://pub.dev/packages/flutter_audio_capture
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:path_provider/path_provider.dart';

//https://pub.dev/packages/just_audio
import 'package:just_audio/just_audio.dart';

import 'package:oktoast/oktoast.dart';

import 'package:flutter_sound_record/flutter_sound_record.dart';

import 'MessageBus.dart';

class MicrecorderUi extends StatefulWidget {
  MessageBus _messageBus;

  MicrecorderUi(MessageBus msgBus, {super.key}) : _messageBus = msgBus {}

  @override
  State<MicrecorderUi> createState() {
    return MicrecorderUiState(_messageBus);
  }
}

class MicrecorderUiState extends State<MicrecorderUi> {
  int _counter = 0;
  MessageBus _messageBus;

  MicrecorderUiState(MessageBus msgBus) : _messageBus = msgBus {}
  int audiorCapturer_state = 0;

  ElevatedButton? _btnMicCapStart;

  ElevatedButton? _btnMicCapStop;

  final FlutterSoundRecord _audioRecorder = FlutterSoundRecord();

  var isDisposed = false;

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

  @override
  void initState() {
    super.initState();

     print("threadPublishState: starting ---------------------");
     threadPublishState();
     print("threadPublishState: started ----------------------");
  }


  Future<void> threadPublishState() async {
    while (!isDisposed) {
      if (audiorCapturer_state == 1) {
        var data = await _audioRecorder.getAmplitude();
        _messageBus
            .Publish(MessageBus.Channel_CurrentAudio_State, {"type": "Amplitude", "data": data});
      }
      await Future.delayed(Duration(seconds: 1));
      //sleep(Duration(seconds:1));
    }
  }

  @override
  Widget build(BuildContext context) {
    _btnMicCapStart = ElevatedButton(
      onPressed: (audiorCapturer_state == 1)
          ? null
          : () async {
              await _audioRecorder.start();
              bool isRecording = await _audioRecorder.isRecording();

              setState(() {
                audiorCapturer_state = 1;
              });

              _messageBus!.Publish(MessageBus.Channel_CurrentAudio_State,
                  {"type": "State", "data": audiorCapturer_state});

              showToast("Start record from mic: ${audiorCapturer_state}");
            },
      child: Text('Record - Start'),
    );

    _btnMicCapStop = ElevatedButton(
      onPressed: audiorCapturer_state != 1
          ? null
          : () async {
              final String? filepath = await _audioRecorder.stop();

              setState(() => audiorCapturer_state = 2);

              showToast(
                  "Stop record from mic: $audiorCapturer_state $filepath");

              _messageBus.Publish(MessageBus.Channel_CurrentAudio_State,
                  {"type": "State", "data": audiorCapturer_state});

              _messageBus.Publish(MessageBus.Channel_CurrentAudio_State,
                  {"type": "File", "data": filepath});


            },
      child: Text('Record - Stop'),
    );

    return Container(
      child: Row(
        children: [_btnMicCapStart!, _btnMicCapStop!],
      ),
    );
  }

  Future<String> getFilePathToSave() async {
    _counter = _counter + 1;

    final now = DateTime.now();
    var workingDir = "";
    var tempRecordedFromMicDir = "";
    Directory? appDocDirectory = await getExternalStorageDirectory();

    if (appDocDirectory == null) {
      appDocDirectory = await getApplicationDocumentsDirectory();
    }

    workingDir = appDocDirectory.path;

    print("workingDir");
    print(workingDir);

    tempRecordedFromMicDir = "$workingDir/temprecorded";

    await Directory(tempRecordedFromMicDir).create(recursive: true);

    var filename = now.toIso8601String().replaceAll(":", "_");

    var filepath = "$tempRecordedFromMicDir/$_counter $filename";

    return filepath;
  }

  Future<void> save_wav(filepath, List<int> data, int sampleRate) async {
    print(
        "Future<void> save(filepath, List<int> data, int sampleRate) async {");
    print(data);
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
