import 'package:flutter/material.dart';
import '../models/dental_measurement.dart';
import '../models/point_cloud.dart';
import '../services/measurement_service.dart';
import '../services/orthodontic_calculations_service.dart';

/// Screen for performing orthodontic analyses
class OrthodonticAnalysisScreen extends StatefulWidget {
  final PointCloud pointCloud;

  const OrthodonticAnalysisScreen({
    super.key,
    required this.pointCloud,
  });

  @override
  State<OrthodonticAnalysisScreen> createState() => _OrthodonticAnalysisScreenState();
}

class _OrthodonticAnalysisScreenState extends State<OrthodonticAnalysisScreen> {
  final MeasurementService _measurementService = MeasurementService();
  late final OrthodonticCalculationsService _orthoService;

  DentalMeasurementSet? _measurementSet;
  Map<String, double>? _boltonResults;
  Map<String, dynamic>? _boltonInterpretation;
  Map<String, double>? _hayceMaxillary;
  Map<String, double>? _hayceMandibular;
  Map<String, dynamic>? _hayceMaxInterpretation;
  Map<String, dynamic>? _hayceMandInterpretation;

  @override
  void initState() {
    super.initState();
    _orthoService = OrthodonticCalculationsService(_measurementService);
    _initializeMeasurements();
  }

  void _initializeMeasurements() {
    // Create a new measurement set
    _measurementSet = DentalMeasurementSet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      maxillaryArch: DentalArch(
        id: 'max_${DateTime.now().millisecondsSinceEpoch}',
        type: ArchType.maxillary,
      ),
      mandibularArch: DentalArch(
        id: 'mand_${DateTime.now().millisecondsSinceEpoch}',
        type: ArchType.mandibular,
      ),
    );
  }

  void _performBoltonAnalysis() {
    if (_measurementSet == null ||
        _measurementSet!.maxillaryArch == null ||
        _measurementSet!.mandibularArch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add measurements to both arches first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final results = _orthoService.calculateBoltonAnalysis(_measurementSet!);
      final interpretation = _orthoService.interpretBoltonAnalysis(results);

      setState(() {
        _boltonResults = results;
        _boltonInterpretation = interpretation;
      });

      _measurementSet!.calculatedRatios['boltonOverall'] = results['overallRatio']!;
      _measurementSet!.calculatedRatios['boltonAnterior'] = results['anteriorRatio']!;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating Bolton analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _performHayceAnalysis() {
    if (_measurementSet == null) {
      return;
    }

    try {
      if (_measurementSet!.maxillaryArch != null) {
        final maxResults = _orthoService.calculateHayceAnalysis(_measurementSet!.maxillaryArch!);
        final maxInterpretation = _orthoService.interpretHayceAnalysis(maxResults);
        setState(() {
          _hayceMaxillary = maxResults;
          _hayceMaxInterpretation = maxInterpretation;
        });
      }

      if (_measurementSet!.mandibularArch != null) {
        final mandResults = _orthoService.calculateHayceAnalysis(_measurementSet!.mandibularArch!);
        final mandInterpretation = _orthoService.interpretHayceAnalysis(mandResults);
        setState(() {
          _hayceMandibular = mandResults;
          _hayceMandInterpretation = mandInterpretation;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating Hayce analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orthodontic Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'About Orthodontic Analysis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add measurement points to the dental arches, then calculate:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Bolton: Tooth size ratios between arches\n'
                      '• Hayce: Arch length discrepancies\n'
                      '• Nance: Space analysis for unerupted teeth',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bolton Analysis Section
            _buildAnalysisSection(
              title: 'Bolton Analysis',
              icon: Icons.compare_arrows,
              onCalculate: _performBoltonAnalysis,
              results: _boltonResults,
              interpretation: _boltonInterpretation,
              buildResults: (results) => [
                _buildResultRow('Overall Ratio', '${results['overallRatio']!.toStringAsFixed(2)}%'),
                _buildResultRow('Anterior Ratio', '${results['anteriorRatio']!.toStringAsFixed(2)}%'),
                _buildResultRow('Mandibular Total', '${results['mandibularTotal']!.toStringAsFixed(2)} mm'),
                _buildResultRow('Maxillary Total', '${results['maxillaryTotal']!.toStringAsFixed(2)} mm'),
              ],
            ),

            const SizedBox(height: 24),

            // Hayce Analysis Section
            _buildAnalysisSection(
              title: 'Hayce Analysis',
              icon: Icons.straighten,
              onCalculate: _performHayceAnalysis,
              results: _hayceMaxillary,
              interpretation: _hayceMaxInterpretation,
              subtitle: 'Maxillary Arch',
              buildResults: (results) => [
                _buildResultRow('Arch Length Discrepancy', '${results['archLengthDiscrepancy']!.toStringAsFixed(2)} mm'),
                _buildResultRow('Available Space', '${results['availableSpace']!.toStringAsFixed(2)} mm'),
                _buildResultRow('Required Space', '${results['requiredSpace']!.toStringAsFixed(2)} mm'),
                _buildResultRow('Crowding', '${results['crowding']!.toStringAsFixed(2)} mm'),
                _buildResultRow('Spacing', '${results['spacing']!.toStringAsFixed(2)} mm'),
              ],
            ),

            if (_hayceMandibular != null) ...[
              const SizedBox(height: 16),
              _buildAnalysisSection(
                title: 'Hayce Analysis',
                icon: Icons.straighten,
                onCalculate: null, // Already calculated
                results: _hayceMandibular,
                interpretation: _hayceMandInterpretation,
                subtitle: 'Mandibular Arch',
                buildResults: (results) => [
                  _buildResultRow('Arch Length Discrepancy', '${results['archLengthDiscrepancy']!.toStringAsFixed(2)} mm'),
                  _buildResultRow('Available Space', '${results['availableSpace']!.toStringAsFixed(2)} mm'),
                  _buildResultRow('Required Space', '${results['requiredSpace']!.toStringAsFixed(2)} mm'),
                  _buildResultRow('Crowding', '${results['crowding']!.toStringAsFixed(2)} mm'),
                  _buildResultRow('Spacing', '${results['spacing']!.toStringAsFixed(2)} mm'),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Instructions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to Use',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Add measurement points to mark tooth positions\n'
                      '2. Measure tooth widths and arch dimensions\n'
                      '3. Calculate analyses to get ratios and interpretations\n'
                      '4. Review clinical recommendations',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Measurement point selection coming in next step'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Measurement Points'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection({
    required String title,
    required IconData icon,
    required VoidCallback? onCalculate,
    Map<String, double>? results,
    Map<String, dynamic>? interpretation,
    String? subtitle,
    required List<Widget> Function(Map<String, double>) buildResults,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (onCalculate != null)
                  ElevatedButton(
                    onPressed: onCalculate,
                    child: const Text('Calculate'),
                  ),
              ],
            ),
            if (results != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              ...buildResults(results),
              if (interpretation != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Interpretation:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (interpretation.containsKey('interpretation'))
                        Text(interpretation['interpretation']),
                      if (interpretation.containsKey('overallInterpretation')) ...[
                        Text('Overall: ${interpretation['overallInterpretation']}'),
                        const SizedBox(height: 4),
                        Text('Anterior: ${interpretation['anteriorInterpretation']}'),
                      ],
                      if (interpretation['recommendations'] != null &&
                          (interpretation['recommendations'] as List).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Recommendations:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...(interpretation['recommendations'] as List<String>)
                            .map((rec) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• '),
                                      Expanded(child: Text(rec)),
                                    ],
                                  ),
                                )),
                      ],
                    ],
                  ),
                ),
              ],
            ] else if (onCalculate == null) ...[
              const SizedBox(height: 8),
              Text(
                'No ${subtitle ?? title.toLowerCase()} data available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}






