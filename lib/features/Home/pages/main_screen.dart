import 'package:campus_mapper/core/components/navbar.dart';
import 'package:campus_mapper/features/Explore/pages/expore_screen.dart';
import 'package:campus_mapper/features/Explore/providers/map_provider.dart';
import 'package:campus_mapper/features/History/pages/history_screen.dart';
import 'package:campus_mapper/features/Home/pages/home_screen.dart';
import 'package:campus_mapper/features/Home/pages/profile_screen.dart';
import 'package:campus_mapper/features/Auth/providers/auth_provider.dart';
import 'package:campus_mapper/features/Preferences/providers/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final kPages = [
    const HomeScreen(),
    const ExploreScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  int _currentPage = 0;

  // void getCurrentLocation() {
  //   RouteService.getCurrentLocation().then((value) {
  //     if (value != null) {
  //       // Handle the current location
  //       print("Current Location: ${value.latitude}, ${value.longitude}");
  //     } else {
  //       print("Failed to get current location");
  //     }
  //   }).catchError((error) {
  //     print("Error getting current location: $error");
  //   });
  // }

  @override
  void initState() {
    super.initState();
    // Initialize preferences when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePreferences();
    });
  }

  void _initializePreferences() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefsProvider = Provider.of<PreferencesProvider>(context, listen: false);
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    
    if (authProvider.isLoggedIn) {
      prefsProvider.initializePreferences(authProvider.currentUser!.uid);
    }
    
    // Connect map provider to preferences
    mapProvider.setPreferencesProvider(prefsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentPage, children: kPages),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _currentPage,
        onItemSelected: (val) {
          setState(() {
            _currentPage = val;
          });
        },
      ),
    );
  }
}
