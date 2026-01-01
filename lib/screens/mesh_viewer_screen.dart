import '../models/point3d.dart';
import 'package:flutter/material.dart';
import '../models/point_cloud.dart';
import '../models/mesh.dart';
import '../services/storage_service.dart';
import '../services/mesh_reconstruction_service.dart';
import '../services/measurement_service.dart';
import 'orthodontic_analysis_screen.dart';

/// Screen for viewing and measuring 3D meshes
class MeshViewerScreen extends StatefulWidget {
  final PointCloud pointCloud;

  const MeshViewerScreen({
    super.key,
    required this.pointCloud,
  });

  @override
  State<MeshViewerScreen> createState() => _MeshViewerScreenState();
}

class _MeshViewerScreenState extends State<MeshViewerScreen> {
  final MeshReconstructionService _meshService = MeshReconstructionService();
  final MeasurementService _measurementService = MeasurementService();
  final StorageService _storageService = StorageService();

  Mesh? _mesh;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _meshAnalysis;
  Map<String, double>? _dimensions;

  @override
  void initState() {
    super.initState();
    _loadMesh();
  }

  Future<void> _loadMesh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to load existing mesh first
      try {
        final meshPath = await _findMeshFile();
        if (meshPath != null) {
          _mesh = await _storageService.loadMesh(meshPath);
        }
      } catch (e) {
        // Mesh file not found, reconstruct it
        debugPrint('Mesh file not found, reconstructing: $e');
      }

      // If no mesh, reconstruct from point cloud
      if (_mesh == null) {
        final filteredCloud = widget.pointCloud.filterNoise();
        if (filteredCloud.isEmpty || !filteredCloud.hasEnoughPoints) {
          throw Exception('Not enough points to reconstruct mesh');
        }
        _mesh = _meshService.reconstructMesh(filteredCloud);
      }

      // Analyze mesh
      _meshAnalysis = _meshService.analyzeMesh(_mesh!);
      _dimensions = _measurementService.getBoundingBoxDimensions(_mesh!);
      final accuracy = _measurementService.estimateAccuracy(_mesh!);

      setState(() {
        _isLoading = false;
      });

      // Show accuracy info
      if (accuracy > 0.1 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estimated accuracy: ${accuracy.toStringAsFixed(2)} mm. '
              'Consider recalibrating for better accuracy.',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load mesh: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _findMeshFile() async {
    final scans = await _storageService.listSavedScans();
    final pointCloudName = widget.pointCloud.name ?? 'scan';
    
    for (final scan in scans) {
      if (scan.contains(pointCloudName) && scan.contains('_mesh.mesh.json')) {
        return scan;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pointCloud.name ?? 'Mesh Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_information),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrthodonticAnalysisScreen(
                    pointCloud: widget.pointCloud,
                  ),
                ),
              );
            },
            tooltip: 'Orthodontic Analysis',
          ),
          IconButton(
            icon: const Icon(Icons.straighten),
            onPressed: () => _showMeasurementTools(),
            tooltip: 'Measurements',
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showCalibrationDialog(),
            tooltip: 'Calibrate',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadMesh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _mesh == null
                  ? const Center(child: Text('No mesh available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mesh Statistics Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mesh Statistics',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildStatRow(
                                    'Triangles',
                                    '${_mesh!.triangleCount}',
                                    Icons.change_history,
                                  ),
                                  if (_meshAnalysis != null) ...[
                                    const Divider(),
                                    _buildStatRow(
                                      'Surface Area',
                                      '${(_meshAnalysis!['surfaceArea'] * 100).toStringAsFixed(2)} mm²',
                                      Icons.square_foot,
                                    ),
                                    _buildStatRow(
                                      'Volume',
                                      '${(_meshAnalysis!['volume'] * 1000).toStringAsFixed(2)} mm³',
                                      Icons.crop_free,
                                    ),
                                    _buildStatRow(
                                      'Watertight',
                                      _meshAnalysis!['isWatertight'] ? 'Yes' : 'No',
                                      Icons.water_drop,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Dimensions Card
                          if (_dimensions != null)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Dimensions',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildStatRow(
                                      'Width',
                                      '${_dimensions!['width']!.toStringAsFixed(2)} mm',
                                      Icons.height,
                                    ),
                                    _buildStatRow(
                                      'Height',
                                      '${_dimensions!['height']!.toStringAsFixed(2)} mm',
                                      Icons.height,
                                    ),
                                    _buildStatRow(
                                      'Depth',
                                      '${_dimensions!['depth']!.toStringAsFixed(2)} mm',
                                      Icons.height,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Point Cloud Info Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Point Cloud',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildStatRow(
                                    'Points',
                                    '${widget.pointCloud.pointCount}',
                                    Icons.cloud_queue,
                                  ),
                                  if (widget.pointCloud.createdAt != null)
                                    _buildStatRow(
                                      'Scanned',
                                      widget.pointCloud.createdAt!
                                          .toString()
                                          .substring(0, 19),
                                      Icons.access_time,
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Accuracy Estimation
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
                                        'Accuracy Estimation',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _mesh != null
                                        ? 'Estimated error: ${_measurementService.estimateAccuracy(_mesh!).toStringAsFixed(2)} mm'
                                        : 'Calculating...',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'For better accuracy, use the calibration tool with a known reference object.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showMeasurementTools(),
                                  icon: const Icon(Icons.straighten),
                                  label: const Text('Measurements'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showCalibrationDialog(),
                                  icon: const Icon(Icons.tune),
                                  label: const Text('Calibrate'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showMeasurementTools() {
    if (_mesh == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MeasurementToolsSheet(
        mesh: _mesh!,
        measurementService: _measurementService,
      ),
    );
  }

  void _showCalibrationDialog() {
    final referenceController = TextEditingController();
    final measuredController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibrate Measurement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Measure a known object (e.g., a coin or ruler) in the scan, '
              'then enter the actual size to calibrate.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Actual size (mm)',
                hintText: 'e.g., 20.0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: measuredController,
              decoration: const InputDecoration(
                labelText: 'Measured size (mm)',
                hintText: 'e.g., 19.5',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reference = double.tryParse(referenceController.text);
              final measured = double.tryParse(measuredController.text);

              if (reference != null && measured != null && measured > 0) {
                // Calculate scale factor
                final currentScale = _measurementService.scaleFactor;
                final ratio = reference / measured;
                _measurementService.scaleFactor = currentScale * ratio;

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Calibrated: ${_measurementService.scaleFactor.toStringAsFixed(2)}x',
                    ),
                  ),
                );

                // Reload to update measurements
                setState(() {
                  _dimensions = _measurementService.getBoundingBoxDimensions(_mesh!);
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid numbers'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Calibrate'),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for measurement tools
class MeasurementToolsSheet extends StatefulWidget {
  final Mesh mesh;
  final MeasurementService measurementService;

  const MeasurementToolsSheet({
    super.key,
    required this.mesh,
    required this.measurementService,
  });

  @override
  State<MeasurementToolsSheet> createState() => _MeasurementToolsSheetState();
}

class _MeasurementToolsSheetState extends State<MeasurementToolsSheet> {
  final List<Point3D> _measurementPoints = [];
  double? _currentDistance;

  void _addPoint(Point3D point) {
    setState(() {
      _measurementPoints.add(point);
      if (_measurementPoints.length >= 2) {
        _currentDistance = widget.measurementService.measureDistance(
          _measurementPoints[_measurementPoints.length - 2],
          _measurementPoints[_measurementPoints.length - 1],
        );
      }
    });
  }

  void _clearPoints() {
    setState(() {
      _measurementPoints.clear();
      _currentDistance = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Measurement Tools',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_currentDistance != null)
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Current Measurement',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_currentDistance!.toStringAsFixed(2)} mm',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Instructions:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Tap on the mesh to select measurement points\n'
                      '• Distance between points will be calculated\n'
                      '• Use calibration for improved accuracy',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _clearPoints,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Points'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Note: Interactive point selection will be implemented in the next step with 3D rendering.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

