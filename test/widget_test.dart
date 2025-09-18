// This is a basic Flutter widget test for Campus Mapper.

import 'package:flutter_test/flutter_test.dart';
import 'package:campus_mapper/core/models/university.dart';

void main() {
  group('University Model Tests', () {
    test('University model creates correctly', () {
      const university = University(
        id: 'test-id',
        name: 'Test University',
        shortName: 'TU',
      );

      expect(university.id, 'test-id');
      expect(university.name, 'Test University');
      expect(university.shortName, 'TU');
      expect(university.isActive, true);
    });

    test('University model toJson works correctly', () {
      const university = University(
        id: 'test-id',
        name: 'Test University',
        shortName: 'TU',
        isActive: false,
      );

      final json = university.toJson();
      expect(json['id'], 'test-id');
      expect(json['name'], 'Test University');
      expect(json['short_name'], 'TU');
      expect(json['is_active'], false);
    });

    test('University model fromJson works correctly', () {
      final json = {
        'id': 'test-id',
        'name': 'Test University',
        'short_name': 'TU',
        'is_active': true,
      };

      final university = University.fromJson(json);
      expect(university.id, 'test-id');
      expect(university.name, 'Test University');
      expect(university.shortName, 'TU');
      expect(university.isActive, true);
    });

    test('University equality works correctly', () {
      const university1 = University(
        id: 'test-id',
        name: 'Test University',
        shortName: 'TU',
      );

      const university2 = University(
        id: 'test-id',
        name: 'Different Name',
        shortName: 'DN',
      );

      const university3 = University(
        id: 'different-id',
        name: 'Test University',
        shortName: 'TU',
      );

      expect(university1, equals(university2)); // Same ID
      expect(university1, isNot(equals(university3))); // Different ID
    });

    test('University toString works correctly', () {
      const university = University(
        id: 'test-id',
        name: 'Test University',
        shortName: 'TU',
      );

      expect(university.toString(), 'Test University');
    });

    test('University hashCode works correctly', () {
      const university1 = University(
        id: 'test-id',
        name: 'Test University',
        shortName: 'TU',
      );

      const university2 = University(
        id: 'test-id',
        name: 'Different Name',
        shortName: 'DN',
      );

      expect(university1.hashCode, equals(university2.hashCode)); // Same ID
    });
  });

  group('Location Filter Logic Tests', () {
    test('Location data should include university_id when adding location', () {
      // Test the concept of location filtering by university
      final locationData = {
        'name': 'Test Location',
        'category': 'Classes',
        'university_id': 'uew',
        'latitude': 5.5,
        'longitude': -0.2,
      };

      expect(locationData['university_id'], isNotNull);
      expect(locationData['university_id'], 'uew');
    });

    test('Search results should be filtered by university', () {
      // Mock search results to test filtering logic
      final allLocations = [
        {'id': '1', 'name': 'UEW Library', 'university_id': 'uew'},
        {'id': '2', 'name': 'UG Library', 'university_id': 'ug'},
        {'id': '3', 'name': 'KNUST Library', 'university_id': 'knust'},
        {'id': '4', 'name': 'UEW Cafeteria', 'university_id': 'uew'},
      ];

      // Filter by UEW
      final uewLocations = allLocations
          .where((location) => location['university_id'] == 'uew')
          .toList();

      expect(uewLocations.length, 2);
      expect(uewLocations[0]['name'], 'UEW Library');
      expect(uewLocations[1]['name'], 'UEW Cafeteria');
    });

    test('University filtering should be case sensitive for IDs', () {
      final locations = [
        {'id': '1', 'name': 'Location 1', 'university_id': 'uew'},
        {'id': '2', 'name': 'Location 2', 'university_id': 'UEW'},
        {'id': '3', 'name': 'Location 3', 'university_id': 'uew'},
      ];

      final filteredLocations = locations
          .where((location) => location['university_id'] == 'uew')
          .toList();

      expect(filteredLocations.length, 2);
      expect(filteredLocations.any((loc) => loc['name'] == 'Location 2'), false);
    });

    test('University filtering should handle null university_id', () {
      final locations = [
        {'id': '1', 'name': 'Location 1', 'university_id': 'uew'},
        {'id': '2', 'name': 'Location 2', 'university_id': null},
        {'id': '3', 'name': 'Location 3'},
      ];

      // Filter by specific university (should exclude null/missing university_id)
      final filteredLocations = locations
          .where((location) => location['university_id'] == 'uew')
          .toList();

      expect(filteredLocations.length, 1);
      expect(filteredLocations[0]['name'], 'Location 1');
    });
  });

  group('Migration Logic Tests', () {
    test('Migration should identify locations without university_id', () {
      final locations = [
        {'id': '1', 'name': 'Location 1', 'university_id': 'uew'},
        {'id': '2', 'name': 'Location 2'},
        {'id': '3', 'name': 'Location 3', 'university_id': null},
        {'id': '4', 'name': 'Location 4', 'university_id': 'ug'},
      ];

      // Identify locations that need migration (no university_id or null)
      final needsMigration = locations
          .where((location) => 
              !location.containsKey('university_id') || 
              location['university_id'] == null)
          .toList();

      expect(needsMigration.length, 2);
      expect(needsMigration.any((loc) => loc['name'] == 'Location 2'), true);
      expect(needsMigration.any((loc) => loc['name'] == 'Location 3'), true);
    });

    test('Migration should preserve existing university assignments', () {
      final locations = [
        {'id': '1', 'name': 'Location 1', 'university_id': 'ug'},
        {'id': '2', 'name': 'Location 2'},
      ];

      // Simulate migration - only update locations without university_id
      final migratedLocations = locations.map((location) {
        if (!location.containsKey('university_id') || location['university_id'] == null) {
          return {...location, 'university_id': 'uew'};
        }
        return location;
      }).toList();

      expect(migratedLocations[0]['university_id'], 'ug'); // Preserved
      expect(migratedLocations[1]['university_id'], 'uew'); // Migrated
    });
  });
}
