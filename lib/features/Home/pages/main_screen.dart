import 'package:campus_mapper/core/api/route_service.dart';
import 'package:campus_mapper/core/components/navbar.dart';
import 'package:campus_mapper/features/Explore/pages/expore_screen.dart';
import 'package:campus_mapper/features/History/pages/history_screen.dart';
import 'package:campus_mapper/features/Home/pages/home_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final kPages = [
    HomeScreen(),
    ExploreScreen(),
    EnhancedSearchScreen(),
    Container()
  ];

  int _currentPage = 0;

  void getCurrentLocation() {
    RouteService.getCurrentLocation().then((value) {
      if (value != null) {
        // Handle the current location
        print("Current Location: ${value.latitude}, ${value.longitude}");
      } else {
        print("Failed to get current location");
      }
    }).catchError((error) {
      print("Error getting current location: $error");
    });
  }

  @override
  void initState() {
    getCurrentLocation();
    super.initState();
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
