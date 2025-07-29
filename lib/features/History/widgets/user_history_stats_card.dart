import 'package:campus_mapper/features/History/providers/user_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class UserHistoryStatsCard extends StatelessWidget {
  const UserHistoryStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserHistoryProvider>(
      builder: (context, historyProvider, child) {
        final stats = historyProvider.stats;
        
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(51),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    HugeIcons.strokeRoundedAnalytics01,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Activity Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // First row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Total',
                      stats['total_entries']?.toString() ?? '0',
                      HugeIcons.strokeRoundedTime04,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Searches',
                      stats['searches_performed']?.toString() ?? '0',
                      HugeIcons.strokeRoundedSearch01,
                      Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Places',
                      stats['places_visited']?.toString() ?? '0',
                      HugeIcons.strokeRoundedLocation01,
                      Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Second row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Journeys',
                      stats['journeys_completed']?.toString() ?? '0',
                      HugeIcons.strokeRoundedRoute01,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Favorites',
                      stats['places_favorited']?.toString() ?? '0',
                      HugeIcons.strokeRoundedFavourite,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Routes',
                      stats['routes_calculated']?.toString() ?? '0',
                      HugeIcons.strokeRoundedRoute01,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  fontSize: 10,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}