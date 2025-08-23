import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:campus_mapper/features/History/providers/user_history_provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:campus_mapper/features/Auth/providers/auth_provider.dart';

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
    return Consumer<UserHistoryProvider>(
      builder: (context, historyProvider, child) {
        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: CachedNetworkImageProvider(
                  Provider.of<AuthProvider>(context, listen: false)
                          .userPhotoURL ??
                      'https://www.gravatar.com/avatar/placeholder'),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Provider.of<AuthProvider>(context, listen: false)
                          .userDisplayName ??
                      'Campus Explorer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  _getRankTitle(_calculateUserRank(historyProvider.stats)),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getRankColor(
                        _calculateUserRank(historyProvider.stats)),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return Consumer<UserHistoryProvider>(
      builder: (context, historyProvider, child) {
        final stats = historyProvider.stats;

        // Calculate total places (visited + added + favorited)
        final placesVisited = stats['places_visited'] ?? 0;
        final placesAdded = stats['places_added'] ?? 0;
        final placesFavorited = stats['places_favorited'] ?? 0;
        final totalPlaces = placesVisited + placesAdded + placesFavorited;

        final totalDistance = stats['total_distance'] as double? ?? 0.0;
        final totalCalories = stats['total_calories'] as double? ?? 0.0;

        // Calculate user rank based on activity score
        final userRank = _calculateUserRank(stats);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              icon: HugeIcons.strokeRoundedLocation01,
              title: 'Places',
              value: totalPlaces.toString(),
              color: Colors.blue,
            ),
            _buildStatCard(
              icon: HugeIcons.strokeRoundedRoute03,
              title: 'Distance',
              value: _formatDistance(totalDistance),
              color: Colors.green,
            ),
            _buildStatCard(
              icon: HugeIcons.strokeRoundedFire,
              title: 'Calories',
              value: _formatCalories(totalCalories),
              color: Colors.orange,
            ),
            _buildStatCard(
              icon: Icons.emoji_events,
              title: 'Rank',
              value: '#$userRank',
              color: Colors.purple,
            ),
          ],
        );
      },
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
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(77)),
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
                  color: color.withAlpha(205),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Consumer<UserHistoryProvider>(
      builder: (context, historyProvider, child) {
        final stats = historyProvider.stats;
        final userRank = _calculateUserRank(stats);
        final rankTitle = _getRankTitle(userRank);
        final rankColor = _getRankColor(userRank);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Rank',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: rankColor.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: rankColor.withAlpha(77)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: rankColor.withAlpha(102),
                      shape: BoxShape.circle,
                      border: Border.all(color: rankColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '#$userRank',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rankTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: rankColor,
                          ),
                        ),
                        Text(
                          _getRankDescription(userRank),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _getRankIcon(userRank),
                    color: rankColor,
                    size: 30,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFavoritePlaces() {
    return Consumer<UserHistoryProvider>(
      builder: (context, historyProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Places',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: historyProvider.getRecentlyVisitedPlaces(limit: 10),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final recentPlaces = snapshot.data ?? [];

                  if (recentPlaces.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.explore,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start exploring to see your favorite places!',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentPlaces.length,
                    itemBuilder: (context, index) {
                      final place = recentPlaces[index];
                      return _buildFavoritePlaceCard(
                        place['place_name'] ?? 'Unknown Place',
                        place['category'] ?? 'Unknown',
                        _getCategoryIcon(place['category'] ?? ''),
                        _getCategoryColor(place['category'] ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
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

  /// Calculate user rank based on activity score
  int _calculateUserRank(Map<String, dynamic> stats) {
    // Calculate activity score based on different actions with different weights
    final placesAdded = (stats['places_added'] ?? 0) as int;
    final placesVisited = (stats['places_visited'] ?? 0) as int;
    final journeysCompleted = (stats['journeys_completed'] ?? 0) as int;
    final searchesPerformed = (stats['searches_performed'] ?? 0) as int;
    final placesFavorited = (stats['places_favorited'] ?? 0) as int;
    final totalDistance =
        (stats['total_distance'] as double? ?? 0.0) / 1000; // Convert to km

    // Weighted scoring system
    final activityScore = (placesAdded * 10) + // Adding places worth more
        (placesVisited * 3) + // Visiting places
        (journeysCompleted * 5) + // Completing journeys
        (searchesPerformed * 1) + // Searches (basic activity)
        (placesFavorited * 2) + // Favoriting places
        (totalDistance * 2).round(); // Distance bonus

    // Rank based on score ranges (can be adjusted)
    if (activityScore >= 1000) return 1; // Elite
    if (activityScore >= 500) return 2; // Expert
    if (activityScore >= 200) return 3; // Advanced
    if (activityScore >= 100) return 4; // Intermediate
    if (activityScore >= 50) return 5; // Active
    if (activityScore >= 20) return 6; // Beginner
    return 10; // Newcomer
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters == 0) return '0 km';

    final distanceInKm = distanceInMeters / 1000;
    if (distanceInKm < 1) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.toStringAsFixed(0)} km';
    }
  }

  String _formatCalories(double calories) {
    if (calories == 0) return '0 cal';
    if (calories < 1000) {
      return '${calories.toStringAsFixed(0)} cal';
    } else {
      return '${(calories / 1000).toStringAsFixed(1)}k cal';
    }
  }

  String _getRankTitle(int rank) {
    switch (rank) {
      case 1:
        return 'Elite Explorer';
      case 2:
        return 'Expert Navigator';
      case 3:
        return 'Advanced Adventurer';
      case 4:
        return 'Intermediate Walker';
      case 5:
        return 'Active Explorer';
      case 6:
        return 'Beginner Explorer';
      default:
        return 'Newcomer';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold for Elite
      case 2:
        return Colors.purple; // Purple for Expert
      case 3:
        return Colors.blue; // Blue for Advanced
      case 4:
        return Colors.green; // Green for Intermediate
      case 5:
        return Colors.orange; // Orange for Active
      case 6:
        return Colors.teal; // Teal for Beginner
      default:
        return Colors.grey; // Grey for Newcomer
    }
  }

  String _getRankDescription(int rank) {
    switch (rank) {
      case 1:
        return 'Campus master with 1000+ activity points';
      case 2:
        return 'Experienced explorer with 500+ points';
      case 3:
        return 'Regular campus user with 200+ points';
      case 4:
        return 'Active campus visitor with 100+ points';
      case 5:
        return 'Getting around campus with 50+ points';
      case 6:
        return 'Starting your campus journey with 20+ points';
      default:
        return 'Welcome to campus exploration!';
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events; // Trophy for Elite
      case 2:
        return Icons.stars; // Stars for Expert
      case 3:
        return Icons.trending_up; // Trending up for Advanced
      case 4:
        return Icons.explore; // Explore for Intermediate
      case 5:
        return Icons.directions_walk; // Walking for Active
      case 6:
        return Icons.place; // Place for Beginner
      default:
        return Icons.person; // Person for Newcomer
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'classes':
      case 'class':
      case 'academic':
        return Icons.school;
      case 'food':
      case 'restaurant':
      case 'dining':
      case 'food & dining':
        return Icons.restaurant;
      case 'library':
      case 'study':
      case 'study spaces':
        return Icons.local_library;
      case 'gym':
      case 'gyms':
      case 'fitness':
      case 'sports & fitness':
        return Icons.fitness_center;
      case 'hostels':
      case 'hostel':
        return Icons.home;
      case 'offices':
      case 'office':
        return Icons.business;
      case 'atms':
      case 'atm':
        return Icons.atm;
      case 'pharmacies':
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'churches':
      case 'church':
        return Icons.church;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
      case 'store':
      case 'shopping centers':
        return Icons.shopping_cart;
      default:
        return Icons.place;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'classes':
      case 'class':
      case 'academic':
        return Colors.blue;
      case 'food':
      case 'restaurant':
      case 'dining':
      case 'food & dining':
        return Colors.orange;
      case 'library':
      case 'study':
      case 'study spaces':
        return Colors.purple;
      case 'gym':
      case 'gyms':
      case 'fitness':
      case 'sports & fitness':
        return Colors.red;
      case 'hostels':
      case 'hostel':
        return Colors.green;
      case 'offices':
      case 'office':
        return Colors.indigo;
      case 'atms':
      case 'atm':
        return Colors.teal;
      case 'pharmacies':
      case 'pharmacy':
        return Colors.pink;
      case 'churches':
      case 'church':
        return Colors.brown;
      case 'entertainment':
        return Colors.deepPurple;
      case 'shopping':
      case 'store':
      case 'shopping centers':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}
