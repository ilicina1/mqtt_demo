import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttermqttnew/modules/core/managers/MQTTManager.dart';
import 'package:fluttermqttnew/modules/core/models/MQTTAppState.dart';
import 'package:fluttermqttnew/modules/core/widgets/status_bar.dart';
import 'package:fluttermqttnew/modules/helpers/screen_route.dart';
import 'package:fluttermqttnew/modules/helpers/status_info_message_utils.dart';
import 'package:provider/provider.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late MQTTManager _manager;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      _configureAndConnect();
      print("SchedulerBinding");
    });
  }

  @override
  Widget build(BuildContext context) {
    _manager = Provider.of<MQTTManager>(context);

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
          // actions: <Widget>[
          //   Padding(
          //     padding: const EdgeInsets.only(right: 15.0),
          //     child: GestureDetector(
          //       onTap: () {
          //         Navigator.of(context).pushNamed(SETTINGS_ROUTE);
          //       },
          //       child: Icon(
          //         Icons.settings,
          //         color: Color(0xff01579B),
          //         size: 26.0,
          //       ),
          //     ),
          //   )
          // ]
          ),
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBar(
                  statusMessage: prepareStateMessageFrom(
                      _manager.currentState.getAppConnectionState)),
              _buildSendButtonFrom(_manager.currentState.getAppConnectionState),
              Container(
                child: Text(''),
              ),
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
        //return RaisedButton(
        //   color: Colors.green,
        //   disabledColor: Colors.grey,
        //   textColor: Colors.white,
        //   disabledTextColor: Colors.black38,
        //   child: Icon(
        //     Icons.power_settings_new,
        //   ),
        //   onPressed: () {
        //     _publishMessage();
        //   },
        // );
      },
    );
  }

  void _publishMessage() {
    _manager.publish();
  }

  void _configureAndConnect() {
    _manager.initializeMQTTClient(host: "broker.hivemq.com");
    _manager.connect();
  }
}
