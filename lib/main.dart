import 'package:campus_mapper/core/custom_theme.dart';
import 'package:campus_mapper/features/Home/pages/main_screen.dart';
import 'package:campus_mapper/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Campus Mapper",
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Use dark or light theme based on system setting.
      themeMode: ThemeMode.system,
      home: MainScreen(),
    );
  }
}
