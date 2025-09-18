import 'package:flutter/material.dart';
import '../models/university.dart';
import '../services/university_service.dart';

class UniversityDropdownDebug extends StatefulWidget {
  final University? selectedUniversity;
  final ValueChanged<University?> onChanged;
  final String? label;
  final String? hint;
  final bool isRequired;
  final String? errorText;

  const UniversityDropdownDebug({
    super.key,
    required this.onChanged,
    this.selectedUniversity,
    this.label = 'University',
    this.hint = 'Select your university',
    this.isRequired = true,
    this.errorText,
  });

  @override
  State<UniversityDropdownDebug> createState() => _UniversityDropdownDebugState();
}

class _UniversityDropdownDebugState extends State<UniversityDropdownDebug> {
  final UniversityService _universityService = UniversityService();
  List<University> _universities = [];
  bool _isLoading = true;
  String? _error;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _debugInfo = 'Starting to load universities...';
      });

      print('UniversityDropdown: Starting to load universities');
      final universities = await _universityService.getAllUniversities();
      print('UniversityDropdown: Loaded ${universities.length} universities');
      
      if (mounted) {
        setState(() {
          _universities = universities;
          _isLoading = false;
          _debugInfo = 'Successfully loaded ${universities.length} universities';
        });
      }
    } catch (e) {
      print('UniversityDropdown: Error loading universities: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load universities: $e';
          _debugInfo = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Debug info
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Debug: $_debugInfo',
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
          ),
        ),
        
        // Main dropdown
        if (_isLoading)
          DropdownButtonFormField<University>(
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: 'Loading universities...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const SizedBox(
                width: 16,
                height: 16,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            items: const [],
            onChanged: null,
          )
        else if (_error != null)
          Column(
            children: [
              DropdownButtonFormField<University>(
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: 'Error loading universities',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                items: const [],
                onChanged: null,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _loadUniversities,
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          DropdownButtonFormField<University>(
            initialValue: widget.selectedUniversity,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.school),
              errorText: widget.errorText,
            ),
            items: _universities.map((university) {
              return DropdownMenuItem<University>(
                value: university,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      university.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (university.shortName.isNotEmpty)
                      Text(
                        university.shortName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: widget.onChanged,
            validator: widget.isRequired
                ? (value) {
                    if (value == null) {
                      return 'Please select your university';
                    }
                    return null;
                  }
                : null,
            isExpanded: true,
            menuMaxHeight: 300,
          ),
      ],
    );
  }
}