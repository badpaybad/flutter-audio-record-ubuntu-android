import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

//https://flutterawesome.com/flutter-audio-cutter-package-for-flutter/
//import 'package:flutter_audio_cutter/audio_cutter.dart';
//https://pub.dev/packages/flutter_audio_capture
//import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:path_provider/path_provider.dart';

//https://pub.dev/packages/just_audio
//import 'package:just_audio/just_audio.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'MessageBus.dart';
import 'Shared.dart';

class MicrecorderUi extends StatefulWidget {
  MessageBus _messageBus;

  MicrecorderUi(MessageBus msgBus, {super.key}) : _messageBus = msgBus {}

  @override
  State<MicrecorderUi> createState() {
    return MicrecorderUiState(_messageBus);
  }
}

class MicrecorderUiState extends State<MicrecorderUi> {
  int _counterGeneratedFile = 0;
  MessageBus _messageBus;

  MicrecorderUiState(MessageBus msgBus) : _messageBus = msgBus {}
  int audiorCapturer_state = 0;

  final FlutterSoundRecord _audioRecorder = FlutterSoundRecord();

  var isDisposed = false;
  var _recordStarted = DateTime.now();
  var _recordElapsed = 0;

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

  @override
  void initState() {
    super.initState();

    threadLoopToPublishState();
  }

  dynamic _buildAudioMessage(dynamic data, String type) {
    return {
      "type": type,
      "data": data,
      "state": audiorCapturer_state,
      "startAt": _recordStarted,
      "duration": _recordElapsed
    };
  }

  Future<void> threadLoopToPublishState() async {
    while (!isDisposed) {
      try {
        if (audiorCapturer_state == 1) {
          //var data = await _audioRecorder.getAmplitude();
          _recordElapsed = _recordElapsed + 100;
          _messageBus.Publish(MessageBus.Channel_CurrentAudio_State,
              _buildAudioMessage(_recordElapsed, "Duration"));
        }
      } finally {
        await Future.delayed(Duration(milliseconds: 100));
        //sleep(Duration(seconds:1));
      }
    }
  }

  Future<void> _startRecordFromMic() async {
    await _audioRecorder.start();
    bool isRecording = await _audioRecorder.isRecording();

    audiorCapturer_state = 1;
    _recordStarted = DateTime.now();
    _recordElapsed = 0;

    _messageBus!.Publish(MessageBus.Channel_CurrentAudio_State,
        _buildAudioMessage(audiorCapturer_state, "State"));

    if (this.mounted == true) setState(() {});

    showToast("Start record from mic: ${audiorCapturer_state}");
  }

  @override
  Widget build(BuildContext context) {
    var alertOverwrite = _buildAlertRecordOverwrite();
    return Container(
      child: Row(
        children: [
          Text(' Record voice from Mic: '),
          ButtonAnimateIconUi(
              toolTipText: "Start record",
              enable: audiorCapturer_state != 1,
              onPressed: () async {
                if (audiorCapturer_state == 0) {
                  _startRecordFromMic();
                } else {
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (ctx) {
                        return alertOverwrite;
                      });
                }
              },
              iconFrom: Icons.record_voice_over,
              inkDecoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 2.0),
                color: Colors.orangeAccent,
                shape: BoxShape.rectangle,
              ),
              key: UniqueKey()),
          const Text(" "),
          ButtonAnimateIconUi(
            key: UniqueKey(),
            toolTipText: "Stop record",
            enable: audiorCapturer_state == 1,
            onPressed: () async {
              final String? filepath = await _audioRecorder.stop();
              audiorCapturer_state = 2;
              showToast(
                  "Stop record from mic: $audiorCapturer_state $filepath");
              _messageBus.Publish(MessageBus.Channel_CurrentAudio_State,
                  _buildAudioMessage(filepath, "File"));

              if (this.mounted == true) setState(() {});
            },
            iconFrom: Icons.record_voice_over_outlined,
            inkDecoration: BoxDecoration(
              border: Border.all(color: Colors.orange, width: 2.0),
              color: Colors.orangeAccent,
              shape: BoxShape.rectangle,
            ),
          ),
        ],
      ),
    );
  }

  AlertDialog _buildAlertRecordOverwrite() {
    return AlertDialog(
      title: Text("Overwrite all after record"),
      content: Text("All segment will clear, you have to do from begin"),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel")),
        TextButton(
            onPressed: () async {
              _startRecordFromMic();

              Navigator.pop(context);
            },
            child: Text("Ok - overwrite")),
      ],
    );
  }

  Future<String> getFilePathToSave() async {
    _counterGeneratedFile = _counterGeneratedFile + 1;

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

    var filepath = "$tempRecordedFromMicDir/$_counterGeneratedFile $filename";

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
