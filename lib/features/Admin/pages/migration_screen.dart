import 'package:flutter/material.dart';
import 'package:campus_mapper/core/scripts/migrate_locations_to_university.dart';

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  final LocationUniversityMigration _migration = LocationUniversityMigration();
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Migration'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'University Location Migration',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool will update all existing locations to be associated with University of Education, Winneba (UEW).',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Actions:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Migrate: Add UEW to all locations without university'),
                    const Text('• Verify: Check migration results'),
                    const Text('• Rollback: Remove university from all UEW locations'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_statusMessage.isNotEmpty)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _runMigration,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Run Migration'),
            ),
            
            const SizedBox(height: 12),
            
            OutlinedButton(
              onPressed: _isLoading ? null : _verifyMigration,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Verify Migration'),
            ),
            
            const SizedBox(height: 12),
            
            OutlinedButton(
              onPressed: _isLoading ? null : _rollbackMigration,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.orange),
                foregroundColor: Colors.orange,
              ),
              child: const Text('Rollback Migration'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runMigration() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting migration...';
    });

    try {
      await _migration.migrateAllLocations();
      setState(() {
        _statusMessage = '✅ Migration completed successfully! All locations have been updated to University of Education, Winneba.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Migration failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyMigration() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Verifying migration...';
    });

    try {
      await _migration.verifyMigration();
      setState(() {
        _statusMessage = '✅ Migration verification completed. Check console logs for details.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Verification failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rollbackMigration() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rollback'),
        content: const Text(
          'Are you sure you want to rollback the migration? This will remove university associations from all locations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Rollback'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Rolling back migration...';
    });

    try {
      await _migration.rollbackMigration();
      setState(() {
        _statusMessage = '✅ Migration rollback completed successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Rollback failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}