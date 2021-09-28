import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttermqttnew/modules/core/managers/speechToTextManager.dart';
import 'package:provider/provider.dart';

import 'modules/core/managers/MQTTManager.dart';
import 'modules/helpers/screen_route.dart';
import 'modules/helpers/service_locator.dart';
import 'modules/message/screen/message_screen.dart';
import 'modules/settings/screen/settings_screen.dart';

void main() {
  setupLocator();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(MyApp());
}

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       home: MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key? key}) : super(key: key);

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   SpeechToText _speechToText = SpeechToText();
//   bool _speechEnabled = false;
//   String _lastWords = '';

//   @override
//   void initState() {
//     super.initState();
//     _initSpeech();
//   }

//   /// This has to happen only once per app
//   void _initSpeech() async {
//     _speechEnabled = await _speechToText.initialize();
//     setState(() {});
//   }

//   /// Each time to start a speech recognition session
//   void _startListening() async {
//     await _speechToText.listen(onResult: _onSpeechResult);
//     setState(() {});
//   }

//   /// Manually stop the active speech recognition session
//   /// Note that there are also timeouts that each platform enforces
//   /// and the SpeechToText plugin supports setting timeouts on the
//   /// listen method.
//   void _stopListening() async {
//     await _speechToText.stop();
//     setState(() {});
//   }

//   /// This is the callback that the SpeechToText plugin calls when
//   /// the platform returns recognized words.
//   void _onSpeechResult(SpeechRecognitionResult result) {
//     setState(() {
//       _lastWords = result.recognizedWords;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Speech Demo'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Container(
//               padding: EdgeInsets.all(16),
//               child: Text(
//                 'Recognized words:',
//                 style: TextStyle(fontSize: 20.0),
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.all(16),
//                 child: Text(
//                   // If listening is active show the recognized words
//                   _speechToText.isListening
//                       ? '$_lastWords'
//                       // If listening isn't active but could be tell the user
//                       // how to start it, otherwise indicate that speech
//                       // recognition is not yet ready or not supported on
//                       // the target device
//                       : _speechEnabled
//                           ? 'Tap the microphone to start listening...'
//                           : 'Speech not available',
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed:
//             // If not yet listening for speech start, otherwise stop
//             _speechToText.isNotListening ? _startListening : _stopListening,
//         tooltip: 'Listen',
//         child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
//       ),
//     );
//   }
// }




class MyApp extends StatelessWidget {
  
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: MQTTManager()),
        ChangeNotifierProvider.value(value: SpeechToTextManager()),
      ],
      child:MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          initialRoute: '/',
          routes: {
            '/': (BuildContext context) => MessageScreen(),
            SETTINGS_ROUTE: (BuildContext context) => SettingsScreen(),
          }),
    );
  }
  
}

