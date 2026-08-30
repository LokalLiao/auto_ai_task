import 'package:flutter/material.dart';
import '../views/main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PersonalAiTaskApp());
}

class PersonalAiTaskApp extends StatelessWidget {
  const PersonalAiTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Personal AI Assistant',
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}