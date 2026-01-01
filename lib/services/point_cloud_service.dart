import '../models/point_cloud.dart';
import '../models/point3d.dart';
import 'dart:math' as math;

/// Service for managing point cloud data collection
/// 
/// This service collects 3D points from ARCore and stores them
/// efficiently for later mesh reconstruction.
class PointCloudService {
  /// Current point cloud being collected
  PointCloud? _currentPointCloud;
  
  /// All saved point clouds
  final List<PointCloud> _pointClouds = [];
  
  /// Maximum points to collect (to avoid memory issues)
  static const int maxPoints = 50000;
  
  /// Minimum distance between points (to avoid duplicates)
  static const double minPointDistance = 0.001; // 1mm in meters

  /// Start a new scan
  void startScan({String? name, String? description}) {
    _currentPointCloud = PointCloud(
      name: name ?? 'Scan ${DateTime.now().toString().substring(0, 19)}',
      description: description,
    );
  }

  /// Stop current scan
  PointCloud? stopScan() {
    final cloud = _currentPointCloud;
    if (cloud != null) {
      cloud.completedAt = DateTime.now();
      _pointClouds.add(cloud);
      _currentPointCloud = null;
    }
    return cloud;
  }

  /// Add a point to current scan
  /// Returns true if point was added, false if rejected (duplicate/limit)
  bool addPoint(Point3D point) {
    if (_currentPointCloud == null) {
      // Auto-start if not started
      startScan();
    }

    final cloud = _currentPointCloud!;

    // Check if we've hit the limit
    if (cloud.pointCount >= maxPoints) {
      return false;
    }

    // Check if point is too close to existing points (likely duplicate)
    if (_isPointTooClose(point, cloud.points)) {
      return false;
    }

    cloud.addPoint(point);
    return true;
  }

  /// Add multiple points at once
  int addPoints(List<Point3D> points) {
    int added = 0;
    for (final point in points) {
      if (addPoint(point)) {
        added++;
      }
    }
    return added;
  }

  /// Check if a point is too close to existing points
  bool _isPointTooClose(Point3D newPoint, List<Point3D> existingPoints) {
    // For efficiency, only check last 100 points
    final startIndex = math.max(0, existingPoints.length - 100);
    
    for (int i = startIndex; i < existingPoints.length; i++) {
      final distance = newPoint.distanceTo(existingPoints[i]);
      if (distance < minPointDistance) {
        return true;
      }
    }
    return false;
  }

  /// Get current scan
  PointCloud? getCurrentScan() => _currentPointCloud;

  /// Get all saved scans
  List<PointCloud> getAllScans() => List.unmodifiable(_pointClouds);

  /// Get scan by index
  PointCloud? getScan(int index) {
    if (index >= 0 && index < _pointClouds.length) {
      return _pointClouds[index];
    }
    return null;
  }

  /// Delete a scan
  bool deleteScan(int index) {
    if (index >= 0 && index < _pointClouds.length) {
      _pointClouds.removeAt(index);
      return true;
    }
    return false;
  }

  /// Get statistics about current scan
  Map<String, dynamic> getCurrentScanStats() {
    final cloud = _currentPointCloud;
    if (cloud == null || cloud.isEmpty) {
      return {
        'pointCount': 0,
        'status': 'No active scan',
      };
    }

    try {
      final bbox = cloud.getBoundingBox();
      final center = cloud.getCenter();

      return {
        'pointCount': cloud.pointCount,
        'status': 'Scanning...',
        'hasEnoughPoints': cloud.hasEnoughPoints,
        'bounds': {
          'min': {'x': bbox['min']!.x, 'y': bbox['min']!.y, 'z': bbox['min']!.z},
          'max': {'x': bbox['max']!.x, 'y': bbox['max']!.y, 'z': bbox['max']!.z},
        },
        'center': {'x': center.x, 'y': center.y, 'z': center.z},
      };
    } catch (e) {
      return {
        'pointCount': cloud.pointCount,
        'status': 'Insufficient data',
        'error': e.toString(),
      };
    }
  }

  /// Clear all scans (use with caution!)
  void clearAllScans() {
    _pointClouds.clear();
    _currentPointCloud = null;
  }
}






