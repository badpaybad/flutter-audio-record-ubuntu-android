import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
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
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

import 'MessageBus.dart';
import 'Shared.dart';

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
  Random _random = Random();

  AudioSegmentManagementUiState(MessageBus msgBus) : _messageBus = msgBus {
    _messageBus!.Subscribe(
        MessageBus.Channel_CurrentAudio_State, "AudioSegmentManagementUiState",
        (data) async {
      _data = data;
      var type = data["type"].toString();
      if (type == "File") {
        _canManipulateFile = true;
        var filePath = data["data"].toString();

        //final player = AudioPlayer();
        //final duration = await player.setFilePath(filePath);

        var info = await MetadataRetriever.fromFile(File(filePath));

        _logs = info.trackDuration.toString();

        await _playAudioFile(filePath);

        setState(() {});
      }
      if (type == "State") {}

      if (type == "Reset") {
        _canManipulateFile = false;
        setState(() {});
      }
    });
  }

  var listAudioSegment = <AudioSegmentItem>[
    AudioSegmentItem(from: 1.0, to: 2.0),
    AudioSegmentItem(from: 3.0, to: 4.0),
    AudioSegmentItem(from: 6.0, to: 7.0),
    AudioSegmentItem(from: 8.0, to: 9.0)
  ];
  final ScrollController _listViewController = ScrollController();

  @override
  Widget build(BuildContext context) {
    //

    return _canManipulateFile
        ? _buildView()
        : ColorFiltered(
            colorFilter: const ColorFilter.mode(
                Color.fromARGB(100, 200, 200, 200), BlendMode.saturation),
            child: _buildView());
  }

  var _audioPlayingState = 0;

  Future<void> _playAudioFile(filepath) async {
    _audioPlayingState = 1;
    setState(() {});
    try {
      final player = AudioPlayer();
      final duration = await player.setFilePath(filepath!);

      await player.play();
    } catch (ex) {
      print("_playAudioFile");
      print(ex);
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _audioPlayingState = 0;
    setState(() {});
  }

  Widget _buildView() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(30, 0, 15, 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ButtonAnimateIconUi(
                      onPressed: () async {
                        print("ButtonAudioPlayUi with decoration ink");
                        var type = _data?["type"]?.toString();
                        if (type == "File") {
                          var filepath = _data["data"]?.toString();
                          await _playAudioFile(filepath);
                        }
                      },
                      iconSize: 32.0,
                      inkDecoration: BoxDecoration(
                        border: Border.all(color: Colors.indigo, width: 2.0),
                        color: Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                    controller: _listViewController,
                    padding: const EdgeInsets.fromLTRB(30, 0, 30, 2),
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
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
                                        ButtonAnimateIconUi(
                                          onPressed: () async {
                                            print("ButtonPlayUi no ink");
                                          },
                                          fromSec: 0.0,
                                          toSec: 0.0,
                                        ),
                                        const Text(" "),
                                        Flexible(
                                          child: TextFormField(
                                            controller: TextEditingController(
                                                text: data.FromSec.toString()),
                                            decoration: const InputDecoration(
                                                //hintText: "From sec",
                                                labelText: "From sec",
                                                border: UnderlineInputBorder()),
                                          ),
                                        ),
                                        const Text("    "),
                                        Flexible(
                                          child: TextFormField(
                                            controller: TextEditingController(
                                                text: data.ToSec.toString()),
                                            decoration: const InputDecoration(
                                                //hintText: "To sec",
                                                labelText: "To sec",
                                                border: UnderlineInputBorder()),
                                          ),
                                        ),
                                        ButtonAnimateIconUi(
                                          iconFrom: Icons.disabled_by_default,
                                          iconTo: Icons
                                              .disabled_by_default_outlined,
                                          iconSize: 24.0,
                                          onPressed: () async {
                                            listAudioSegment
                                                .remove(listAudioSegment[idx]);
                                            setState(() {});
                                          },
                                        ),
                                        const Text("    "),
                                      ],
                                    );
                                  }),
                            ),
                          ),
                        ]),
                      ],
                    )),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(5, 0, 30, 2),
          child: Column(
            children: [
              ButtonAnimateIconUi(
                inkDecoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.indigo,
                      width: 2.0,
                    ),
                    shape: BoxShape.circle,
                    color: Colors.orange),
                iconFrom: Icons.add_box,
                iconTo: Icons.add,
                iconSize: 24.0,
                onPressed: () async {
                  listAudioSegment.add(AudioSegmentItem(
                      filepath: "123", from: _random.nextDouble()));

                  setState(() {});
                  _listViewController.animateTo(
                    _listViewController.position.maxScrollExtent + 1000,
                    duration: const Duration(seconds: 2),
                    curve: Curves.ease,
                  );
                },
              ),
              ButtonAnimateIconUi(
                toolTipText: "Export all",
                inkDecoration: BoxDecoration(
                    border: Border.all(color: Colors.indigo, width: 2.0),
                    shape: BoxShape.circle,
                    color: Colors.orange),
                iconFrom: Icons.add_to_home_screen,
                iconTo: Icons.arrow_forward,
                iconSize: 32.0,
                onPressed: () async {
                  _messageBus.Publish(MessageBus.Channel_CurrentAudio_State,
                      {"type": "Reset", "data": ""});

                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
