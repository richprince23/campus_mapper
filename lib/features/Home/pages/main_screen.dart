import 'package:campus_mapper/core/components/navbar.dart';
import 'package:campus_mapper/features/Explore/pages/expore_screen.dart';
import 'package:campus_mapper/features/Home/pages/home_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final kPages = [HomeScreen(), ExploreScreen(), Container(), Container()];

  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: kPages[_currentPage],
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
