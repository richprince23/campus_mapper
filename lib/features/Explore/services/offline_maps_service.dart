import 'dart:developer' show log;
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing offline map tiles
class OfflineMapsService {
  static const String _cacheDirectoryName = 'offline_maps';
  static const String _metadataKey = 'offline_maps_metadata';
  static const int _maxZoomLevel = 18;
  static const int _minZoomLevel = 10;
  
  /// Check if offline maps are enabled in preferences
  Future<bool> isOfflineMapsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // This would be set by the preferences provider
      return prefs.getBool('offline_maps_enabled') ?? false;
    } catch (e) {
      log('Error checking offline maps preference: $e');
      return false;
    }
  }

  /// Get the cache directory for offline maps
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheDirectoryName');
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }

  /// Download map tiles for a specific region
  Future<void> downloadRegion({
    required LatLng center,
    required double radiusKm,
    Function(double)? onProgress,
    VoidCallback? onComplete,
    Function(String)? onError,
  }) async {
    try {
      if (!await isOfflineMapsEnabled()) {
        onError?.call('Offline maps are disabled');
        return;
      }

      // Calculate bounding box
      final bounds = _calculateBounds(center, radiusKm);
      
      // Generate tile coordinates for different zoom levels
      final tileCoordinates = <TileCoordinate>[];
      for (int zoom = _minZoomLevel; zoom <= _maxZoomLevel; zoom++) {
        final tiles = _getTilesInBounds(bounds, zoom);
        tileCoordinates.addAll(tiles);
      }

      log('Downloading ${tileCoordinates.length} map tiles...');

      int downloaded = 0;
      final total = tileCoordinates.length;

      for (final tile in tileCoordinates) {
        try {
          await _downloadTile(tile);
          downloaded++;
          
          final progress = downloaded / total;
          onProgress?.call(progress);
          
          // Add small delay to prevent overwhelming the server
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          log('Failed to download tile ${tile.x},${tile.y},${tile.z}: $e');
          // Continue with other tiles
        }
      }

      // Save metadata
      await _saveRegionMetadata(center, radiusKm);
      
      log('Downloaded $downloaded out of $total tiles');
      onComplete?.call();

    } catch (e) {
      log('Error downloading region: $e');
      onError?.call('Failed to download map region: $e');
    }
  }

  /// Download a single map tile
  Future<void> _downloadTile(TileCoordinate tile) async {
    final cacheDir = await _getCacheDirectory();
    final tileFile = File('${cacheDir.path}/${tile.z}_${tile.x}_${tile.y}.png');
    
    // Skip if already cached
    if (await tileFile.exists()) {
      return;
    }

    // Google Maps tile URL (this is a simplified example)
    // In a real app, you'd need to use the actual Google Maps API
    final url = 'https://mt1.google.com/vt/lyrs=m&x=${tile.x}&y=${tile.y}&z=${tile.z}';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'CampusMapperApp/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await tileFile.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      log('Failed to download tile: $e');
      rethrow;
    }
  }

  /// Get cached tile if available
  Future<File?> getCachedTile(int x, int y, int z) async {
    try {
      if (!await isOfflineMapsEnabled()) {
        return null;
      }

      final cacheDir = await _getCacheDirectory();
      final tileFile = File('${cacheDir.path}/${z}_${x}_${y}.png');
      
      if (await tileFile.exists()) {
        return tileFile;
      }
      
      return null;
    } catch (e) {
      log('Error getting cached tile: $e');
      return null;
    }
  }

  /// Calculate bounding box from center point and radius
  LatLngBounds _calculateBounds(LatLng center, double radiusKm) {
    // Rough calculation: 1 degree ≈ 111 km
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * math.cos(center.latitude * math.pi / 180));

    return LatLngBounds(
      southwest: LatLng(
        center.latitude - latDelta,
        center.longitude - lngDelta,
      ),
      northeast: LatLng(
        center.latitude + latDelta,
        center.longitude + lngDelta,
      ),
    );
  }

  /// Get all tile coordinates within bounds for a zoom level
  List<TileCoordinate> _getTilesInBounds(LatLngBounds bounds, int zoom) {
    final tiles = <TileCoordinate>[];
    
    final swTile = _latLngToTile(bounds.southwest, zoom);
    final neTile = _latLngToTile(bounds.northeast, zoom);
    
    for (int x = swTile.x; x <= neTile.x; x++) {
      for (int y = neTile.y; y <= swTile.y; y++) {
        tiles.add(TileCoordinate(x: x, y: y, z: zoom));
      }
    }
    
    return tiles;
  }

  /// Convert lat/lng to tile coordinates
  TileCoordinate _latLngToTile(LatLng latLng, int zoom) {
    final scale = 1 << zoom; // 2^zoom
    final worldCoordinate = _latLngToWorldCoordinate(latLng);
    
    return TileCoordinate(
      x: (worldCoordinate.x * scale).floor(),
      y: (worldCoordinate.y * scale).floor(),
      z: zoom,
    );
  }

  /// Convert lat/lng to world coordinates (0-1 range)
  Point _latLngToWorldCoordinate(LatLng latLng) {
    double x = (latLng.longitude + 180.0) / 360.0;
    double sinLatitude = math.sin(latLng.latitude * math.pi / 180.0);
    double y = 0.5 - math.log(sinLatitude / (1.0 + sinLatitude)) / (4.0 * math.pi);
    
    return Point(x: x, y: y);
  }

  /// Save metadata about downloaded region
  Future<void> _saveRegionMetadata(LatLng center, double radiusKm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getString(_metadataKey);
      
      List<Map<String, dynamic>> regions = [];
      if (existingData != null) {
        final decoded = jsonDecode(existingData) as List;
        regions = decoded.cast<Map<String, dynamic>>();
      }

      regions.add({
        'center': {'lat': center.latitude, 'lng': center.longitude},
        'radius_km': radiusKm,
        'downloaded_at': DateTime.now().toIso8601String(),
        'tile_count': 0, // Could be calculated
      });

      await prefs.setString(_metadataKey, jsonEncode(regions));
      log('Saved offline region metadata');
    } catch (e) {
      log('Error saving region metadata: $e');
    }
  }

  /// Get list of downloaded regions
  Future<List<Map<String, dynamic>>> getDownloadedRegions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_metadataKey);
      
      if (data != null) {
        final decoded = jsonDecode(data) as List;
        return decoded.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      log('Error getting downloaded regions: $e');
      return [];
    }
  }

  /// Get total cache size
  Future<double> getCacheSizeMB() async {
    try {
      final cacheDir = await _getCacheDirectory();
      
      if (!await cacheDir.exists()) {
        return 0.0;
      }

      int totalBytes = 0;
      await for (final file in cacheDir.list(recursive: true)) {
        if (file is File) {
          try {
            final stat = await file.stat();
            totalBytes += stat.size;
          } catch (e) {
            // Skip files that can't be read
          }
        }
      }

      return totalBytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      log('Error calculating cache size: $e');
      return 0.0;
    }
  }

  /// Clear all cached tiles
  Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_metadataKey);
      
      log('Cleared offline maps cache');
    } catch (e) {
      log('Error clearing cache: $e');
      rethrow;
    }
  }

  /// Show download dialog for current campus area
  static Future<void> showDownloadDialog(
    BuildContext context, {
    required LatLng center,
    double radiusKm = 2.0,
  }) async {
    final service = OfflineMapsService();
    
    // Check if offline maps are enabled
    if (!await service.isOfflineMapsEnabled()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable offline maps in preferences first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DownloadDialog(
        service: service,
        center: center,
        radiusKm: radiusKm,
      ),
    );
  }
}

/// Tile coordinate structure
class TileCoordinate {
  final int x;
  final int y;
  final int z;

  const TileCoordinate({
    required this.x,
    required this.y,
    required this.z,
  });
}

/// Point structure for world coordinates
class Point {
  final double x;
  final double y;

  const Point({required this.x, required this.y});
}

/// Download progress dialog
class _DownloadDialog extends StatefulWidget {
  final OfflineMapsService service;
  final LatLng center;
  final double radiusKm;

  const _DownloadDialog({
    required this.service,
    required this.center,
    required this.radiusKm,
  });

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0.0;
  bool _isDownloading = false;
  String _status = 'Ready to download';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Download Offline Maps'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Download maps for campus area (${widget.radiusKm.toStringAsFixed(1)}km radius)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          Text(
            _status,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ElevatedButton(
          onPressed: _isDownloading ? null : _startDownload,
          child: Text(_isDownloading ? 'Downloading...' : 'Download'),
        ),
      ],
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _status = 'Preparing download...';
    });

    await widget.service.downloadRegion(
      center: widget.center,
      radiusKm: widget.radiusKm,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _status = 'Downloaded ${(progress * 100).toStringAsFixed(1)}%';
          });
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() {
            _status = 'Download complete!';
          });
          
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline maps downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _status = 'Error: $error';
          });
        }
      },
    );
  }
}