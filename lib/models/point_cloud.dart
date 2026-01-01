import 'point3d.dart';

/// Collection of 3D points representing a scanned object
/// 
/// This is like a "cloud" of points floating in 3D space.
/// Each point represents a tiny spot on the surface of your dental model.
class PointCloud {
  /// List of all 3D points
  final List<Point3D> points;
  
  /// Timestamp when scanning started
  final DateTime createdAt;
  
  /// Timestamp when scanning ended
  DateTime? completedAt;
  
  /// Metadata about the scan
  final String? name;
  final String? description;

  PointCloud({
    List<Point3D>? points,
    DateTime? createdAt,
    this.completedAt,
    this.name,
    this.description,
  })  : points = points ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Add a single point
  void addPoint(Point3D point) {
    points.add(point);
  }

  /// Add multiple points at once
  void addPoints(List<Point3D> newPoints) {
    points.addAll(newPoints);
  }

  /// Get total number of points
  int get pointCount => points.length;

  /// Check if point cloud is empty
  bool get isEmpty => points.isEmpty;

  /// Check if point cloud has enough points for meshing
  /// (Usually need at least 100 points for a basic mesh)
  bool get hasEnoughPoints => points.length >= 100;

  /// Get bounding box (min/max coordinates)
  Map<String, Point3D> getBoundingBox() {
    if (points.isEmpty) {
      throw StateError('Cannot get bounding box of empty point cloud');
    }

    double minX = points[0].x;
    double maxX = points[0].x;
    double minY = points[0].y;
    double maxY = points[0].y;
    double minZ = points[0].z;
    double maxZ = points[0].z;

    for (final point in points) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
      if (point.z < minZ) minZ = point.z;
      if (point.z > maxZ) maxZ = point.z;
    }

    return {
      'min': Point3D(x: minX, y: minY, z: minZ),
      'max': Point3D(x: maxX, y: maxY, z: maxZ),
    };
  }

  /// Calculate center point of the point cloud
  Point3D getCenter() {
    if (points.isEmpty) {
      throw StateError('Cannot get center of empty point cloud');
    }

    double sumX = 0, sumY = 0, sumZ = 0;
    for (final point in points) {
      sumX += point.x;
      sumY += point.y;
      sumZ += point.z;
    }

    final count = points.length;
    return Point3D(
      x: sumX / count,
      y: sumY / count,
      z: sumZ / count,
    );
  }

  /// Filter out points that are too far from others (likely noise)
  PointCloud filterNoise({double threshold = 0.05}) {
    final filtered = PointCloud(
      name: name,
      description: description,
      createdAt: createdAt,
      completedAt: completedAt,
    );

    if (points.isEmpty) return filtered;

    final center = getCenter();

    for (final point in points) {
      final distance = point.distanceTo(center);
      // Simple noise filter: keep points within reasonable distance
      // More sophisticated filtering will come in later steps
      if (distance < threshold * 10) { // Rough estimate
        filtered.addPoint(point);
      }
    }

    return filtered;
  }

  /// Convert to JSON for saving to file
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'name': name,
      'description': description,
      'pointCount': pointCount,
    };
  }

  /// Create from JSON
  factory PointCloud.fromJson(Map<String, dynamic> json) {
    final cloud = PointCloud(
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );

    final pointsJson = json['points'] as List;
    for (final pointJson in pointsJson) {
      cloud.addPoint(Point3D.fromJson(pointJson as Map<String, dynamic>));
    }

    return cloud;
  }
}






