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
    speechEnabled =   await speechToText.initialize();
    
    print("initialize speech recognition ${speechToText.isListening}");
    createPorcupineManager();
    // await speechToText.listen(onResult: onSpeechResult);

    notifyListeners();
  }

  void createPorcupineManager() async {
    try {
      _porcupineManager =
          await PorcupineManager.fromKeywords(["picovoice"], wakeWordCallback);
      await _startProcessing();
    } on PvError catch (err) {
      // handle porcupine init error
      print("Porcupine error!! $err");
    }
  }

  Future<void> _startProcessing() async {
    try {
      await _porcupineManager?.start();
      print("WORKING");
    } on PvAudioException catch (ex) {
      print("Failed to start audio capture: ${ex.message}");
    }
  }

  void wakeWordCallback(int keywordIndex) {
    if (keywordIndex >= 0) {
      print("TRIGERED KEYWORD");
      SystemSound.play(SystemSoundType.click);

      startListening();
    }
  }

  void onSpeechResult(
    SpeechRecognitionResult result,
  ) {
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

    // notifyListeners();
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void stopListening() async {
    await speechToText.stop();
    notifyListeners();
  }
}
