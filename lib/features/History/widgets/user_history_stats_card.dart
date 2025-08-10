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
                    child: _buildClickableStatItem(
                      context,
                      historyProvider,
                      'Total',
                      stats['total_entries']?.toString() ?? '0',
                      HugeIcons.strokeRoundedTime04,
                      Theme.of(context).colorScheme.primary,
                      'all',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildClickableStatItem(
                      context,
                      historyProvider,
                      'Searches',
                      stats['searches_performed']?.toString() ?? '0',
                      HugeIcons.strokeRoundedSearch01,
                      Theme.of(context).colorScheme.secondary,
                      'searches',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildClickableStatItem(
                      context,
                      historyProvider,
                      'Places',
                      stats['places_visited']?.toString() ?? '0',
                      HugeIcons.strokeRoundedLocation01,
                      Theme.of(context).colorScheme.tertiary,
                      'visits',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Second row
              Row(
                children: [
                  Expanded(
                    child: _buildClickableStatItem(
                      context,
                      historyProvider,
                      'Journeys',
                      stats['journeys_completed']?.toString() ?? '0',
                      HugeIcons.strokeRoundedRoute01,
                      Colors.green,
                      'journeys',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildClickableStatItem(
                      context,
                      historyProvider,
                      'Favorites',
                      stats['places_favorited']?.toString() ?? '0',
                      HugeIcons.strokeRoundedFavourite,
                      Colors.red,
                      'favorites',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildClickableStatItem(
                      context,
                      historyProvider,
                      'Routes',
                      stats['routes_calculated']?.toString() ?? '0',
                      HugeIcons.strokeRoundedRoute01,
                      Colors.blue,
                      'routes',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Third row - Distance and Calories
              Row(
                children: [
                  Expanded(
                    child: _buildClickableStatItem(
                      context,
                      historyProvider,
                      'Distance',
                      _formatDistance(stats['total_distance'] as double? ?? 0.0),
                      HugeIcons.strokeRoundedRoute03,
                      Colors.orange,
                      'distance',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildClickableStatItem(
                      context,
                      historyProvider,
                      'Calories',
                      _formatCalories(stats['total_calories'] as double? ?? 0.0),
                      HugeIcons.strokeRoundedFire,
                      Colors.deepOrange,
                      'calories',
                    ),
                  ),
                  // Add empty expanded to maintain 3-column layout
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClickableStatItem(
    BuildContext context,
    UserHistoryProvider historyProvider,
    String label,
    String value,
    IconData icon,
    Color color,
    String filterType,
  ) {
    final isActive = historyProvider.currentFilter == filterType;
    
    return GestureDetector(
      onTap: () {
        // Check if this tile has zero items (handle both numeric and string values)
        if ((value == '0' || value == '0.0 km' || value == '0 cal') && filterType != 'all' && filterType != 'distance' && filterType != 'calories') {
          // Show snackbar for empty category without filtering
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No $label found yet'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return; // Don't apply filter or change navigation
        }
        
        // Distance and calories are informational only, don't filter
        if (filterType == 'distance' || filterType == 'calories') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Total $label: $value'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        
        // Apply filter for non-zero values or "all" category
        historyProvider.setFilter(filterType);
        
        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              filterType == 'all' 
                ? 'Showing all history' 
                : 'Filtered by $label',
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive 
            ? color.withAlpha(77) // More opaque when active
            : color.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: isActive 
            ? Border.all(color: color, width: 2)
            : null,
          boxShadow: isActive 
            ? [
                BoxShadow(
                  color: color.withAlpha(51),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
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
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters == 0) return '0.0 km';
    
    final distanceInKm = distanceInMeters / 1000;
    if (distanceInKm < 1) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    }
    return '${distanceInKm.toStringAsFixed(1)} km';
  }

  String _formatCalories(double calories) {
    if (calories == 0) return '0 cal';
    return '${calories.toStringAsFixed(0)} cal';
  }
}