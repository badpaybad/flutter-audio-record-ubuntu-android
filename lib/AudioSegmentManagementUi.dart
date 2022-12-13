import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

//https://flutterawesome.com/flutter-audio-cutter-package-for-flutter/
//import 'package:flutter_audio_cutter/audio_cutter.dart';

//https://pub.dev/packages/flutter_audio_capture
//import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:path_provider/path_provider.dart';

//https://pub.dev/packages/just_audio
import 'package:just_audio/just_audio.dart';
import 'package:oktoast/oktoast.dart';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

//import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:easy_folder_picker/FolderPicker.dart';
import 'MessageBus.dart';
import 'Shared.dart';

class AudioSegmentManagementUi extends StatefulWidget {
  MessageBus _messageBus;

  AudioSegmentManagementUi(MessageBus msgBus, {super.key})
      : _messageBus = msgBus {}

  @override
  State<StatefulWidget> createState() {
    return AudioSegmentManagementUiState(_messageBus);
  }
}

class AudioSegmentManagementUiState extends State<AudioSegmentManagementUi> {
  MessageBus _messageBus;
  int _currentAudioDuration = 0;
  String _currentAudioPathFile = "";

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
        _currentAudioPathFile = filePath;
        var info = await MetadataRetriever.fromFile(File(filePath));
        _currentAudioDuration = info.trackDuration ?? 0;
        _playAudioFile(filePath);

        listAudioSegment = [];

        listAudioSegment
            .add(AudioSegmentItem(from: 0, to: _currentAudioDuration));

        if (this.mounted == true) setState(() {});
      }

      if (type == "Duration") {
        _currentAudioDuration = data["data"];
        if (this.mounted == true) setState(() {});
      }

      if (type == "Reset") {
        _canManipulateFile = false;
        if (this.mounted == true) setState(() {});
      }
    });
  }

  var listAudioSegment = <AudioSegmentItem>[];

  final ScrollController _listViewController = ScrollController();

  @override
  Widget build(BuildContext context) {
    //
    return _canManipulateFile
        ? _buildView()
        : GestureDetector(
            onTap: () {
              showToast("Please record you voice first");
            },
            child: AbsorbPointer(
                child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                        Color.fromARGB(100, 200, 200, 200),
                        BlendMode.saturation),
                    child: _buildView())));
  }

  var _audioPlayingState = 0;

  Future<void> _playAudioFile(filepath,
      {int? fromMilisec, int? toMilisec}) async {
    _audioPlayingState = 1;
    if (this.mounted == true) setState(() {});
    try {
      final player = AudioPlayer();
      final duration = await player.setFilePath(filepath!);

      int clipFrom = 0;
      int clipTo = _currentAudioDuration;

      clipFrom = fromMilisec ?? 0;
      clipTo = toMilisec ?? _currentAudioDuration;

      if (fromMilisec != null || toMilisec != null) {
        player.setClip(
            start: Duration(milliseconds: clipFrom),
            end: Duration(milliseconds: clipTo));
      }

      await player.play();
      await player.stop();
      player.dispose();

      // print("${clipFrom} ${clipTo} ----");
    } catch (ex) {
      print("_playAudioFile warining");
      print(ex);
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _audioPlayingState = 0;
    if (this.mounted == true) setState(() {});
  }

  Widget _buildView() {
    return Row(
      children: [
        _buildListView(),
        _buildRightTools(),
      ],
    );
  }

  Widget _buildRightTools() {
    var alertReset = _buildAlertReset();
    var alertExport = _buildAlertExport();
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 0, 20, 2),
      child: Column(
        children: [
          ButtonAnimateIconUi(
            toolTipText: "Add segment",
            inkDecoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black87,
                  width: 2.0,
                ),
                shape: BoxShape.circle,
                color: Colors.orange),
            iconFrom: Icons.add_box,
            iconTo: Icons.add,
            iconSize: 24.0,
            onPressed: () async {
              listAudioSegment
                  .add(AudioSegmentItem(filepath: _currentAudioPathFile));

              if (this.mounted == true) setState(() {});
              _listViewController.animateTo(
                _listViewController.position.maxScrollExtent + 1000,
                duration: const Duration(seconds: 2),
                curve: Curves.ease,
              );
            },
          ),
          const Text(" "),
          ButtonAnimateIconUi(
            toolTipText: "Export all",
            inkDecoration: BoxDecoration(
                border: Border.all(color: Colors.black87, width: 2.0),
                shape: BoxShape.circle,
                color: Colors.orange),
            iconFrom: Icons.add_to_home_screen,
            iconTo: Icons.arrow_forward,
            iconSize: 32.0,
            onPressed: () async {
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (ctx) {
                    return alertExport;
                  });
            },
          ),
          const Text(" "),
          const Text(" "),
          ButtonAnimateIconUi(
            key: UniqueKey(),
            toolTipText: "Reset",
            onPressed: () async {
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (ctx) {
                    return alertReset;
                  });
            },
            iconFrom: Icons.ac_unit,
            iconTo: Icons.access_time,
            inkDecoration: BoxDecoration(
              border: Border.all(color: Colors.orange, width: 2.0),
              color: Colors.redAccent,
              shape: BoxShape.rectangle,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 15, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ButtonAnimateIconUi(
                  onPressed: () async {
                    var type = _data?["type"]?.toString();
                    if (type == "File") {
                      var filepath = _data["data"]?.toString();
                      await _playAudioFile(filepath);
                    }
                  },
                  iconSize: 32.0,
                  inkDecoration: BoxDecoration(
                    border: Border.all(color: Colors.black87, width: 2.0),
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                Center(
                  child: Text(
                      "$_currentAudioDuration miliseconds ~ ${_currentAudioDuration / 1000} seconds"),
                ),
              ],
            ),
          ),
          Expanded(
              child: Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 15, 2),
            child: ListView.builder(
                controller: _listViewController,
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: listAudioSegment.length,
                itemBuilder: (BuildContext context, int idx) {
                  var data = listAudioSegment[idx];
                  return Row(
                    key: UniqueKey(),
                    children: [
                      ButtonAnimateIconUi(
                        toolTipText: "Play croped",
                        onPressed: () async {
                          var dataToPlay = listAudioSegment[idx];

                          _playAudioFile(_currentAudioPathFile,
                              fromMilisec: dataToPlay.FromMilisec,
                              toMilisec: dataToPlay.ToMilisec);
                        },
                        fromMilisec: data.FromMilisec,
                        toMilisec: data.ToMilisec,
                      ),
                      const Text(" "),
                      Flexible(
                        child: TextFormField(
                          validator: (val) {
                            var tempFrom = int.tryParse(val ?? "0") ?? 0;
                            var dataToTest = listAudioSegment[idx];

                            if (dataToTest.ToMilisec <= tempFrom) {
                              return "From must less than To";
                            }

                            return null;
                          },
                          onChanged: (val) {
                            data.FromMilisec = int.tryParse(val ?? "0") ?? 0;
                            //if (this.mounted) setState(() {});
                          },
                          initialValue: data.FromMilisec.toString(),
                          // controller: TextEditingController(
                          //     text: data.FromMilisec.toString()),
                          decoration: const InputDecoration(
                              //hintText: "From sec",
                              labelText: "From Milisec",
                              border: UnderlineInputBorder()),
                        ),
                      ),
                      const Text("    "),
                      const Text("    "),
                      Flexible(
                        child: TextFormField(
                          validator: (val) {
                            var tempTo = int.tryParse(val ?? "0") ?? 0;
                            var dataToTest = listAudioSegment[idx];

                            if (dataToTest.FromMilisec <= tempTo) {
                              return "From must less than To";
                            }
                            return null;
                          },
                          onChanged: (val) {
                            data.ToMilisec = int.tryParse(val ?? "0") ?? 0;
                            //if (this.mounted) setState(() {});
                          },
                          initialValue: data.ToMilisec.toString(),
                          // controller: TextEditingController(
                          //     text: data.ToMilisec.toString()),
                          decoration: const InputDecoration(
                              //hintText: "To sec",
                              labelText: "To Milisec",
                              border: UnderlineInputBorder()),
                        ),
                      ),
                      ButtonAnimateIconUi(
                        iconFrom: Icons.disabled_by_default,
                        iconTo: Icons.disabled_by_default_outlined,
                        iconSize: 24.0,
                        onPressed: () async {
                          listAudioSegment.remove(listAudioSegment[idx]);
                          if (this.mounted == true) setState(() {});
                        },
                      ),
                      const Text("    "),
                    ],
                  );
                }),
          )),
        ],
      ),
    );
  }

  AlertDialog _buildAlertReset() {
    return AlertDialog(
      title: Text("Reset all"),
      content: Text("All segment will clear, you have to do from begin"),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel")),
        TextButton(
            onPressed: () async {
              showToast("Reset");

              listAudioSegment = [];

              await Future.delayed(Duration(milliseconds: 500));

              _messageBus.Publish(MessageBus.Channel_CurrentAudio_State,
                  {"type": "Reset", "data": "", "state": -1});

              if (this.mounted == true) setState(() {});
              Navigator.pop(context);
            },
            child: Text("Ok - reset")),
      ],
    );
  }

  AlertDialog _buildAlertExport() {
    return AlertDialog(
      title: Text("Export all"),
      content: Text("You will pick folder to save"),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel")),
        TextButton(
            onPressed: () async {
              if (listAudioSegment.any((s) => s.FromMilisec >= s.ToMilisec)) {
                showToast("From must be less than To",
                    duration: Duration(seconds: 3));
                return;
              }

              Directory dirToSave = await _pickDirectory();

              var fileOrgWav = _currentAudioPathFile + ".wav";

              await ffmpeg_m4a_to_wav(_currentAudioPathFile, fileOrgWav);

              for (AudioSegmentItem s in listAudioSegment) {
                double startPoint = s.FromMilisec / 1000;
                double endPoint = s.ToMilisec / 1000;

                var filePathToSave =
                    "${dirToSave.path}/audio_croped_${s.FromMilisec}_${s.ToMilisec}_${s.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0')}.wav";

                var result = await cropAudio(
                    fileOrgWav, filePathToSave, startPoint, endPoint);

                print(result);

                showToast(filePathToSave);
                await Future.delayed(Duration(seconds: 1));
              }

              File fileOrg = File(_currentAudioPathFile);
              await fileOrg
                  .copy("${dirToSave.path}/${getFileName(fileOrg.path)}");

              showToast("Saved all to: ${dirToSave.path}");

              _messageBus.Publish(MessageBus.Channel_CurrentAudio_State,
                  {"type": "Reset", "data": "", "state": -1});

              listAudioSegment = [];
              try {
                await File(_currentAudioPathFile).delete(recursive: true);
              } catch (ex) {}
              try {
                await File(fileOrgWav).delete(recursive: true);
              } catch (ex) {}

              if (this.mounted == true) setState(() {});

              Navigator.pop(context);
            },
            child: Text("Ok - export")),
      ],
    );
  }

  String getFileName(String filePath) {
    return filePath.replaceAll("\\", "/").split('/').last;
  }

  Future<String?> ffmpeg_m4a_to_wav(String pathFileOrg, String outPath) async {
    var cmd = "-y -i \"$pathFileOrg\" \"$outPath\"";
    var r = await FFmpegKit.execute(cmd);
    return await r.getAllLogsAsString();
  }

  Future<String?> cropAudio(
      String pathFileOrg, String outPath, double start, double end) async {
    if (start < 0 || end < 0) {
      throw ArgumentError('The starting and ending points cannot be negative');
    }
    if (start > end) {
      throw ArgumentError(
          'The starting point cannot be greater than the ending point');
    }
    //final Directory dir = await getTemporaryDirectory();
    //final outPath = "${dir.path}/audio_cutter/output.mp3";
    //await File(outPath).create(recursive: true);

    // var cmd =
    //     "-y -i \"$pathFileOrg\" -vn -ss $start -to $end -ar 16k -ac 2 -b:a 96k -acodec copy $outPath";
    var cmd = "-y -i \"$pathFileOrg\" -ss $start -to $end -c copy \"$outPath\"";

    var r = await FFmpegKit.execute(cmd);

    return await r.getAllLogsAsString();
  }

  Directory? selectedDirectory;

  Future<Directory> _pickDirectory() async {
    Directory directory = selectedDirectory ?? Directory(FolderPicker.rootPath);

    Directory? newDirectory = await FolderPicker.pick(
        allowFolderCreation: true,
        context: context,
        rootDirectory: directory,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))));

    selectedDirectory = newDirectory;

    return newDirectory ?? Directory(FolderPicker.rootPath);
  }
}

//     Expanded(
//       child: SingleChildScrollView(
//           controller: _listViewController,
//           padding: const EdgeInsets.fromLTRB(30, 0, 30, 2),
//           scrollDirection: Axis.vertical,
//           child: Column(
//             children: [
//               Row(children: [
//                 Expanded(
//                   child: SizedBox(
//                     //height: 300.0,
//                     child:
// null
//                   ),
//                 ),
//               ]),
//             ],
//           )),
//     ),
