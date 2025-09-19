import 'package:flutter/material.dart';
import '../scripts/migrate_locations_to_university.dart';

class QuickMigrationButton extends StatefulWidget {
  const QuickMigrationButton({super.key});

  @override
  State<QuickMigrationButton> createState() => _QuickMigrationButtonState();
}

class _QuickMigrationButtonState extends State<QuickMigrationButton> {
  bool _isRunning = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Migration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will update ALL existing locations and user profiles to UEW',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_status.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status.contains('✅') 
                      ? Colors.green.shade50
                      : _status.contains('❌')
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.contains('✅') 
                        ? Colors.green.shade700
                        : _status.contains('❌')
                            ? Colors.red.shade700
                            : Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runMigration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isRunning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Run Migration Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isRunning ? null : _verifyMigration,
                    child: const Text('Verify Results'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _status = '🔄 Starting migration...';
    });

    try {
      final migration = LocationUniversityMigration();
      
      // Run complete migration
      await migration.migrateAll();
      
      setState(() {
        _status = '✅ Migration completed! All locations and user profiles updated to UEW.';
      });
      
      // Auto-verify after migration
      await Future.delayed(const Duration(seconds: 2));
      await _verifyMigration();
      
    } catch (e) {
      setState(() {
        _status = '❌ Migration failed: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _verifyMigration() async {
    setState(() {
      _status = '📊 Verifying migration results...';
    });

    try {
      final migration = LocationUniversityMigration();
      await migration.verifyMigration();
      
      setState(() {
        _status = '✅ Verification complete! Check console logs for details.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Verification failed: $e';
      });
    }
  }
}