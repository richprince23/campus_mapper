import 'package:flutter/material.dart';
import '../models/university.dart';
import '../services/university_service.dart';

class UniversityDropdown extends StatefulWidget {
  final University? selectedUniversity;
  final ValueChanged<University?> onChanged;
  final String? label;
  final String? hint;
  final bool isRequired;
  final String? errorText;

  const UniversityDropdown({
    super.key,
    required this.onChanged,
    this.selectedUniversity,
    this.label = 'University',
    this.hint = 'Select your university',
    this.isRequired = true,
    this.errorText,
  });

  @override
  State<UniversityDropdown> createState() => _UniversityDropdownState();
}

class _UniversityDropdownState extends State<UniversityDropdown> {
  final UniversityService _universityService = UniversityService();
  List<University> _universities = [];
  bool _isLoading = true;
  String? _error;

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
      });

      final universities = await _universityService.getAllUniversities();
      
      if (mounted) {
        setState(() {
          _universities = universities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load universities';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return DropdownButtonFormField<University>(
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
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
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
      );
    }

    return DropdownButtonFormField<University>(
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
    );
  }
}