import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: onItemSelected,
        // selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedHome07),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedRoute02),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedClock01),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedUserCircle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
