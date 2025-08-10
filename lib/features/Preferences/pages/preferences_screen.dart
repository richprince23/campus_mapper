import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_mapper/features/Preferences/providers/preferences_provider.dart';
import 'package:campus_mapper/features/Auth/providers/auth_provider.dart';
import 'package:campus_mapper/features/Explore/services/offline_maps_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  void _initializePreferences() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefsProvider = Provider.of<PreferencesProvider>(context, listen: false);
    
    if (authProvider.isLoggedIn) {
      prefsProvider.initializePreferences(authProvider.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(HugeIcons.strokeRoundedMoreVertical),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(HugeIcons.strokeRoundedRefresh),
                    SizedBox(width: 8),
                    Text('Reset to Defaults'),
                  ],
                ),
                onTap: () => _showResetDialog(),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<PreferencesProvider>(
        builder: (context, prefsProvider, child) {
          if (prefsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (prefsProvider.preferences == null) {
            return const Center(
              child: Text('Unable to load preferences'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance Section
                _buildSectionCard(
                  context,
                  title: 'Appearance',
                  icon: HugeIcons.strokeRoundedPaintBrush02,
                  children: [
                    _buildThemeSelector(context, prefsProvider),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      context,
                      title: 'Auto Night Mode',
                      subtitle: 'Automatically switch theme based on time',
                      icon: HugeIcons.strokeRoundedMoon02,
                      value: prefsProvider.preferences!.autoNightMode,
                      onChanged: prefsProvider.setAutoNightMode,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Privacy Section
                _buildSectionCard(
                  context,
                  title: 'Privacy',
                  icon: HugeIcons.strokeRoundedShield01,
                  children: [
                    _buildSwitchTile(
                      context,
                      title: 'Show Name on Leaderboard',
                      subtitle: 'Display your name publicly on rankings',
                      icon: HugeIcons.strokeRoundedAward03,
                      value: prefsProvider.preferences!.showNameOnLeaderboard,
                      onChanged: prefsProvider.setShowNameOnLeaderboard,
                    ),
                    _buildSwitchTile(
                      context,
                      title: 'Location Sharing',
                      subtitle: 'Share location for better recommendations',
                      icon: HugeIcons.strokeRoundedLocation01,
                      value: prefsProvider.preferences!.locationSharingEnabled,
                      onChanged: prefsProvider.setLocationSharingEnabled,
                    ),
                    _buildSwitchTile(
                      context,
                      title: 'Analytics',
                      subtitle: 'Help improve the app with usage data',
                      icon: HugeIcons.strokeRoundedAnalytics02,
                      value: prefsProvider.preferences!.analyticsEnabled,
                      onChanged: prefsProvider.setAnalyticsEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notifications Section
                _buildSectionCard(
                  context,
                  title: 'Notifications',
                  icon: HugeIcons.strokeRoundedNotification01,
                  children: [
                    _buildSwitchTile(
                      context,
                      title: 'Push Notifications',
                      subtitle: 'Receive updates and reminders',
                      icon: HugeIcons.strokeRoundedNotification01,
                      value: prefsProvider.preferences!.notificationsEnabled,
                      onChanged: prefsProvider.setNotificationsEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Map Section
                _buildSectionCard(
                  context,
                  title: 'Map Settings',
                  icon: HugeIcons.strokeRoundedMaps,
                  children: [
                    _buildMapTypeSelector(context, prefsProvider),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      context,
                      title: 'Offline Maps',
                      subtitle: 'Download maps for offline use',
                      icon: HugeIcons.strokeRoundedDownload01,
                      value: prefsProvider.preferences!.offlineMapsEnabled,
                      onChanged: prefsProvider.setOfflineMapsEnabled,
                    ),
                    if (prefsProvider.preferences!.offlineMapsEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 44), // Align with switch content
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showOfflineMapDialog(context),
                                icon: const Icon(HugeIcons.strokeRoundedDownload01, size: 16),
                                label: const Text('Download Campus Area'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, PreferencesProvider prefsProvider) {
    final themes = [
      {'value': 'system', 'label': 'System', 'icon': HugeIcons.strokeRoundedSmartPhone01},
      {'value': 'light', 'label': 'Light', 'icon': HugeIcons.strokeRoundedSun03},
      {'value': 'dark', 'label': 'Dark', 'icon': HugeIcons.strokeRoundedMoon02},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  HugeIcons.strokeRoundedPaintBrush02,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      'Choose your preferred theme',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(153),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: themes.map((theme) {
              final isSelected = prefsProvider.preferences!.theme == theme['value'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => prefsProvider.setTheme(theme['value'] as String),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withAlpha(77),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            theme['icon'] as IconData,
                            size: 20,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            theme['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTypeSelector(BuildContext context, PreferencesProvider prefsProvider) {
    final mapTypes = [
      {'value': 'normal', 'label': 'Normal'},
      {'value': 'satellite', 'label': 'Satellite'},
      {'value': 'hybrid', 'label': 'Hybrid'},
      {'value': 'terrain', 'label': 'Terrain'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              HugeIcons.strokeRoundedLayers01,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default Map Type',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  'Choose your preferred map style',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: prefsProvider.preferences!.mapType,
            onChanged: (value) {
              if (value != null) {
                prefsProvider.setMapType(value);
              }
            },
            items: mapTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type['value'],
                child: Text(type['label']!),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Preferences'),
        content: const Text(
          'Are you sure you want to reset all preferences to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final prefsProvider = Provider.of<PreferencesProvider>(context, listen: false);
              await prefsProvider.resetToDefaults();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preferences reset to defaults'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showOfflineMapDialog(BuildContext context) {
    // Default campus center (you can get this from preferences or map provider)
    const campusCenter = LatLng(5.362312610147424, -0.633134506275042);
    
    OfflineMapsService.showDownloadDialog(
      context,
      center: campusCenter,
      radiusKm: 3.0, // 3km radius around campus
    );
  }
}