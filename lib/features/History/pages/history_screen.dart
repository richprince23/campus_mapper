import 'package:campus_mapper/features/History/models/user_history.dart';
import 'package:campus_mapper/features/History/providers/user_history_provider.dart';
import 'package:campus_mapper/features/History/widgets/user_history_item_tile.dart';
import 'package:campus_mapper/features/History/widgets/user_history_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserHistoryProvider>(
      builder: (context, historyProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('History'),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
            actions: [
              IconButton(
                onPressed: () => _showClearHistoryDialog(context, historyProvider),
                icon: const Icon(HugeIcons.strokeRoundedDelete02),
                tooltip: 'Clear History',
              ),
              IconButton(
                onPressed: () => historyProvider.loadHistory(),
                icon: const Icon(HugeIcons.strokeRoundedRefresh),
                tooltip: 'Refresh',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withAlpha(51),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search history...',
                    prefixIcon: Icon(HugeIcons.strokeRoundedSearch01),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: historyProvider.setSearchQuery,
                ),
              ),
            ),
          ),
          body: historyProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : historyProvider.historyItems.isEmpty
                  ? _buildEmptyState(context)
                  : Column(
                      children: [
                        // Stats card
                        if (historyProvider.historyItems.isNotEmpty)
                          const UserHistoryStatsCard(),
                        // History list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: historyProvider.historyItems.length,
                            itemBuilder: (context, index) {
                              final item = historyProvider.historyItems[index];
                              return UserHistoryItemTile(
                                historyItem: item,
                                onTap: () => _handleHistoryItemTap(context, item),
                                onDelete: () => _deleteHistoryItem(
                                  context,
                                  historyProvider,
                                  item,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            HugeIcons.strokeRoundedTime04,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your searches and navigation history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Show a helpful message since the user can use the bottom navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tap "Explore" in the bottom navigation to start searching for places'),
                  duration: Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(HugeIcons.strokeRoundedSearch01),
            label: const Text('Start Exploring'),
          ),
        ],
      ),
    );
  }

  void _handleHistoryItemTap(BuildContext context, UserHistory item) {
    switch (item.actionType) {
      case HistoryActionType.searchPerformed:
        // Navigate back to search with the query
        final query = item.details['metadata']?['query'] as String?;
        if (query != null) {
          Navigator.of(context).pop(query);
        }
        break;
      case HistoryActionType.journeyCompleted:
      case HistoryActionType.routeCalculated:
        // Navigate to location details or re-navigate
        final placeId = item.details['place_id'] as String?;
        if (placeId != null) {
          // Navigate to location details
          // This would need the location details screen
        }
        break;
      case HistoryActionType.placeVisited:
      case HistoryActionType.placeFavorited:
      case HistoryActionType.placeAdded:
        // Navigate to location details
        final placeId = item.details['place_id'] as String?;
        if (placeId != null) {
          // Navigate to location details
        }
        break;
    }
  }

  void _deleteHistoryItem(
    BuildContext context,
    UserHistoryProvider provider,
    UserHistory item,
  ) {
    if (item.id != null) {
      provider.deleteHistoryItem(item.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History item deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showClearHistoryDialog(
    BuildContext context,
    UserHistoryProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}