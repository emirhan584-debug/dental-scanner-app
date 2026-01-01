import 'dart:math' as math;

/// Represents a single 3D point in space
///
/// Each point has x, y, z coordinates and optionally
/// a normal vector (which way the surface faces) and color.
class Point3D {
  final double x;
  final double y;
  final double z;

  // Optional: normal vector (surface direction)
  double? nx;
  double? ny;
  double? nz;

  // Optional: color (RGB values 0-255)
  int? r;
  int? g;
  int? b;

  // Optional: confidence score (how reliable this point is)
  double? confidence;

  /// Named constructor (recommended)
  Point3D({
    required this.x,
    required this.y,
    required this.z,
    this.nx,
    this.ny,
    this.nz,
    this.r,
    this.g,
    this.b,
    this.confidence,
  });

  /// Simple constructor (for old usages like Point3D(x, y, z))
  Point3D.simple(this.x, this.y, this.z);

  /// Create from ARCore point cloud data
  factory Point3D.fromArCore(List<double> position) {
    if (position.length < 3) {
      throw ArgumentError(
        'Position must have at least 3 elements (x, y, z)',
      );
    }
    return Point3D.simple(
      position[0],
      position[1],
      position[2],
    );
  }

  /// Calculate distance to another point
  double distanceTo(Point3D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Convert to JSON for saving
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      if (nx != null) 'nx': nx,
      if (ny != null) 'ny': ny,
      if (nz != null) 'nz': nz,
      if (r != null) 'r': r,
      if (g != null) 'g': g,
      if (b != null) 'b': b,
      if (confidence != null) 'confidence': confidence,
    };
  }

  /// Create from JSON
  factory Point3D.fromJson(Map<String, dynamic> json) {
    return Point3D(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      nx: json['nx'] != null ? (json['nx'] as num).toDouble() : null,
      ny: json['ny'] != null ? (json['ny'] as num).toDouble() : null,
      nz: json['nz'] != null ? (json['nz'] as num).toDouble() : null,
      r: json['r']?.toInt(),
      g: json['g']?.toInt(),
      b: json['b']?.toInt(),
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : null,
    );
  }

  @override
  String toString() => 'Point3D($x, $y, $z)';
}

