import '../views/weather_page.dart';
import 'package:flutter/material.dart';
import '../views/setting_page.dart';

class AppNavigator {

  static void navigate(BuildContext context, String id) {
    switch(id) {
      case "settings":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingPage())
        );
        break;
      case 'location':
        /*Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LocationPage(),
          ),
        );*/
        break;
      case 'weather':
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WeatherPage())
        );
        break;
    }
  }

  static void back(BuildContext context) {
    Navigator.pop(context);
  }

}