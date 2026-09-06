import 'package:AIAssistant/views/local_search_page.dart';

import '../views/locations_page.dart';
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
        Navigator.push(
          context,
            MaterialPageRoute(builder: (_) => const LocationsPage())
        );
        break;
      case 'weather':
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WeatherPage())
        );
        break;
      case 'local_search':
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LocalSearchPage())
        );
        break;
    }
  }

  static void back(BuildContext context) {
    Navigator.pop(context);
  }

}