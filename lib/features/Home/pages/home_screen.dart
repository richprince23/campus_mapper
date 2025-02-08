import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildUserHeader(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildUserHeader(),
              // const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildLeaderboard(),
              const SizedBox(height: 24),
              _buildFavoritePlaces(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.person, size: 35, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Text(
          'John Doe',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.place,
          title: 'Places Added',
          value: '28',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.directions_walk,
          title: 'Distance',
          value: '142 km',
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.local_fire_department,
          title: 'Calories',
          value: '12,450',
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.emoji_events,
          title: 'Rank',
          value: '#5',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Leaderboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildLeaderboardItem('Jane Smith', '234 places', 1),
              const Divider(),
              _buildLeaderboardItem('Mike Johnson', '198 places', 2),
              const Divider(),
              _buildLeaderboardItem('Sarah Wilson', '165 places', 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(String name, String score, int position) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: position == 1 ? Colors.amber : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Text(
              '#$position',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: position == 1 ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  score,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritePlaces() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Favorite Places',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFavoritePlaceCard(
                'Central Park',
                'Nature',
                Icons.park,
                Colors.green,
              ),
              _buildFavoritePlaceCard(
                'City Library',
                'Study',
                Icons.local_library,
                Colors.blue,
              ),
              _buildFavoritePlaceCard(
                'Fitness Center',
                'Exercise',
                Icons.fitness_center,
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritePlaceCard(
    String name,
    String category,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                category,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
