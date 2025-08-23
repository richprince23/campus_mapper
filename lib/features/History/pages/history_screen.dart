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
                onPressed: () =>
                    _showClearHistoryDialog(context, historyProvider),
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
              : historyProvider.hasError
                  ? _buildErrorState(context, historyProvider)
                  : historyProvider.historyItems.isEmpty
                      ? _buildEmptyState(context)
                      : Column(
                          children: [
                            // Sync status indicator
                            if (historyProvider.isSyncing)
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Syncing to cloud...',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Stats card
                            if (historyProvider.historyItems.isNotEmpty)
                              const UserHistoryStatsCard(),
                            // History list
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: () =>
                                    historyProvider.refreshFromFirebase(),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount:
                                      historyProvider.historyItems.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        historyProvider.historyItems[index];
                                    return UserHistoryItemTile(
                                      historyItem: item,
                                      onTap: () =>
                                          _handleHistoryItemTap(context, item),
                                      onDelete: () => _deleteHistoryItem(
                                        context,
                                        historyProvider,
                                        item,
                                      ),
                                    );
                                  },
                                ),
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
                  content: Text(
                      'Tap "Explore" in the bottom navigation to start searching for places'),
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
      default:
        print("default hit");
    }
  }

  void _deleteHistoryItem(
    BuildContext context,
    UserHistoryProvider provider,
    UserHistory item,
  ) async {
    if (item.id != null) {
      try {
        await provider.deleteHistoryItem(item.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('History item deleted'),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // Re-add the item (simplified undo)
                  provider.addHistoryItem(item);
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete item: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
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
          'Are you sure you want to clear all history? This action cannot be undone and will remove all data from the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await provider.clearHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('History cleared successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear history: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
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

  Widget _buildErrorState(BuildContext context, UserHistoryProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              HugeIcons.strokeRoundedAlert02,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Sync Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.refreshFromFirebase(),
              icon: const Icon(HugeIcons.strokeRoundedRefresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            Text(
              provider.getSyncStatusMessage(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(128),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
