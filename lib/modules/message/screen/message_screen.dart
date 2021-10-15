import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttermqttnew/modules/core/managers/MQTTManager.dart';
import 'package:fluttermqttnew/modules/core/managers/speechToTextManager.dart';
import 'package:fluttermqttnew/modules/core/models/MQTTAppState.dart';
import 'package:fluttermqttnew/modules/settings/screen/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:tuple/tuple.dart';

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
        title: Image.asset(
          "assets/images/unifai_logo.png",
          width: 82,
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 40,
          color: Color(0xff0B0B45),
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Voice commands enabled",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  child: SvgPicture.asset(
                    "assets/images/options.svg",
                    color: Colors.white,
                    width: 24,
                    height: 24,
                  ),
                  onTap: () async {
                    await showSlidingBottomSheet(
                      context,
                      resizeToAvoidBottomInset: false,
                      useRootNavigator: true,
                      builder: (context) {
                        return SlidingSheetDialog(
                          duration: const Duration(milliseconds: 400),
                          elevation: 8,
                          cornerRadius: 16,
                          snapSpec: SnapSpec(
                            snap: true,
                            snappings: [0.7],
                            positioning:
                                SnapPositioning.relativeToAvailableSpace,
                          ),
                          builder: (context, state) {
                            return SheetListenerBuilder(
                              builder: (context, state) {
                                return Material(
                                  color: Colors.white,
                                  child:
                                      Selector<MQTTManager, Tuple2<bool, bool>>(
                                    selector: (context, mqttMenager) => Tuple2(
                                        mqttMenager.isVoiceCommandEnabled,
                                        mqttMenager.isVoiceAssistantEnabled),
                                    builder: (context, data, child) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          left: 20.0,
                                          right: 20,
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text("Voice commands"),
                                                // SizedBox(height: 100),
                                                Transform.scale(
                                                  scale: .7,
                                                  child: CupertinoSwitch(
                                                    trackColor: Colors
                                                        .grey, // **INACTIVE STATE COLOR**
                                                    activeColor: Color(
                                                        0xff01579B), // **ACTIVE STATE COLOR**
                                                    value: data.item1,
                                                    onChanged: (bool value) {
                                                      print("value");
                                                      _manager
                                                          .changeVoiceCommandState(
                                                              value);
                                                      if (value == false)
                                                        _speechManager
                                                            .stopProcessing();
                                                      else
                                                        _speechManager
                                                            .startProcessing();
                                                    },
                                                  ),
                                                )
                                              ],
                                            ),
                                            Divider(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text("Voice assistant"),
                                                Transform.scale(
                                                  scale: .7,
                                                  child: CupertinoSwitch(
                                                    trackColor: Colors
                                                        .grey, // **INACTIVE STATE COLOR**
                                                    activeColor: Color(
                                                        0xff01579B), // **ACTIVE STATE COLOR**
                                                    value: data.item2,
                                                    onChanged: (bool value) {
                                                      _manager
                                                          .changeVoiceAssistantState(
                                                              value);
                                                    },
                                                  ),
                                                )
                                              ],
                                            ),
                                            Divider(),
                                            Image.asset(
                                              "assets/images/qr-code.png",
                                              width: 200,
                                              height: 200,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        alignment: Alignment.center,
        child: isConnected
            ? MediaQuery.of(context).orientation == Orientation.portrait
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          child: _buildSendButtonFrom(
                              _manager.currentState.getAppConnectionState),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Color(0xff65AFFF).withOpacity(0.2),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: SfRadialGauge(
                              axes: <RadialAxis>[
                                RadialAxis(
                                  minimum: 16,
                                  maximum: 31,
                                  annotations: <GaugeAnnotation>[
                                    GaugeAnnotation(
                                        widget: Container(
                                          child: Text(
                                            '${_manager.temperatureValue}°C',
                                            style: TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xff0B0B45),
                                              fontFamily: "Poppins",
                                            ),
                                          ),
                                        ),
                                        angle: 90,
                                        positionFactor: 0)
                                  ],
                                  pointers: <GaugePointer>[
                                    RangePointer(
                                      cornerStyle: CornerStyle.bothCurve,
                                      width: 15,
                                      sizeUnit: GaugeSizeUnit.logicalPixel,
                                    ),
                                    MarkerPointer(
                                        onValueChanged: (double value) {
                                          _manager
                                              .temperatureChange(value.toInt());
                                          _manager.confirmNewTemperature(
                                              _manager.temperatureIntValue);
                                        },
                                        value: _manager.temperatureIntValue
                                            .toDouble(),
                                        enableDragging: true,
                                        markerHeight: 34,
                                        markerWidth: 34,
                                        markerType: MarkerType.circle,
                                        color: Color(0xff01579B),
                                        borderWidth: 2,
                                        borderColor: Colors.white54),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Container(
                          child: _buildSendButtonFrom(
                              _manager.currentState.getAppConnectionState),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Color(0xff65AFFF).withOpacity(0.2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: SfRadialGauge(
                                  axes: <RadialAxis>[
                                    RadialAxis(
                                      minimum: 16,
                                      maximum: 31,
                                      annotations: <GaugeAnnotation>[
                                        GaugeAnnotation(
                                            widget: Container(
                                                child: Text(
                                                    '${_manager.temperatureValue}°C',
                                                    style: TextStyle(
                                                        fontSize: 25,
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            angle: 90,
                                            positionFactor: 0)
                                      ],
                                      pointers: <GaugePointer>[
                                        RangePointer(
                                          cornerStyle: CornerStyle.bothCurve,
                                          width: 15,
                                          sizeUnit: GaugeSizeUnit.logicalPixel,
                                        ),
                                        MarkerPointer(
                                            onValueChanged: (double value) {
                                              _manager.temperatureChange(
                                                  value.toInt());
                                              _manager.confirmNewTemperature(
                                                  _manager.temperatureIntValue);
                                            },
                                            value: _manager.temperatureIntValue
                                                .toDouble(),
                                            enableDragging: true,
                                            markerHeight: 34,
                                            markerWidth: 34,
                                            markerType: MarkerType.circle,
                                            color: Color(0xff01579B),
                                            borderWidth: 2,
                                            borderColor: Colors.white54),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child: Text(
                      "Lost connection to broker, please reconnect",
                      style: TextStyle(
                        color: Color(0xff0B0B45),
                        fontFamily: "Poppins",
                        fontSize: 24,
                      ),
                      textAlign:TextAlign.center,
                    ),

                  ),
                  RaisedButton(
                    color: Color(0xff01579B),
                    child: const Text(
                      'Reconnect',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                      ),
                    ),
                    onPressed: _manager.currentState.getAppConnectionState ==
                            MQTTAppConnectionState.disconnected
                        ? _configureAndConnect
                        : null, //
                  ),
                  Container(),
                ],
              ),
      ),
    );
  }

  Widget _buildSendButtonFrom(MQTTAppConnectionState state) {
    return Selector<MQTTManager, bool>(
      selector: (context, mqttMenager) => mqttMenager.isTurnedOn,
      builder: (context, isTurnedOn, child) {
        return Padding(
          padding: const EdgeInsets.all(50.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: () => _publishMessage(),
            child: Container(
              child: Image.asset(
                isTurnedOn
                    ? "assets/images/light_on.png"
                    : "assets/images/light_off.png",
              ),
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
