import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MQTTManager>(
      create: (context) => service_locator<MQTTManager>(),
      child: MaterialApp(
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
