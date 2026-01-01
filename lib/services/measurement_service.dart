import 'dart:math' as math;
import '../models/point3d.dart';
import '../models/mesh.dart';
import '../models/triangle.dart';

/// Service for making accurate measurements on 3D meshes
/// 
/// Provides millimeter-accurate distance, area, and volume measurements.
class MeasurementService {
  /// Scale factor for calibration (meters to millimeters)
  /// This will be calibrated using a known reference object
  double scaleFactor = 1000.0; // Default: 1 meter = 1000 mm

  /// Calibrate the scale using a known reference object
  /// 
  /// [referenceLength] - Known length in millimeters
  /// [measuredLength] - Measured length in meters
  void calibrate(double referenceLength, double measuredLength) {
    if (measuredLength <= 0) {
      throw ArgumentError('Measured length must be positive');
    }
    scaleFactor = referenceLength / measuredLength;
  }

  /// Calculate distance between two points in millimeters
  double measureDistance(Point3D point1, Point3D point2) {
    final distanceMeters = point1.distanceTo(point2);
    return distanceMeters * scaleFactor;
  }

  /// Calculate distance between two 3D coordinates in millimeters
  double measureDistanceCoords(
    double x1, double y1, double z1,
    double x2, double y2, double z2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dz = z2 - z1;
    final distanceMeters = math.sqrt(dx * dx + dy * dy + dz * dz);
    return distanceMeters * scaleFactor;
  }

  /// Measure surface area of a mesh in square millimeters
  double measureSurfaceArea(Mesh mesh) {
    double totalAreaM2 = 0;
    for (final triangle in mesh.triangles) {
      totalAreaM2 += triangle.getArea();
    }
    return totalAreaM2 * scaleFactor * scaleFactor; // m² to mm²
  }

  /// Measure volume of a closed mesh in cubic millimeters
  double measureVolume(Mesh mesh) {
    final volumeM3 = mesh.getVolume();
    return volumeM3 * scaleFactor * scaleFactor * scaleFactor; // m³ to mm³
  }

  /// Find the closest point on mesh to a given point
  Point3D? findClosestPointOnMesh(Point3D point, Mesh mesh) {
    if (mesh.triangles.isEmpty) return null;

    double minDistance = double.infinity;
    Point3D? closestPoint;

    // Check each triangle
    for (final triangle in mesh.triangles) {
      final closestOnTriangle = _closestPointOnTriangle(
        point,
        triangle.v1,
        triangle.v2,
        triangle.v3,
      );

      final distance = point.distanceTo(closestOnTriangle);
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = closestOnTriangle;
      }
    }

    return closestPoint;
  }

  /// Find closest point on a triangle to a given point
  Point3D _closestPointOnTriangle(
    Point3D point,
    Point3D v1,
    Point3D v2,
    Point3D v3,
  ) {
    // Vector from v1 to v2
    final edge1 = Point3D(
      x: v2.x - v1.x,
      y: v2.y - v1.y,
      z: v2.z - v1.z,
    );

    // Vector from v1 to v3
    final edge2 = Point3D(
      x: v3.x - v1.x,
      y: v3.y - v1.y,
      z: v3.z - v1.z,
    );

    // Vector from v1 to point
    final v1ToPoint = Point3D(
      x: point.x - v1.x,
      y: point.y - v1.y,
      z: point.z - v1.z,
    );

    final a = _dotProduct(edge1, edge1);
    final b = _dotProduct(edge1, edge2);
    final c = _dotProduct(edge2, edge2);
    final d = _dotProduct(edge1, v1ToPoint);
    final e = _dotProduct(edge2, v1ToPoint);

    final det = a * c - b * b;
    double s = b * e - c * d;
    double t = b * d - a * e;

    if (s + t < det) {
      if (s < 0) {
        if (t < 0) {
          // Region 4
          if (d < 0) {
            s = 0;
            t = 0;
            if (-d >= a) {
              s = 1;
            }
          } else {
            s = 0;
          }
        } else {
          // Region 3
          s = 0;
          if (e >= 0) {
            t = 0;
          } else if (-e >= c) {
            t = 1;
          } else {
            t = -e / c;
          }
        }
      } else {
        // Region 5
        t = 0;
        if (d >= 0) {
          s = 0;
        } else if (-d >= a) {
          s = 1;
        } else {
          s = -d / a;
        }
      }
    } else {
      if (s < 0) {
        // Region 2
        final tmp0 = b + d;
        final tmp1 = c + e;
        if (tmp1 > tmp0) {
          final numer = tmp1 - tmp0;
          final denom = a - 2 * b + c;
          s = (numer >= denom) ? 1 : numer / denom;
          t = 1 - s;
        } else {
          s = 0;
          if (tmp1 <= 0) {
            t = 1;
          } else if (e >= 0) {
            t = 0;
          } else {
            t = -e / c;
          }
        }
      } else if (t < 0) {
        // Region 6
        final tmp0 = b + e;
        final tmp1 = a + d;
        if (tmp1 > tmp0) {
          final numer = tmp1 - tmp0;
          final denom = a - 2 * b + c;
          t = (numer >= denom) ? 1 : numer / denom;
          s = 1 - t;
        } else {
          t = 0;
          if (tmp1 <= 0) {
            s = 1;
          } else if (d >= 0) {
            s = 0;
          } else {
            s = -d / a;
          }
        }
      } else {
        // Region 1
        final numer = c + e - b - d;
        if (numer <= 0) {
          s = 0;
        } else {
          final denom = a - 2 * b + c;
          s = (numer >= denom) ? 1 : numer / denom;
        }
        t = 1 - s;
      }
    }

    return Point3D(
      x: v1.x + s * edge1.x + t * edge2.x,
      y: v1.y + s * edge1.y + t * edge2.y,
      z: v1.z + s * edge1.z + t * edge2.z,
    );
  }

  /// Dot product of two points (treating them as vectors)
  double _dotProduct(Point3D a, Point3D b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
  }

  /// Measure the length along a path of points on the mesh
  double measurePathLength(List<Point3D> path) {
    if (path.length < 2) return 0;

    double totalLength = 0;
    for (int i = 0; i < path.length - 1; i++) {
      totalLength += measureDistance(path[i], path[i + 1]);
    }

    return totalLength;
  }

  /// Get bounding box dimensions in millimeters
  Map<String, double> getBoundingBoxDimensions(Mesh mesh) {
    if (mesh.triangles.isEmpty) {
      return {'width': 0, 'height': 0, 'depth': 0};
    }

    // Collect all vertices
    final vertices = <Point3D>[];
    for (final triangle in mesh.triangles) {
      if (!vertices.contains(triangle.v1)) vertices.add(triangle.v1);
      if (!vertices.contains(triangle.v2)) vertices.add(triangle.v2);
      if (!vertices.contains(triangle.v3)) vertices.add(triangle.v3);
    }

    if (vertices.isEmpty) {
      return {'width': 0, 'height': 0, 'depth': 0};
    }

    double minX = vertices[0].x;
    double maxX = vertices[0].x;
    double minY = vertices[0].y;
    double maxY = vertices[0].y;
    double minZ = vertices[0].z;
    double maxZ = vertices[0].z;

    for (final vertex in vertices) {
      if (vertex.x < minX) minX = vertex.x;
      if (vertex.x > maxX) maxX = vertex.x;
      if (vertex.y < minY) minY = vertex.y;
      if (vertex.y > maxY) maxY = vertex.y;
      if (vertex.z < minZ) minZ = vertex.z;
      if (vertex.z > maxZ) maxZ = vertex.z;
    }

    return {
      'width': (maxX - minX) * scaleFactor,
      'height': (maxY - minY) * scaleFactor,
      'depth': (maxZ - minZ) * scaleFactor,
    };
  }

  /// Estimate measurement accuracy based on point density
  /// Returns estimated error in millimeters
  double estimateAccuracy(Mesh mesh) {
    if (mesh.triangles.isEmpty) return double.infinity;

    // Estimate based on average triangle size
    double totalArea = 0;
    int count = 0;

    for (final triangle in mesh.triangles) {
      totalArea += triangle.getArea();
      count++;
    }

    if (count == 0) return double.infinity;

    final avgArea = totalArea / count;
    final avgEdgeLength = math.sqrt(avgArea) * 2; // Rough estimate

    // Error is roughly proportional to triangle edge length
    // For dental models, we target < 0.1mm error
    final estimatedError = avgEdgeLength * scaleFactor * 0.5; // Conservative estimate

    return estimatedError;
  }
}






