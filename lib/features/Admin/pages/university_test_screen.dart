import 'package:flutter/material.dart';
import 'package:campus_mapper/core/services/university_service.dart';
import 'package:campus_mapper/core/models/university.dart';
import 'package:campus_mapper/core/widgets/university_dropdown.dart';

class UniversityTestScreen extends StatefulWidget {
  const UniversityTestScreen({super.key});

  @override
  State<UniversityTestScreen> createState() => _UniversityTestScreenState();
}

class _UniversityTestScreenState extends State<UniversityTestScreen> {
  final UniversityService _universityService = UniversityService();
  List<University> _universities = [];
  bool _isLoading = false;
  String _statusMessage = '';
  University? _selectedUniversity;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('University Test'),
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
                      'University Service Test',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Loaded ${_universities.length} universities'),
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusMessage.contains('Error') 
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _loadUniversities,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load Universities'),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _initializeUniversities,
              child: const Text('Initialize Universities in Firestore'),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'University Dropdown Test:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            
            UniversityDropdown(
              selectedUniversity: _selectedUniversity,
              onChanged: (university) {
                setState(() {
                  _selectedUniversity = university;
                });
                if (university != null) {
                  setState(() {
                    _statusMessage = 'Selected: ${university.name} (${university.id})';
                  });
                }
              },
            ),
            
            const SizedBox(height: 24),
            
            if (_universities.isNotEmpty) ...[
              const Text(
                'Loaded Universities:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _universities.length,
                  itemBuilder: (context, index) {
                    final university = _universities[index];
                    return ListTile(
                      title: Text(university.name),
                      subtitle: Text('${university.shortName} (${university.id})'),
                      trailing: university.isActive 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.cancel, color: Colors.red),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadUniversities() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading universities...';
    });

    try {
      final universities = await _universityService.getAllUniversities();
      setState(() {
        _universities = universities;
        _statusMessage = 'Successfully loaded ${universities.length} universities';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading universities: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeUniversities() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing universities in Firestore...';
    });

    try {
      await _universityService.initializeUniversities();
      setState(() {
        _statusMessage = 'Successfully initialized universities in Firestore';
      });
      
      // Reload after initialization
      await _loadUniversities();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing universities: $e';
        _isLoading = false;
      });
    }
  }
}