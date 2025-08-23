import 'package:campus_mapper/features/History/models/user_history.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class UserHistoryItemTile extends StatelessWidget {
  final UserHistory historyItem;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const UserHistoryItemTile({
    super.key,
    required this.historyItem,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        // leading: _buildLeadingIcon(context),
        title: Text(
          historyItem.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (historyItem.displaySubtitle != null) ...[
              Text(
                historyItem.displaySubtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Icon(
                  HugeIcons.strokeRoundedTime04,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(historyItem.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(128),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                HugeIcons.strokeRoundedDelete02,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Delete',
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  // Widget _buildLeadingIcon(BuildContext context) {
  //   IconData iconData;
  //   Color iconColor = Theme.of(context).colorScheme.primary;

  //   switch (historyItem.actionType) {
  //     case HistoryActionType.searchPerformed:
  //       iconData = HugeIcons.strokeRoundedSearch01;
  //       break;
  //     case HistoryActionType.journeyCompleted:
  //       iconData = HugeIcons.strokeRoundedRoute01;
  //       iconColor = Theme.of(context).colorScheme.secondary;
  //       break;
  //     case HistoryActionType.placeVisited:
  //       iconData = HugeIcons.strokeRoundedLocation01;
  //       iconColor = Theme.of(context).colorScheme.tertiary;
  //       break;
  //     case HistoryActionType.placeFavorited:
  //       iconData = HugeIcons.strokeRoundedFavourite;
  //       iconColor = Colors.red;
  //       break;
  //     case HistoryActionType.placeAdded:
  //       iconData = HugeIcons.strokeRoundedLocationAdd01;
  //       iconColor = Colors.green;
  //       break;
  //     case HistoryActionType.routeCalculated:
  //       iconData = HugeIcons.strokeRoundedRoute01;
  //       iconColor = Colors.blue;
  //       break;
  //     default:
  //       print("default hit");
  //   }

  //   return Container(
  //     width: 48,
  //     height: 48,
  //     decoration: BoxDecoration(
  //       color: iconColor.withAlpha(26),
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Icon(
  //       iconData,
  //       color: iconColor,
  //       size: 24,
  //     ),
  //   );
  // }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
