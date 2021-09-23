import 'package:flutter/material.dart';
import 'package:fluttermqttnew/modules/core/models/MQTTAppState.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MQTTManager extends ChangeNotifier {
  // Private instance of client
  MQTTAppState _currentState = MQTTAppState();
  MqttBrowserClient? _client;
  late String _identifier;
  String? _host;
  String _topic = "sonoff";
  bool isTurnedOn = false;

  void initializeMQTTClient({
    required String host,
    required String identifier,
  }) {
    // Save the values
    _identifier = identifier;
    _host = host;

    _client = MqttBrowserClient("ws://" + host, _identifier);

    _client!.port = 8000;
    _client!.keepAlivePeriod = 20;
    // _client!.secure = false;
    _client!.onDisconnected = onDisconnected;
    _client!.logging(on: true);
    _client!.websocketProtocols = ['mqtt'];
    _client!.server += "/mqtt";

    /// Add the successful connection callback
    _client!.onConnected = onConnected;
    // _client!.onSubscribed = onSubscribed;
    _client!.onUnsubscribed = onUnsubscribed;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(_identifier)
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

      // on initialization send message to getstate and receive response
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addString("0");
      _client!.publishMessage(
          "unifai/light/event/getstate", MqttQos.exactlyOnce, builder.payload!);

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
    } on Exception catch (e) {
      print('EXAMPLE::client exception - $e');
      disconnect();
    }
  }

  void disconnect() {
    print('Disconnected');
    _client!.disconnect();
  }

  void publish() {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    String message = "";
    if (isTurnedOn)
      message = "0";
    else
      message = "1";
    builder.addString(message);
    _client!.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload!);
    _client!.publishMessage("unifai/light/event/changestate",
        MqttQos.exactlyOnce, builder.payload!);
    isTurnedOn = !isTurnedOn;

    notifyListeners();
  }

  /// The subscribed callback
  // void onSubscribed(String topic) {
  //   print('EXAMPLE::Subscription confirmed for topic $topic');
  //   _currentState
  //       .setAppConnectionState(MQTTAppConnectionState.connectedSubscribed);
  //   updateState();
  // }

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

  // void subScribeTo(String topic) {
  //   // Save topic for future use
  //   _topic = topic;
  //   _client!.subscribe(topic, MqttQos.atLeastOnce);
  // }

  /// Unsubscribe from a topic
  // void unSubscribe(String topic) {
  //   _client!.unsubscribe(topic);
  // }

  /// Unsubscribe from a topic
  // void unSubscribeFromCurrentTopic() {
  //   _client!.unsubscribe(_topic);
  // }

  void updateState() {
    //controller.add(_currentState);
    notifyListeners();
  }
}
