import 'point3d.dart';
import 'dart:math' as math;

/// Represents a dental measurement point
/// Used for marking specific points on a dental model for analysis
class DentalMeasurementPoint {
  final String id;
  final String name;
  final Point3D position;
  final DateTime timestamp;
  final String? notes;

  DentalMeasurementPoint({
    required this.id,
    required this.name,
    required this.position,
    DateTime? timestamp,
    this.notes,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Calculate distance to another point in millimeters
  double distanceTo(DentalMeasurementPoint other, double scaleFactor) {
    final dx = position.x - other.position.x;
    final dy = position.y - other.position.y;
    final dz = position.z - other.position.z;
    final distanceMeters = math.sqrt(dx * dx + dy * dy + dz * dz);
    return distanceMeters * scaleFactor;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory DentalMeasurementPoint.fromJson(Map<String, dynamic> json) {
    return DentalMeasurementPoint(
      id: json['id'],
      name: json['name'],
      position: Point3D.fromJson(json['position']),
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
    );
  }
}

/// Represents a dental arch (maxillary or mandibular)
class DentalArch {
  final String id;
  final ArchType type;
  final List<DentalMeasurementPoint> points;
  final Map<String, double> measurements;

  DentalArch({
    required this.id,
    required this.type,
    List<DentalMeasurementPoint>? points,
    Map<String, double>? measurements,
  })  : points = points ?? [],
        measurements = measurements ?? {};

  void addPoint(DentalMeasurementPoint point) {
    points.add(point);
  }

  void addMeasurement(String name, double value) {
    measurements[name] = value;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'points': points.map((p) => p.toJson()).toList(),
      'measurements': measurements,
    };
  }

  factory DentalArch.fromJson(Map<String, dynamic> json) {
    return DentalArch(
      id: json['id'],
      type: ArchType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ArchType.unknown,
      ),
      points: (json['points'] as List)
          .map((p) => DentalMeasurementPoint.fromJson(p))
          .toList(),
      measurements: Map<String, double>.from(json['measurements']),
    );
  }
}

enum ArchType {
  maxillary, // Upper arch
  mandibular, // Lower arch
  unknown,
}

/// Represents a complete set of dental measurements for analysis
class DentalMeasurementSet {
  final String id;
  final DateTime createdAt;
  final DentalArch? maxillaryArch;
  final DentalArch? mandibularArch;
  final Map<String, double> calculatedRatios;

  DentalMeasurementSet({
    required this.id,
    DateTime? createdAt,
    this.maxillaryArch,
    this.mandibularArch,
    Map<String, double>? calculatedRatios,
  })  : createdAt = createdAt ?? DateTime.now(),
        calculatedRatios = calculatedRatios ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'maxillaryArch': maxillaryArch?.toJson(),
      'mandibularArch': mandibularArch?.toJson(),
      'calculatedRatios': calculatedRatios,
    };
  }

  factory DentalMeasurementSet.fromJson(Map<String, dynamic> json) {
    return DentalMeasurementSet(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      maxillaryArch: json['maxillaryArch'] != null
          ? DentalArch.fromJson(json['maxillaryArch'])
          : null,
      mandibularArch: json['mandibularArch'] != null
          ? DentalArch.fromJson(json['mandibularArch'])
          : null,
      calculatedRatios: Map<String, double>.from(json['calculatedRatios'] ?? {}),
    );
  }
}

