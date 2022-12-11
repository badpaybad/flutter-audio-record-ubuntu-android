import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

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

class AudioSegmentManagementUi extends StatefulWidget {
  MessageBus _messageBus;

  AudioSegmentManagementUi(MessageBus msgBus, {super.key})
      : _messageBus = msgBus {}

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return AudioSegmentManagementUiState(_messageBus);
  }
}

class AudioSegmentManagementUiState extends State<AudioSegmentManagementUi> {
  MessageBus _messageBus;
  var _logs = "";

  dynamic _data;

  var _canManipulateFile = false;

  AudioSegmentManagementUiState(MessageBus msgBus) : _messageBus = msgBus {
    _messageBus!.Subscribe(
        MessageBus.Channel_CurrentAudio_State, "AudioSegmentManagementUiState",
        (data) async {
      _data = data;
      var type = data["type"].toString();

      _logs = jsonEncode(data);
      if (type == "File") {
        setState(() {
          _canManipulateFile = true;
        });
      }
      if (type == "State") {}
    });
  }

  var listAudioSegment = <AudioSegmentItem>[];

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                child: Text(
                  "|>",
                ),
                onPressed: _canManipulateFile == false
                    ? null
                    : () async {
                        var type = _data["type"]?.toString();
                        if (type == "File") {
                          var filepath = _data["data"]?.toString();
                          final player = AudioPlayer();
                          final duration = await player.setFilePath(filepath!);

                          await player.play();
                        }
                      },
              ),
            ],
          ),
          Row(children: [
            Expanded(
              child: SizedBox(
                //height: 300.0,
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: listAudioSegment.length,
                    itemBuilder: (BuildContext context, int idx) {
                      var data = listAudioSegment[idx];
                      return Row(
                        children: [
                          ElevatedButton(
                            child: Text("|>"),
                            onPressed: () async {},
                          ),
                          ElevatedButton(
                            child: Text("-"),
                            onPressed: () async {
                              listAudioSegment.remove(listAudioSegment[idx]);
                              setState(() {});
                            },
                          ),
                          Flexible(
                            child: TextFormField(
                              controller:TextEditingController(text: data.FromSec.toString()),
                              decoration: InputDecoration(
                                  //hintText: "From sec",
                                  labelText:"From sec",
                                  border: UnderlineInputBorder()
                              ),
                            ),
                          ),
                          Flexible(
                            child: TextFormField(
                              controller:TextEditingController(text: data.ToSec.toString()),
                              decoration: InputDecoration(
                                //hintText: "To sec",
                                  labelText:"To sec",
                                  border: UnderlineInputBorder()
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
              ),
            ),
          ]),
          ElevatedButton(
            child: Text("+"),
            onPressed: () async {
              listAudioSegment.add(AudioSegmentItem(filepath: "123"));

              setState(() {});
            },
          ),
          Text("Logs"),
          Text(_logs)
        ],
      ),
    );
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
