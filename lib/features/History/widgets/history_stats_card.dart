import 'package:campus_mapper/features/History/providers/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class HistoryStatsCard extends StatefulWidget {
  const HistoryStatsCard({super.key});

  @override
  State<HistoryStatsCard> createState() => _HistoryStatsCardState();
}

class _HistoryStatsCardState extends State<HistoryStatsCard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        final stats = historyProvider.getHistoryStats();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(51),
            ),
          ),
          child: ExpansionTile(
            onExpansionChanged: (value) {
              // if (mounted) {
              //   setState(() {
              //     _isExpanded = value;
              //   });
              // }
            },
            initiallyExpanded: false,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Icon(
              HugeIcons.strokeRoundedAnalytics01,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Activity Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            subtitle: Text(
              '${stats['total']?.toString() ?? '0'} total activities',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Total',
                      stats['total']?.toString() ?? '0',
                      HugeIcons.strokeRoundedTime04,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Searches',
                      stats['searches']?.toString() ?? '0',
                      HugeIcons.strokeRoundedSearch01,
                      Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Routes',
                      stats['navigations']?.toString() ?? '0',
                      HugeIcons.strokeRoundedRoute01,
                      Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Places',
                      stats['locationViews']?.toString() ?? '0',
                      HugeIcons.strokeRoundedLocation01,
                      Colors.green,
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
            size: 20,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
