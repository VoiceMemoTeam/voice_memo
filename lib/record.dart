import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:voice_memo/API/whisper_api.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

late Record audioRecord;
late AudioPlayer audioPlayer;
bool isRecording = false;
bool isPlaying = false;
String audioPath = '';
String? transcript;
late Future<Database> database;

class Transcript {
  final String audioPath;
  final String baseText;
  final String? summaryText;
  final String? cleanText;

  const Transcript({
    required this.audioPath,
    required this.baseText,
    this.summaryText,
    this.cleanText,
  });

  Map<String, dynamic> toMap() {
    return {
      'audioPath': audioPath,
      'baseText': baseText,
      'summaryText': summaryText,
      'cleanText': cleanText,
    };
  }
}

Future<void> newTranscript(Transcript transcript) async {
  final db = await database;

  await db.insert(
    'transcripts',
    transcript.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Transcript>> transcripts() async {
  final db = await database;

  final List<Map<String, dynamic>> maps = await db.query('transcripts');

  return List.generate(maps.length, (i) {
    return Transcript(
      audioPath: maps[i]['audioPath'] as String,
      baseText: maps[i]['baseText'] as String,
    );
  });
}

Future<String> get localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> get localFile async {
  final path = await localPath;
  return File('$path/${DateTime.now().toString()}.m4a');
}

Future<void> writeAudio(File audio) async {
  final file = await localFile;
  file.writeAsBytes(await audio.readAsBytes());
}

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});
  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioRecord = Record();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        await audioRecord.start();
        setState(() {
          isRecording = true;
          isPlaying = false;
          audioPath = '';
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    final db = openDatabase(
      join(await getDatabasesPath(), 'transcripts.db'),
      // When the database is first created, create a table.
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE transcripts(id INTEGER PRIMARY KEY AUTOINCREMENT, audioPath TEXT, baseText TEXT, summaryText TEXT, cleanText TEXT)',
        );
      },
      version: 1,
    );
    database = db;
    try {
      String? path = await audioRecord.stop();
      print(path);
      var audio = File(path!);
      writeAudio(audio);
      var newPath = await localFile;
      var req = await requestWhisper(path!, null);
      transcript = req;
      var newTrns = Transcript(audioPath: newPath.path, baseText: req);
      List<Transcript> debug = await transcripts();
      print(debug);
      newTranscript(newTrns);
      setState(() {
        isRecording = false;
        audioPath = path!;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlSource = UrlSource(audioPath);
      await audioPlayer.play(urlSource);
    } catch (e) {
      print('Error playing audio : $e');
    }
  }

  Future<void> stopPlaying() async {
    try {
      await audioPlayer.stop();
      setState(() {
        isPlaying = false;
      });
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: Text(isRecording ? 'Stop' : 'Record'),
            ),
            SizedBox(height: 25),
            if (audioPath.isNotEmpty)
              ElevatedButton(
                onPressed: isPlaying ? stopPlaying : playRecording,
                child: Text(isPlaying ? 'Stop Playback' : 'Play'),
              ),
            if (transcript != null) Text("$transcript"),
          ],
        ),
      ),
    );
  }
}
