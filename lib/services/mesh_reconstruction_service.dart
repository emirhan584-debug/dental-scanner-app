import '../models/point_cloud.dart';
import '../models/mesh.dart';
import '../models/point3d.dart';
import 'dart:math' as math;

/// Service for reconstructing 3D meshes from point clouds
/// 
/// This service converts collections of 3D points into triangular meshes
/// that form the surface of scanned objects.
class MeshReconstructionService {
  /// Reconstruct a mesh from a point cloud using Delaunay-like triangulation
  /// 
  /// This is a simplified version. For production, you'd want to use
  /// more sophisticated algorithms like Poisson Surface Reconstruction.
  Mesh reconstructMesh(PointCloud pointCloud, {double searchRadius = 0.01}) {
    if (pointCloud.isEmpty) {
      throw ArgumentError('Cannot reconstruct mesh from empty point cloud');
    }

    if (!pointCloud.hasEnoughPoints) {
      throw ArgumentError(
        'Point cloud needs at least 100 points. Current: ${pointCloud.pointCount}',
      );
    }

    final mesh = Mesh();
    final points = pointCloud.points;
    final triangles = <Triangle>[];

    // Simple mesh reconstruction algorithm:
    // For each point, find nearby points and create triangles
    
    // This is a basic approach - production apps would use more
    // sophisticated algorithms like:
    // - Delaunay Triangulation
    // - Poisson Surface Reconstruction
    // - Marching Cubes
    // - Ball Pivoting Algorithm

    // For now, we'll use a grid-based approach for simplicity
    triangles.addAll(_gridBasedTriangulation(points, searchRadius));

    mesh.addTriangles(triangles);
    return mesh;
  }

  /// Grid-based triangulation (simplified approach)
  /// 
  /// This divides space into a grid and connects nearby points.
  /// Not as accurate as advanced algorithms, but good for learning.
  List<Triangle> _gridBasedTriangulation(
    List<Point3D> points,
    double radius,
  ) {
    final triangles = <Triangle>[];

    // Create a spatial grid for efficient neighbor finding
    final grid = _createSpatialGrid(points, radius);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final neighbors = _findNeighbors(point, points, grid, radius, maxNeighbors: 10);

      if (neighbors.length >= 2) {
        // Try to form triangles with neighbors
        for (int j = 0; j < neighbors.length - 1; j++) {
          for (int k = j + 1; k < neighbors.length; k++) {
            final p1 = point;
            final p2 = neighbors[j];
            final p3 = neighbors[k];

            // Check if triangle is valid (not too flat, not too large)
            if (_isValidTriangle(p1, p2, p3, radius)) {
              final triangle = Triangle(v1: p1, v2: p2, v3: p3);
              
              // Check if triangle already exists (avoid duplicates)
              if (!_triangleExists(triangle, triangles)) {
                triangles.add(triangle);
              }
            }
          }
        }
      }
    }

    return triangles;
  }

  /// Create a spatial grid for efficient point lookup
  Map<String, List<int>> _createSpatialGrid(
    List<Point3D> points,
    double cellSize,
  ) {
    final grid = <String, List<int>>{};

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final cellX = (point.x / cellSize).floor();
      final cellY = (point.y / cellSize).floor();
      final cellZ = (point.z / cellSize).floor();
      final key = '$cellX,$cellY,$cellZ';

      grid.putIfAbsent(key, () => []).add(i);
    }

    return grid;
  }

  /// Find neighboring points within radius
  List<Point3D> _findNeighbors(
    Point3D point,
    List<Point3D> allPoints,
    Map<String, List<int>> grid,
    double radius, {
    int maxNeighbors = 10,
  }) {
    final neighbors = <Point3D>[];
    final radiusSquared = radius * radius;
    final cellSize = radius;

    final cellX = (point.x / cellSize).floor();
    final cellY = (point.y / cellSize).floor();
    final cellZ = (point.z / cellSize).floor();

    // Check adjacent cells
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        for (int dz = -1; dz <= 1; dz++) {
          final key = '${cellX + dx},${cellY + dy},${cellZ + dz}';
          final indices = grid[key] ?? [];

          for (final index in indices) {
            final candidate = allPoints[index];
            final distanceSquared = point.distanceTo(candidate) * point.distanceTo(candidate);

            if (distanceSquared <= radiusSquared && distanceSquared > 0.0001) {
              neighbors.add(candidate);
              if (neighbors.length >= maxNeighbors) {
                return neighbors;
              }
            }
          }
        }
      }
    }

    return neighbors;
  }

  /// Check if triangle is valid (not degenerate)
  bool _isValidTriangle(Point3D p1, Point3D p2, Point3D p3, double maxEdgeLength) {
    final d1 = p1.distanceTo(p2);
    final d2 = p2.distanceTo(p3);
    final d3 = p3.distanceTo(p1);

    // Check if any edge is too long
    if (d1 > maxEdgeLength * 2 || d2 > maxEdgeLength * 2 || d3 > maxEdgeLength * 2) {
      return false;
    }

    // Check if triangle is not too flat (area > threshold)
    final triangle = Triangle(v1: p1, v2: p2, v3: p3);
    final area = triangle.getArea();
    final minArea = maxEdgeLength * maxEdgeLength * 0.001; // Minimum area threshold

    return area > minArea;
  }

  /// Check if triangle already exists in list
  bool _triangleExists(Triangle newTriangle, List<Triangle> existingTriangles) {
    for (final existing in existingTriangles) {
      if (_trianglesEqual(newTriangle, existing)) {
        return true;
      }
    }
    return false;
  }

  /// Check if two triangles are equal (same vertices)
  bool _trianglesEqual(Triangle t1, Triangle t2) {
    // Check if all vertices match (order doesn't matter)
    final t1Vertices = {t1.v1, t1.v2, t1.v3};
    final t2Vertices = {t2.v1, t2.v2, t2.v3};

    return t1Vertices.contains(t2.v1) &&
        t1Vertices.contains(t2.v2) &&
        t1Vertices.contains(t2.v3);
  }

  /// Estimate mesh quality metrics
  Map<String, dynamic> analyzeMesh(Mesh mesh) {
    return {
      'triangleCount': mesh.triangleCount,
      'surfaceArea': mesh.getSurfaceArea(),
      'volume': mesh.getVolume(),
      'isWatertight': _checkWatertight(mesh),
    };
  }

  /// Check if mesh is watertight (closed surface)
  bool _checkWatertight(Mesh mesh) {
    // Simplified check: count edge occurrences
    // In a watertight mesh, each edge should appear exactly twice
    // This is a simplified version - full check is more complex
    final edgeCount = <String, int>{};

    for (final triangle in mesh.triangles) {
      _countEdge(edgeCount, triangle.v1, triangle.v2);
      _countEdge(edgeCount, triangle.v2, triangle.v3);
      _countEdge(edgeCount, triangle.v3, triangle.v1);
    }

    // Check if all edges appear exactly twice
    for (final count in edgeCount.values) {
      if (count != 2) {
        return false;
      }
    }

    return true;
  }

  /// Count edge occurrences
  void _countEdge(Map<String, int> edgeCount, Point3D p1, Point3D p2) {
    // Create a unique key for the edge (order vertices)
    final key = p1.x < p2.x || (p1.x == p2.x && p1.y < p2.y) || 
        (p1.x == p2.x && p1.y == p2.y && p1.z < p2.z)
        ? '${p1.x},${p1.y},${p1.z}-${p2.x},${p2.y},${p2.z}'
        : '${p2.x},${p2.y},${p2.z}-${p1.x},${p1.y},${p1.z}';

    edgeCount[key] = (edgeCount[key] ?? 0) + 1;
  }
}

