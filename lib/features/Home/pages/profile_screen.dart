import 'package:campus_mapper/features/Auth/pages/login_screen.dart';
import 'package:campus_mapper/features/Auth/providers/auth_provider.dart';
import 'package:campus_mapper/features/History/providers/user_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return authProvider.isLoggedIn
              ? _buildProfileView(context, authProvider)
              : _buildGuestView(context, authProvider);
        },
      ),
    );
  }

  Widget _buildGuestView(BuildContext context, AuthProvider authProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  HugeIcons.strokeRoundedUserCircle,
                  size: 60,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Guest User',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Sign in to sync your history and preferences across devices',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(153),
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  icon: const Icon(HugeIcons.strokeRoundedLogin01),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Guest Features
              Container(
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
                    Text(
                      'What you can do as a guest:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(context, HugeIcons.strokeRoundedSearch01,
                        'Search for locations'),
                    _buildFeatureItem(context, HugeIcons.strokeRoundedRoute01,
                        'Get directions'),
                    _buildFeatureItem(
                        context,
                        HugeIcons.strokeRoundedLocation01,
                        'View location details'),
                    _buildFeatureItem(context, HugeIcons.strokeRoundedTime04,
                        'Local history (device only)'),
                    const SizedBox(height: 16),
                    Text(
                      'Sign in to unlock:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                        context,
                        HugeIcons.strokeRoundedCloudDownload,
                        'Cloud sync across devices'),
                    _buildFeatureItem(context, HugeIcons.strokeRoundedFavourite,
                        'Save favorite places'),
                    _buildFeatureItem(
                        context,
                        HugeIcons.strokeRoundedSettings02,
                        'Personalized preferences'),
                    _buildFeatureItem(context, HugeIcons.strokeRoundedSecurity,
                        'Secure data backup'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: authProvider.userPhotoURL != null
                      ? NetworkImage(authProvider.userPhotoURL!)
                      : null,
                  child: authProvider.userPhotoURL == null
                      ? Text(
                          authProvider.userDisplayName
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : null,
                ),

                const SizedBox(height: 16),

                Text(
                  authProvider.userDisplayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),

                const SizedBox(height: 4),

                Text(
                  authProvider.userEmail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withAlpha(153),
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account Actions
          _buildActionCard(
            context,
            title: 'Account Settings',
            items: [
              _buildActionItem(
                context,
                icon: HugeIcons.strokeRoundedUser,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () {
                  // TODO: Navigate to edit profile screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit Profile - Coming Soon')),
                  );
                },
              ),
              _buildActionItem(
                context,
                icon: HugeIcons.strokeRoundedSettings02,
                title: 'Preferences',
                subtitle: 'App settings and preferences',
                onTap: () {
                  // TODO: Navigate to settings screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preferences - Coming Soon')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Data Actions
          _buildActionCard(
            context,
            title: 'Data & Privacy',
            items: [
              _buildActionItem(
                context,
                icon: HugeIcons.strokeRoundedCloudDownload,
                title: 'Sync Data',
                subtitle: 'Refresh your data from cloud',
                onTap: () {
                  // Trigger history refresh
                  final historyProvider = context.read<UserHistoryProvider>();
                  historyProvider.refreshFromFirebase();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Syncing data...')),
                  );
                },
              ),
              _buildActionItem(
                context,
                icon: HugeIcons.strokeRoundedShield01,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                onTap: () async {
                  const url =
                      'https://suptle.com/privacy';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Could not open privacy policy')),
                    );
                  }
                },
              ),
              _buildActionItem(
                context,
                icon: HugeIcons.strokeRoundedNote,
                title: 'Terms & Conditions',
                subtitle: 'View terms and conditions',
                onTap: () async {
                  const url = 'https://suptle.com/campus-mapper/terms';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Could not open terms and conditions')),
                    );
                  }
                },
              ),
              _buildActionItem(
                context,
                icon: HugeIcons.strokeRoundedDelete01,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                onTap: () {
                  _showDeleteAccountDialog(context, authProvider);
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: authProvider.isLoading
                  ? null
                  : () {
                      _showSignOutDialog(context, authProvider);
                    },
              icon: authProvider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(HugeIcons.strokeRoundedLogout01),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Theme.of(context).colorScheme.error),
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required List<Widget> items,
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
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                size: 20,
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
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete your account?'),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAccount(context, authProvider);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(
      BuildContext context, AuthProvider authProvider) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting account...'),
            ],
          ),
        ),
      );

      // Delete user account
      await authProvider.deleteAccount();

      // Clear history data
      if (context.mounted) {
        final historyProvider =
            Provider.of<UserHistoryProvider>(context, listen: false);
        await historyProvider.clearAllHistory();
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
