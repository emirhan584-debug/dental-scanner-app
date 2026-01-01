import 'dart:math';
import 'point3d.dart';


/// Represents a triangle face in a 3D mesh
class Triangle {
  /// Three vertices of the triangle
  final Point3D v1, v2, v3;

  Triangle({
    required this.v1,
    required this.v2,
    required this.v3,
  });

  /// Calculate triangle normal (which way the surface faces)
  Point3D getNormal() {
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

    // Cross product to get normal
    final nx = edge1.y * edge2.z - edge1.z * edge2.y;
    final ny = edge1.z * edge2.x - edge1.x * edge2.z;
    final nz = edge1.x * edge2.y - edge1.y * edge2.x;

    // Normalize (make length = 1)
    final length = sqrt(nx * nx + ny * ny + nz * nz);
    if (length == 0) {
      return Point3D(x: 0, y: 0, z: 1); // Default normal
    }

    return Point3D(
      x: nx / length,
      y: ny / length,
      z: nz / length,
    );
  }

  /// Calculate triangle area
  double getArea() {
    final edge1 = Point3D(
      x: v2.x - v1.x,
      y: v2.y - v1.y,
      z: v2.z - v1.z,
    );
    final edge2 = Point3D(
      x: v3.x - v1.x,
      y: v3.y - v1.y,
      z: v3.z - v1.z,
    );

    // Cross product magnitude / 2
    final crossX = edge1.y * edge2.z - edge1.z * edge2.y;
    final crossY = edge1.z * edge2.x - edge1.x * edge2.z;
    final crossZ = edge1.x * edge2.y - edge1.y * edge2.x;

    final magnitude = sqrt(crossX * crossX + crossY * crossY + crossZ * crossZ,);

    return magnitude / 2.0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'v1': v1.toJson(),
      'v2': v2.toJson(),
      'v3': v3.toJson(),
    };
  }

  /// Create from JSON
  factory Triangle.fromJson(Map<String, dynamic> json) {
    return Triangle(
      v1: Point3D.fromJson(json['v1']),
      v2: Point3D.fromJson(json['v2']),
      v3: Point3D.fromJson(json['v3']),
    );
  }
}

/// 3D mesh composed of triangles
/// 
/// A mesh is a collection of triangles that form a 3D surface.
/// Think of it like a 3D jigsaw puzzle made of triangles.
class Mesh {
  /// List of all triangles forming the mesh
  final List<Triangle> triangles;
  
  /// Optional: list of unique vertices (to avoid duplicates)
  final List<Point3D> vertices;

  Mesh({
    List<Triangle>? triangles,
    List<Point3D>? vertices,
  })  : triangles = triangles ?? [],
        vertices = vertices ?? [];

  /// Add a triangle
  void addTriangle(Triangle triangle) {
    triangles.add(triangle);
  }

  /// Add multiple triangles
  void addTriangles(List<Triangle> newTriangles) {
    triangles.addAll(newTriangles);
  }

  /// Get total number of triangles
  int get triangleCount => triangles.length;

  /// Check if mesh is empty
  bool get isEmpty => triangles.isEmpty;

  /// Calculate total surface area
  double getSurfaceArea() {
    double totalArea = 0;
    for (final triangle in triangles) {
      totalArea += triangle.getArea();
    }
    return totalArea;
  }

  /// Calculate volume (for closed meshes)
  /// This is a simplified calculation - assumes mesh is closed
  double getVolume() {
    if (triangles.isEmpty) return 0;

    // Simple volume calculation using divergence theorem
    // This works for closed meshes (watertight)
    double volume = 0;
    final origin = Point3D(x: 0, y: 0, z: 0);

    for (final triangle in triangles) {
      final v1 = triangle.v1;
      final v2 = triangle.v2;
      final v3 = triangle.v3;

      // Signed volume of tetrahedron
      final det = v1.x * (v2.y * v3.z - v3.y * v2.z) -
          v2.x * (v1.y * v3.z - v3.y * v1.z) +
          v3.x * (v1.y * v2.z - v2.y * v1.z);

      volume += det;
    }

    return volume.abs() / 6.0;
  }

  /// Convert to JSON for saving
  Map<String, dynamic> toJson() {
    return {
      'triangles': triangles.map((t) => t.toJson()).toList(),
      'vertices': vertices.map((v) => v.toJson()).toList(),
      'triangleCount': triangleCount,
    };
  }

  /// Create from JSON
  factory Mesh.fromJson(Map<String, dynamic> json) {
    final mesh = Mesh();

    final trianglesJson = json['triangles'] as List;
    for (final triJson in trianglesJson) {
      mesh.addTriangle(
        Triangle.fromJson(triJson as Map<String, dynamic>),
      );
    }

    if (json['vertices'] != null) {
      final verticesJson = json['vertices'] as List;
      for (final vertJson in verticesJson) {
        mesh.vertices.add(
          Point3D.fromJson(vertJson as Map<String, dynamic>),
        );
      }
    }

    return mesh;
  }
}






