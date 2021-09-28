import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttermqttnew/modules/core/models/MQTTAppState.dart';
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

  void initializeMQTTClient({
    required String host,
  }) {
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
    print('EXAMPLE::Mosquitto client connecting....');
    _client!.connectionMessage = connMess;
  }

  String? get host => _host;
  MQTTAppState get currentState => _currentState;
  // Connect to the host
  void connect() async {
    assert(_client != null);
    try {
      print('EXAMPLE::Mosquitto start client connecting....');
      _currentState.setAppConnectionState(MQTTAppConnectionState.connecting);
      updateState();
      await _client!.connect();
      _client!.subscribe("unifai/light/event/state", MqttQos.atLeastOnce);

      // listen to unifai/light/event/state and changing state depending on message
      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message!);
        if (payload == "1")
          isTurnedOn = true;
        else
          isTurnedOn = false;
        print('Received message:$payload  --');
      });

      // on initialization send message to getstate and receive response
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addString("0");
      _client!.publishMessage(
          "unifai/light/event/getstate", MqttQos.exactlyOnce, builder.payload!);
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

  void publish([value]) {
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
    isTurnedOn = !isTurnedOn;

    // notifyListeners();
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
    print('EXAMPLE::Mosquitto client connected....');
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
    //controller.add(_currentState);
    notifyListeners();
  }

  String generateRandomString(int len) {
    var r = Random();
    return String.fromCharCodes(
        List.generate(len, (index) => r.nextInt(33) + 89));
  }
}
