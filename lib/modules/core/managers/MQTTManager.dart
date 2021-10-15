import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttermqttnew/modules/core/models/MQTTAppState.dart';
import 'package:fluttermqttnew/modules/message/screen/message_screen.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTManager extends ChangeNotifier {
  // Private instance of client

  MQTTAppState _currentState = MQTTAppState();
  MqttServerClient? _client;
  late String _identifier;
  String? _host;
  String _topic = "sonoff";
  bool isTurnedOn = false;
  String temperatureValue = "";
  int temperatureIntValue = 16;
  late BuildContext context;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  FlutterTts flutterTts = FlutterTts();
  bool isVoiceCommandEnabled = true;
  bool isVoiceAssistantEnabled = true;

  bool sensorState = false;

  void changeVoiceCommandState(bool value) {
    isVoiceCommandEnabled = value;
    notifyListeners();
  }

  void changeVoiceAssistantState(bool value) {
    isVoiceAssistantEnabled = value;
    notifyListeners();
  }

  void temperatureChange(int value) {
    temperatureIntValue = value;

    notifyListeners();
  }

  Future<void> confirmNewTemperature(int value) async {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    print(value);
    builder.addString(value.toString());
    await flutterTts.setSpeechRate(0.30);

    isVoiceAssistantEnabled
        ? await flutterTts
            .speak("The temperature is set to $value degrees Celsius")
        : null;
    _client!.publishMessage(
        "unifai/temp/event/settemp", MqttQos.exactlyOnce, builder.payload!);
  }

  void initializeMQTTClient({required String host, context}) {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    context = context;
    var initSetttings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: onSelectNotification);
    _host = host;
    var idRandom = generateRandomString(10);
    _client = MqttServerClient(_host!, idRandom);
    _client!.port = 1883;
    // _client!.keepAlivePeriod = 1;
    _client!.secure = false;
    _client!.onDisconnected = onDisconnected;
    _client!.logging(on: true);

    /// Add the successful connection callback
    _client!.onConnected = onConnected;
    // _client!.onSubscribed = onSubscribed;
    _client!.onUnsubscribed = onUnsubscribed;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(idRandom)
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        //.authenticateAs(username, password)// Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::hivemq client connecting....');
    _client!.connectionMessage = connMess;
  }

  showNotification() async {
    var android = new AndroidNotificationDetails('id', 'channel');
    var platform = new NotificationDetails(android: android);
    await flutterLocalNotificationsPlugin.show(
        0, 'Unifai', 'Test test', platform,
        payload: 'Welcome to the Unifai ');
  }

  String? get host => _host;
  MQTTAppState get currentState => _currentState;
  // Connect to the host
  void connect() async {
    assert(_client != null);
    try {
      print('EXAMPLE::hivemq start client connecting....');
      _currentState.setAppConnectionState(MQTTAppConnectionState.connecting);
      updateState();
      await _client!.connect();
      _client!.subscribe("unifai/light/event/state", MqttQos.atLeastOnce);
      // for temperature
      _client!.subscribe("unifai/temp/event/value", MqttQos.atLeastOnce);

      //for movement tracking
      _client!
          .subscribe("unifai/motion/event/sensorstate", MqttQos.atLeastOnce);
      // listen to unifai/light/event/state and changing state depending on message
      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message!);
        if (payload == "1")
          isTurnedOn = true;
        else if (payload == "0") {
          isTurnedOn = false;
          sensorState = false;
        } else {
          temperatureValue = payload;
        }
        if (recMess.payload.variableHeader!.topicName ==
            "unifai/motion/event/sensorstate") {
          if (!sensorState) {
            showNotification();
            sensorState = true;
          }
        }
        print(
            'Received message: $payload  ${c[0].payload.header} --- ${recMess.payload.variableHeader!.topicName}');
      });

      // on initialization send message to getstate and receive response
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addString("0");
      _client!.publishMessage(
          "unifai/light/event/getstate", MqttQos.exactlyOnce, builder.payload!);
      builder.addString("0");

      // get temperature
      _client!.publishMessage(
          "unifai/temp/event/gettemp", MqttQos.exactlyOnce, builder.payload!);

      new Timer.periodic(
          const Duration(minutes: 10),
          (Timer t) => _client!.publishMessage(
              "test/test", MqttQos.exactlyOnce, builder.payload!));
    } on Exception catch (e) {
      print('EXAMPLE::client exception - $e');
      disconnect();
    }
  }

  void onVoiceCommand(String value) {
    if (value.toLowerCase().contains("lights on")) publish("1");
    if (value.toLowerCase().contains("lights off")) publish("0");
  }

  void disconnect() {
    print('Disconnected');
    _client!.disconnect();
  }

  Future<void> publish([value]) async {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    String message = "";
    if (isTurnedOn)
      message = "0";
    else
      message = "1";
    print("value value: $value");
    builder.addString(value == null ? message : value);
    _client!.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload!);
    _client!.publishMessage("unifai/light/event/changestate",
        MqttQos.exactlyOnce, builder.payload!);
    await flutterTts.setSpeechRate(0.30);

    if (value == null) {
      if (message == "0") {
        isTurnedOn = false;
        isVoiceAssistantEnabled ? await flutterTts.speak("The lights are off") : null;
      } else {
        isTurnedOn = true;
        isVoiceAssistantEnabled ? await flutterTts.speak("The lights are on") : null;
      }
    } else {
      if (value == "0") {
        isTurnedOn = false;
      } else
        isTurnedOn = true;
      if (value == "0") {
        isVoiceAssistantEnabled ? await flutterTts.speak("The lights are off") : null;
      } else {
        isVoiceAssistantEnabled ? await flutterTts.speak("The lights are on") : null;
      }
    }

    notifyListeners();
  }

  void onUnsubscribed(String? topic) {
    print('EXAMPLE::onUnsubscribed confirmed for topic $topic');
    _currentState.clearText();
    _currentState
        .setAppConnectionState(MQTTAppConnectionState.connectedUnSubscribed);
    updateState();
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (_client!.connectionStatus!.returnCode ==
        MqttConnectReturnCode.noneSpecified) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    }
    _currentState.clearText();
    _currentState.setAppConnectionState(MQTTAppConnectionState.disconnected);
    updateState();
  }

  /// The successful connect callback
  void onConnected() {
    _currentState.setAppConnectionState(MQTTAppConnectionState.connected);
    updateState();
    print('EXAMPLE::hivemq client connected....');
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message!);
      _currentState.setReceivedText(pt);
      updateState();
      print(
          'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      print('');
    });
    print(
        'EXAMPLE::OnConnected client callback - Client connection was sucessful');
  }

  void updateState() {
    notifyListeners();
  }

  String generateRandomString(int len) {
    var r = Random();
    return String.fromCharCodes(
        List.generate(len, (index) => r.nextInt(33) + 89));
  }

  void onSelectNotification(String? payload) {
    openPage(context);
  }

  Future<void> openPage(context) async {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return MessageScreen();
    }));
    isVoiceAssistantEnabled ? await flutterTts.speak("Wellcome") : null;
  }
}
