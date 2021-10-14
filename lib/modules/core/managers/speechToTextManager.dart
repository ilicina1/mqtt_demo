import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:porcupine/porcupine_error.dart';
import 'package:porcupine/porcupine_manager.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextManager extends ChangeNotifier {
  SpeechToText speechToText = SpeechToText();
  bool speechEnabled = false;
  String lastWords = '';
  PorcupineManager? _porcupineManager;
  

  void initSpeech() async {
    createPorcupineManager();
    speechEnabled = await speechToText.initialize(debugLogging: true);

    print("initialize speech recognition ${speechEnabled}");

    notifyListeners();
  }

  void createPorcupineManager() async {
    try {
      _porcupineManager = await PorcupineManager.fromKeywords(
          ["picovoice"], wakeWordCallback,
          sensitivities: [0.9]);
      await startProcessing();
    } on PvError catch (err) {
      // handle porcupine init error
      print("Porcupine error!! $err");
    }
  }

  Future<void> startProcessing() async {
    try {
      await _porcupineManager?.start();
      print("WORKING");
    } on PvAudioException catch (ex) {
      print("Failed to start audio capture: ${ex.message}");
    }
  }
  Future<void> stopProcessing() async {
    try {
      await _porcupineManager?.stop();
      print("STOPED PORCUPINE");
    } on PvAudioException catch (ex) {
      print("Failed to start audio capture: ${ex.message}");
    }
  }

  Future<void> wakeWordCallback(int keywordIndex) async {
    if (keywordIndex >= 0) {
      print("TRIGERED KEYWORD");
      SystemSound.play(SystemSoundType.click);
      await _porcupineManager!.stop();

      startListening();
    }
  }

  Future<void> onSpeechResult(
    SpeechRecognitionResult result,
  ) async {
    print("lastwords2: ");

    lastWords = result.recognizedWords;
    print("lastwords: " + lastWords);

    notifyListeners();
  }

  void startListening() async {
    try {
      await speechToText.listen(onResult: onSpeechResult);
    } catch (e) {
      print("error listening speech to text: $e");
    }

    print("lastwords1: ");

    Timer(Duration(seconds: 3), () async {
      await stopListening();
      await startProcessing();
    });

    notifyListeners();
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  Future<void>  stopListening() async {
    await speechToText.stop();
    notifyListeners();
  }
}