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
            colorFilter: ColorFilter.mode(
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

    await Future.delayed(Duration(milliseconds: 500));
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
                      onPressed: ()async{
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
                                            toSec: 0.0),
                                        Text(" "),
                                        Flexible(
                                          child: TextFormField(
                                            controller: TextEditingController(
                                                text: data.FromSec.toString()),
                                            decoration: InputDecoration(
                                                //hintText: "From sec",
                                                labelText: "From sec",
                                                border: UnderlineInputBorder()),
                                          ),
                                        ),
                                        Text("    "),
                                        Flexible(
                                          child: TextFormField(
                                            controller: TextEditingController(
                                                text: data.ToSec.toString()),
                                            decoration: InputDecoration(
                                                //hintText: "To sec",
                                                labelText: "To sec",
                                                border: UnderlineInputBorder()),
                                          ),
                                        ),
                                        ButtonAnimateIconUi(
                                          iconFrom: Icons.disabled_by_default,
                                          iconTo: Icons.disabled_by_default_outlined,
                                          iconSize: 24.0,
                                          onPressed: () async {
                                            listAudioSegment
                                                .remove(listAudioSegment[idx]);
                                            setState(() {});
                                          },
                                        ),
                                        Text("    "),
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
                iconFrom: Icons.add_box,
                iconTo: Icons.add,
                iconSize: 24.0,
                onPressed: () async {
                  listAudioSegment.add(AudioSegmentItem(
                      filepath: "123", from: _random.nextDouble()));

                  setState(() {});
                  _listViewController.animateTo(
                    _listViewController.position.maxScrollExtent + 1000,
                    duration: Duration(seconds: 2),
                    curve: Curves.ease,
                  );
                },
              ),
              ButtonAnimateIconUi(
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

class ButtonAnimateIconUi extends StatefulWidget {
  VoidCallback onPressed;
  double? fromSec;
  double? toSec;
  double ? _iconSize;
  BoxDecoration ? _inkDecoration;
  IconData ? _iconFrom;
  IconData ? _iconTo;
  ButtonAnimateIconUi({onPressed, double? fromSec, double? toSec,double? iconSize,
    IconData ? iconFrom,
    IconData ? iconTo,
    BoxDecoration ? inkDecoration,
    super.key})
      : this.onPressed = onPressed,
        this.fromSec = fromSec,
        this.toSec = toSec {
    _inkDecoration=inkDecoration;
    _iconSize=iconSize;
    if (iconFrom!=null && iconTo==null){
      iconTo=iconFrom;
    }
    if (iconFrom==null && iconTo!=null){
      iconFrom=iconTo;
    }
    _iconFrom=iconFrom ?? Icons.play_arrow;
    _iconTo=iconTo?? Icons.pause;
  }

  @override
  State<StatefulWidget> createState() {
    return ButtonAnimateIconUiState(onPressed, fromSec, toSec, _iconSize,_iconFrom,_iconTo, _inkDecoration);
  }
}

class ButtonAnimateIconUiState extends State<ButtonAnimateIconUi> {
  VoidCallback _onPressed;
  double? _from;
  double? _to;
  BoxDecoration ? _inkDecoration;
  double ? _iconSize=32.0;
  IconData ? _iconFrom= Icons.play_arrow;
  IconData ? _iconTo= Icons.pause;
  ButtonAnimateIconUiState(VoidCallback onPressed, double? from, double? to,
      double ? iconSize,
      IconData ? iconFrom,
      IconData ?  iconTo,
      BoxDecoration ? inkDecoration)
      : _onPressed = onPressed {
    _from = from;
    _to = to;
    _inkDecoration=inkDecoration;
    _iconSize=iconSize;
    _iconFrom=iconFrom;
    _iconTo=iconTo;
  }

  var _playState = 0;
  @override
  Widget build(BuildContext context) {
    var btn= IconButton(
      icon: Icon( _playState == 1 ? _iconTo : _iconFrom),
      iconSize: _iconSize,
      onPressed: () async {
        _playState = 1;
        setState(() {});
        try {
          _onPressed!.call();
        }catch(ex){
          print("ButtonPlayUiState:Error:");
          print(ex);
        }
        await Future.delayed(Duration(milliseconds: 500));
        _playState = 0;
        setState(() {});
      },
    );
    if (_inkDecoration==null){
      return btn;
    }else{
      return Ink(
        decoration: _inkDecoration,
        child: btn,
      );
    }
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
