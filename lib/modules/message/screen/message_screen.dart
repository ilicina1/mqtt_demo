import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttermqttnew/modules/core/managers/MQTTManager.dart';
import 'package:fluttermqttnew/modules/core/managers/speechToTextManager.dart';
import 'package:fluttermqttnew/modules/core/models/MQTTAppState.dart';
import 'package:fluttermqttnew/modules/core/widgets/status_bar.dart';
import 'package:fluttermqttnew/modules/helpers/screen_route.dart';
import 'package:fluttermqttnew/modules/helpers/status_info_message_utils.dart';
import 'package:fluttermqttnew/modules/settings/screen/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late MQTTManager _manager;
  late SpeechToTextManager _speechManager;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      _configureAndConnect();
      _initializeSpeechRecognition();
      print("SchedulerBinding");
    });
  }

  void onSelectNotification(String? payload) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return SettingsScreen();
    }));
  }

  @override
  Widget build(BuildContext context) {
    _manager = Provider.of<MQTTManager>(context);
    _speechManager = Provider.of<SpeechToTextManager>(context);
    print("REBUILD WIDGET ${_speechManager.lastWords}");
    if (_speechManager.lastWords.length > 0) {
      _manager.onVoiceCommand(_speechManager.lastWords);
      _speechManager.lastWords = "";
    }

    bool isConnected = false;

    if (_manager.currentState.getAppConnectionState ==
        MQTTAppConnectionState.connected)
      isConnected = true;
    else
      isConnected = false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text(
            'Unifai',
            style: TextStyle(
              fontSize: 20,
              fontFamily: "Poppins",
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              color: Color(0xff01579B),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.0,
          // manual connection
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(SETTINGS_ROUTE);
                },
                child: Icon(
                  Icons.settings,
                  color: Color(0xff01579B),
                  size: 26.0,
                ),
              ),
            )
          ]),
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          height: MediaQuery.of(context).size.height,
          child: isConnected
              ? ListView(
                children: [
                  
                  Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBar(
                            statusMessage: prepareStateMessageFrom(
                                _manager.currentState.getAppConnectionState)),
                        Padding(
                          padding: const EdgeInsets.only(top: 50.0),
                          child: _buildSendButtonFrom(
                              _manager.currentState.getAppConnectionState),
                        ),


                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: SfRadialGauge(
                                axes: <RadialAxis>[
                                  RadialAxis(
                                    minimum: 16,
                                    maximum: 31,
                                    pointers: <GaugePointer>[
                                      RangePointer(
                                        // value: double.parse(_manager.temperatureValue == ""
                                        //     ? "16"
                                        //     : _manager.temperatureValue),
                                        cornerStyle: CornerStyle.bothCurve,
                                        width: 15,
                                        sizeUnit: GaugeSizeUnit.logicalPixel,
                                      ),
                                      MarkerPointer(
                                          onValueChanged: (double value) {
                                            _manager.temperatureChange(value.toInt());
                                          },
                                          // value: double.parse(_manager.temperatureValue == ""
                                          //     ? "16"
                                          //     : _manager.temperatureValue),
                                          value:
                                              _manager.temperatureIntValue.toDouble(),
                                          enableDragging: true,
                                          markerHeight: 34,
                                          markerWidth: 34,
                                          markerType: MarkerType.circle,
                                          color: Color(0xff01579B),
                                          borderWidth: 2,
                                          borderColor: Colors.white54)
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 30.0),
                              child: GestureDetector(
                                onTap: () => _manager.confirmNewTemperature(
                                    _manager.temperatureIntValue),
                                child: Container(
                                  width: 90,
                                  color: Color(0xff01579B),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                        child: Text(
                                      "Confirm",
                                      style: TextStyle(color: Colors.white),
                                    )),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Container(
                            child: Text(
                                'Room temperature is: ${_manager.temperatureValue} '),
                          ),
                        ),
                        // Container(
                        //   child: Text(''),
                        // ),
                      ],
                    ),
                ],
              )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatusBar(
                        statusMessage: prepareStateMessageFrom(
                            _manager.currentState.getAppConnectionState)),
                    RaisedButton(
                      color: Color(0xff01579B),
                      child: const Text(
                        'Connect',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Poppins",
                        ),
                      ),
                      onPressed: _manager.currentState.getAppConnectionState == MQTTAppConnectionState.disconnected
                          ? _configureAndConnect
                          : null, //
                    ),
                    Container(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSendButtonFrom(MQTTAppConnectionState state) {
    return Selector<MQTTManager, bool>(
      selector: (context, mqttMenager) => mqttMenager.isTurnedOn,
      builder: (context, isTurnedOn, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () => _publishMessage(),
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: isTurnedOn ? Color(0xffC1292E) : Color(0xff01579B),
            ),
            child: Icon(
              Icons.power_settings_new,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  void _publishMessage() {
    _manager.publish();
  }

  void _configureAndConnect() {
    _manager.initializeMQTTClient(host: "broker.hivemq.com", context: context);

    _manager.connect();
    print("ssssssss");
  }

  void _initializeSpeechRecognition() {
    _speechManager.initSpeech();
  }
}
