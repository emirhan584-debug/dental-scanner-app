import '../models/dental_measurement.dart';
import 'measurement_service.dart';

/// Service for calculating orthodontic ratios
/// 
/// Implements standard orthodontic analyses:
/// - Bolton Analysis (tooth size ratios)
/// - Hayce Analysis (arch length discrepancies)
/// - Nance Analysis (space analysis)
class OrthodonticCalculationsService {
  final MeasurementService _measurementService;

  OrthodonticCalculationsService(this._measurementService);

  /// Calculate Bolton Analysis ratios
  /// 
  /// Bolton Analysis compares the total tooth widths between arches.
  /// Used to assess tooth size discrepancies that may affect occlusion.
  /// 
  /// Returns a map with:
  /// - 'overallRatio': Overall Bolton ratio (mandibular/maxillary total)
  /// - 'anteriorRatio': Anterior Bolton ratio (anterior 6 teeth)
  /// - 'mandibularTotal': Total mandibular tooth widths
  /// - 'maxillaryTotal': Total maxillary tooth widths
  /// - 'mandibularAnterior': Mandibular anterior 6 teeth
  /// - 'maxillaryAnterior': Maxillary anterior 6 teeth
  Map<String, double> calculateBoltonAnalysis(DentalMeasurementSet measurements) {
    if (measurements.maxillaryArch == null || measurements.mandibularArch == null) {
      throw ArgumentError('Both arches required for Bolton analysis');
    }

    // For now, we'll use placeholder calculations
    // In a full implementation, you'd measure actual tooth widths
    // from the 3D model at specific anatomical landmarks

    final maxillaryArch = measurements.maxillaryArch!;
    final mandibularArch = measurements.mandibularArch!;

    // Extract tooth measurements from arch measurements
    // These would come from specific measurement points on the model
    final maxillaryTotal = _calculateArchTotalWidth(maxillaryArch);
    final mandibularTotal = _calculateArchTotalWidth(mandibularArch);

    final maxillaryAnterior = _calculateAnteriorWidth(maxillaryArch);
    final mandibularAnterior = _calculateAnteriorWidth(mandibularArch);

    // Bolton ratios
    final overallRatio = (mandibularTotal / maxillaryTotal) * 100;
    final anteriorRatio = (mandibularAnterior / maxillaryAnterior) * 100;

    return {
      'overallRatio': overallRatio,
      'anteriorRatio': anteriorRatio,
      'mandibularTotal': mandibularTotal,
      'maxillaryTotal': maxillaryTotal,
      'mandibularAnterior': mandibularAnterior,
      'maxillaryAnterior': maxillaryAnterior,
    };
  }

  /// Calculate Hayce Analysis (Arch Length Discrepancy)
  /// 
  /// Hayce analysis determines if there's enough space for all teeth.
  /// 
  /// Returns:
  /// - 'archLengthDiscrepancy': Difference between required and available space (mm)
  /// - 'availableSpace': Measured arch length (mm)
  /// - 'requiredSpace': Sum of tooth widths (mm)
  /// - 'crowding': Positive value = crowding, negative = spacing
  Map<String, double> calculateHayceAnalysis(DentalArch arch) {
    // Calculate arch perimeter (available space)
    final availableSpace = _calculateArchPerimeter(arch);

    // Calculate total tooth width required
    final requiredSpace = _calculateArchTotalWidth(arch);

    // Discrepancy
    final discrepancy = availableSpace - requiredSpace;

    return {
      'archLengthDiscrepancy': discrepancy,
      'availableSpace': availableSpace,
      'requiredSpace': requiredSpace,
      'crowding': discrepancy < 0 ? discrepancy.abs() : 0,
      'spacing': discrepancy > 0 ? discrepancy : 0,
    };
  }

  /// Calculate Nance Analysis (Mixed Dentition Space Analysis)
  /// 
  /// Nance analysis predicts space for unerupted permanent teeth.
  /// 
  /// Returns:
  /// - 'predictedSpace': Predicted space available
  /// - 'requiredSpace': Space needed for unerupted teeth
  /// - 'discrepancy': Difference (positive = sufficient, negative = insufficient)
  Map<String, double> calculateNanceAnalysis(
    DentalArch arch,
    Map<String, double> predictedToothSizes,
  ) {
    final availableSpace = _calculateArchPerimeter(arch);
    final currentTeethWidth = _calculateArchTotalWidth(arch);

    // Sum of predicted unerupted tooth sizes
    double predictedToothSizeTotal = 0;
    for (final size in predictedToothSizes.values) {
      predictedToothSizeTotal += size;
    }

    final requiredSpace = currentTeethWidth + predictedToothSizeTotal;
    final discrepancy = availableSpace - requiredSpace;

    return {
      'predictedSpace': availableSpace,
      'requiredSpace': requiredSpace,
      'discrepancy': discrepancy,
      'sufficientSpace': discrepancy > 0 ? 1 : 0,
      'predictedCrowding': discrepancy < 0 ? discrepancy.abs() : 0,
    };
  }

  /// Calculate total width of all teeth in arch
  double _calculateArchTotalWidth(DentalArch arch) {
    // This would measure tooth widths at specific anatomical points
    // For now, we use stored measurements or calculate from points
    
    if (arch.measurements.containsKey('totalWidth')) {
      return arch.measurements['totalWidth']!;
    }

    // Calculate from measurement points if available
    if (arch.points.isEmpty) {
      return 0;
    }

    // Sort points by position and calculate cumulative width
    // This is simplified - real implementation would use tooth landmarks
    double totalWidth = 0;
    final sortedPoints = List<DentalMeasurementPoint>.from(arch.points)
      ..sort((a, b) => a.position.x.compareTo(b.position.x));

    for (int i = 0; i < sortedPoints.length - 1; i++) {
      final distance = sortedPoints[i].distanceTo(
        sortedPoints[i + 1],
        _measurementService.scaleFactor,
      );
      totalWidth += distance;
    }

    return totalWidth;
  }

  /// Calculate anterior width (6 anterior teeth)
  double _calculateAnteriorWidth(DentalArch arch) {
    if (arch.measurements.containsKey('anteriorWidth')) {
      return arch.measurements['anteriorWidth']!;
    }

    // Simplified: use first 6 points or specific anterior measurements
    // Real implementation would identify anterior teeth specifically
    final sortedPoints = List<DentalMeasurementPoint>.from(arch.points)
      ..sort((a, b) => a.position.x.compareTo(b.position.x));

    if (sortedPoints.length < 6) {
      return _calculateArchTotalWidth(arch) * 0.4; // Rough estimate
    }

    double anteriorWidth = 0;
    for (int i = 0; i < 5 && i < sortedPoints.length - 1; i++) {
      anteriorWidth += sortedPoints[i].distanceTo(
        sortedPoints[i + 1],
        _measurementService.scaleFactor,
      );
    }

    return anteriorWidth;
  }

  /// Calculate arch perimeter (arch length)
  double _calculateArchPerimeter(DentalArch arch) {
    if (arch.measurements.containsKey('perimeter')) {
      return arch.measurements['perimeter']!;
    }

    // Calculate arch length by following the arch curve
    if (arch.points.length < 2) {
      return 0;
    }

    final sortedPoints = List<DentalMeasurementPoint>.from(arch.points)
      ..sort((a, b) => a.position.x.compareTo(b.position.x));

    double perimeter = 0;
    for (int i = 0; i < sortedPoints.length - 1; i++) {
      perimeter += sortedPoints[i].distanceTo(
        sortedPoints[i + 1],
        _measurementService.scaleFactor,
      );
    }

    return perimeter;
  }

  /// Interpret Bolton ratios and provide clinical recommendations
  Map<String, dynamic> interpretBoltonAnalysis(Map<String, double> boltonResults) {
    final overallRatio = boltonResults['overallRatio']!;
    final anteriorRatio = boltonResults['anteriorRatio']!;

    // Normal ranges:
    // Overall: 91.3 ± 1.91 (Bolton standard)
    // Anterior: 77.2 ± 1.65 (Bolton standard)
    const normalOverallMin = 89.39;
    const normalOverallMax = 93.21;
    const normalAnteriorMin = 75.55;
    const normalAnteriorMax = 78.85;

    String overallInterpretation;
    String anteriorInterpretation;
    List<String> recommendations = [];

    if (overallRatio < normalOverallMin) {
      overallInterpretation = 'Mandibular teeth smaller than normal';
      recommendations.add('Consider mandibular tooth size reduction');
    } else if (overallRatio > normalOverallMax) {
      overallInterpretation = 'Mandibular teeth larger than normal';
      recommendations.add('Consider maxillary tooth size increase or mandibular reduction');
    } else {
      overallInterpretation = 'Within normal range';
    }

    if (anteriorRatio < normalAnteriorMin) {
      anteriorInterpretation = 'Mandibular anterior teeth smaller than normal';
      recommendations.add('Anterior tooth size discrepancy present');
    } else if (anteriorRatio > normalAnteriorMax) {
      anteriorInterpretation = 'Mandibular anterior teeth larger than normal';
      recommendations.add('Anterior tooth size discrepancy present');
    } else {
      anteriorInterpretation = 'Within normal range';
    }

    return {
      'overallInterpretation': overallInterpretation,
      'anteriorInterpretation': anteriorInterpretation,
      'recommendations': recommendations,
      'overallNormal': overallRatio >= normalOverallMin && overallRatio <= normalOverallMax,
      'anteriorNormal': anteriorRatio >= normalAnteriorMin && anteriorRatio <= normalAnteriorMax,
    };
  }

  /// Interpret Hayce analysis results
  Map<String, dynamic> interpretHayceAnalysis(Map<String, double> hayceResults) {
    final discrepancy = hayceResults['archLengthDiscrepancy']!;
    final crowding = hayceResults['crowding']!;
    final spacing = hayceResults['spacing']!;

    String interpretation;
    List<String> recommendations = [];

    if (discrepancy < -5) {
      interpretation = 'Severe crowding';
      recommendations.add('Consider extraction or expansion');
    } else if (discrepancy < 0) {
      interpretation = 'Mild to moderate crowding';
      recommendations.add('Consider interproximal reduction or expansion');
    } else if (discrepancy > 5) {
      interpretation = 'Excessive spacing';
      recommendations.add('Consider closing spaces or restorations');
    } else {
      interpretation = 'Adequate space';
    }

    return {
      'interpretation': interpretation,
      'recommendations': recommendations,
      'discrepancy': discrepancy,
      'crowding': crowding,
      'spacing': spacing,
    };
  }

  /// Interpret Nance analysis results
  Map<String, dynamic> interpretNanceAnalysis(Map<String, double> nanceResults) {
    final discrepancy = nanceResults['discrepancy']!;
    final sufficient = nanceResults['sufficientSpace']! == 1;

    String interpretation;
    List<String> recommendations = [];

    if (sufficient) {
      interpretation = 'Sufficient space predicted for permanent dentition';
    } else {
      final crowding = nanceResults['predictedCrowding']!;
      interpretation = 'Insufficient space predicted (${crowding.toStringAsFixed(2)} mm crowding)';
      
      if (crowding > 5) {
        recommendations.add('Consider early intervention');
        recommendations.add('Evaluate extraction needs');
      } else {
        recommendations.add('Monitor development');
        recommendations.add('Consider space maintenance');
      }
    }

    return {
      'interpretation': interpretation,
      'recommendations': recommendations,
      'sufficientSpace': sufficient,
      'predictedCrowding': nanceResults['predictedCrowding']!,
    };
  }
}






