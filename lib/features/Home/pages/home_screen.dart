import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final int _placesAdded = 12;
  final double _totalDistance = 24.5; // Example: in kilometers
  final int _totalCalories = 980; // Example: calories burned
  final List<Map<String, String>> _leaderboard = [
    {'name': 'Alice', 'points': '1200'},
    {'name': 'Bob', 'points': '1150'},
    {'name': 'Charlie', 'points': '1100'},
  ];
  final List<Map<String, String>> _favoritePlaces = [
    {'name': 'Library', 'category': 'Study'},
    {'name': 'Sports Complex', 'category': 'Fitness'},
    {'name': 'Cafeteria', 'category': 'Food'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Campus Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Places Added & Stats
              _buildStatCard("Places Added", "$_placesAdded",
                  HugeIcons.strokeRoundedPinLocation01),
              const SizedBox(height: 12),
              _buildStatCard(
                  "Total Distance Traveled",
                  "${_totalDistance.toStringAsFixed(1)} km",
                  HugeIcons.strokeRoundedRoad),
              const SizedBox(height: 12),
              _buildStatCard("Total Calories Burnt", "$_totalCalories kcal",
                  HugeIcons.strokeRoundedFire),

              const SizedBox(height: 20),

              // Leaderboard
              _buildSectionTitle("Leaderboard"),
              _buildLeaderboard(),

              const SizedBox(height: 20),

              // Favorite Places
              _buildSectionTitle("Favorite Places"),
              _buildFavoritePlaces(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Column(
      children: _leaderboard.map((entry) {
        return ListTile(
          leading: Icon(HugeIcons.strokeRoundedMedal01, color: Colors.orange),
          title: Text(entry['name']!),
          trailing: Text("${entry['points']} pts"),
        );
      }).toList(),
    );
  }

  Widget _buildFavoritePlaces() {
    return Column(
      children: _favoritePlaces.map((place) {
        return ListTile(
          leading: Icon(HugeIcons.strokeRoundedFavourite, color: Colors.red),
          title: Text(place['name']!),
          subtitle: Text(place['category']!),
        );
      }).toList(),
    );
  }
}
