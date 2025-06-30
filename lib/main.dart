import 'package:campus_mapper/core/custom_theme.dart';
import 'package:campus_mapper/features/Explore/providers/map_provider.dart';
import 'package:campus_mapper/features/Explore/providers/search_provider.dart';
import 'package:campus_mapper/features/Home/pages/main_screen.dart';
import 'package:campus_mapper/firebase_options.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort(); // init foreground task
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // use firebase emulator
  // if (kDebugMode) {
  //   await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  //   await FirebaseStorage.instance.useStorageEmulator('localhost', 5001);
  //   FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  //   log("Using emulator for Firebase services");
  // }

  // Initialize Supabase with your project URL and anon key
  // await Supabase.initialize(
  //   url: "https://ldwnikdoqijibgkwebgj.supabase.co",
  //   anonKey:
  //       "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxkd25pa2RvcWlqaWJna3dlYmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU3MzcwMzMsImV4cCI6MjA2MTMxMzAzM30.vH0YTnKzE3x8tFJ4odjxrLG43HU-cfWRMzSGieylbnI",
  //   authOptions: FlutterAuthClientOptions(
  //     autoRefreshToken: true,
  //     localStorage:
  //         SharedPreferencesLocalStorage(persistSessionKey: "_auth_token"),
  //   ),
  // );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Campus Mapper",
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // Use dark or light theme based on system setting.
        themeMode: ThemeMode.system,
        home: MainScreen(),
      ),
    );
  }
}
