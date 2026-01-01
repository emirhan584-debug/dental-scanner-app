import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';
import '../services/point_cloud_service.dart';
import '../services/mesh_reconstruction_service.dart';
import '../services/storage_service.dart';
import '../models/point3d.dart';
import '../models/point_cloud.dart';
import '../models/mesh.dart';

/// Main ARCore scanning screen
/// 
/// This screen shows the camera preview and manages the ARCore session.
/// Users will see what the camera sees and can scan objects in 3D.
class ARCoreScannerScreen extends StatefulWidget {
  const ARCoreScannerScreen({super.key});

  @override
  State<ARCoreScannerScreen> createState() => _ARCoreScannerScreenState();
}

class _ARCoreScannerScreenState extends State<ARCoreScannerScreen> {
  // ARCore controller - manages the ARCore session
  ArCoreController? arCoreController;
  
  // Camera controller - manages camera preview
  CameraController? cameraController;
  
  // List of available cameras
  List<CameraDescription>? cameras;
  
  // Scanning state
  bool isScanning = false;
  bool isPermissionGranted = false;
  bool isLoading = true;
  String? errorMessage;
  
  // Services
  final PointCloudService _pointCloudService = PointCloudService();
  final MeshReconstructionService _meshService = MeshReconstructionService();
  final StorageService _storageService = StorageService();
  
  // Scan statistics
  Map<String, dynamic>? _scanStats;
  
  // Update timer for statistics
  DateTime? _lastStatsUpdate;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Initialize camera and request permissions
  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final hasPermission = await PermissionService.requestCameraPermission();
      
      if (!hasPermission) {
        setState(() {
          isLoading = false;
          errorMessage = 'Camera permission is required to scan.\nPlease grant camera permission in settings.';
          isPermissionGranted = false;
        });
        return;
      }

      setState(() {
        isPermissionGranted = true;
      });

      // Get available cameras
      cameras = await availableCameras();
      
      if (cameras == null || cameras!.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No cameras found on this device.';
        });
        return;
      }

      // Initialize camera controller with back camera
      final backCamera = cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras!.first,
      );

      cameraController = CameraController(
        backCamera,
        ResolutionPreset.high, // High resolution for better scanning
        enableAudio: false,
      );

      await cameraController!.initialize();
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  /// Called when ARCore view is created
  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    
    // Enable plane detection (detects flat surfaces)
    arCoreController.onPlaneDetected = _onPlaneDetected;
    
    // Enable point cloud updates (collects 3D points)
    arCoreController.onPointCloudUpdated = _onPointCloudUpdated;
    
    // Start a new scan session
    _pointCloudService.startScan();
    
    setState(() {
      isScanning = true;
    });
    
    // Update statistics periodically
    _updateStats();
  }

  /// Called when a plane (flat surface) is detected
  void _onPlaneDetected(ArCorePlane plane) {
    // This is called when ARCore detects a flat surface
    // We can use this to help users position their scanning
    debugPrint('Plane detected: ${plane.identifier}');
  }

  /// Called when point cloud is updated
  /// This is where we collect 3D points for mesh reconstruction
  void _onPointCloudUpdated(ArCorePointCloud pointCloud) {
    // This gives us 3D points from the ARCore session
    // Convert ARCore points to our Point3D format and store them
    if (pointCloud.points != null && isScanning) {
      final arCorePoints = pointCloud.points!;
      final points3D = <Point3D>[];
      
      // ARCore provides points as Float32List in groups of 4 (x, y, z, confidence)
      for (int i = 0; i < arCorePoints.length; i += 4) {
        if (i + 2 < arCorePoints.length) {
          final point = Point3D(
            x: arCorePoints[i].toDouble(),
            y: arCorePoints[i + 1].toDouble(),
            z: arCorePoints[i + 2].toDouble(),
            confidence: i + 3 < arCorePoints.length 
                ? arCorePoints[i + 3].toDouble() 
                : null,
          );
          points3D.add(point);
        }
      }
      
      // Add points to our collection
      final added = _pointCloudService.addPoints(points3D);
      
      // Update stats periodically (not on every update for performance)
      final now = DateTime.now();
      if (_lastStatsUpdate == null || 
          now.difference(_lastStatsUpdate!).inSeconds >= 1) {
        _updateStats();
        _lastStatsUpdate = now;
      }
      
      if (added > 0 && points3D.length > 10) {
        debugPrint('Added $added points. Total: ${_pointCloudService.getCurrentScan()?.pointCount ?? 0}');
      }
    }
  }
  
  /// Update scan statistics
  void _updateStats() {
    final stats = _pointCloudService.getCurrentScanStats();
    setState(() {
      _scanStats = stats;
    });
  }

  /// Start scanning
  void _startScanning() {
    setState(() {
      isScanning = true;
    });
  }

  /// Stop scanning and save data
  Future<void> _stopScanning() async {
    setState(() {
      isScanning = false;
    });
    
    // Stop the scan and get collected point cloud
    final pointCloud = _pointCloudService.stopScan();
    
    if (pointCloud == null || pointCloud.isEmpty) {
      _showMessage('No data collected. Please scan again.');
      return;
    }
    
    // Show progress dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Filter noise from point cloud
      final filteredCloud = pointCloud.filterNoise();
      
      if (filteredCloud.isEmpty || !filteredCloud.hasEnoughPoints) {
        if (!mounted) return;
        Navigator.pop(context); // Close progress dialog
        _showMessage(
          'Not enough points collected (${filteredCloud.pointCount}).\n'
          'Please scan more of the object.',
        );
        return;
      }
      
      // Save point cloud
      final savedPath = await _storageService.savePointCloud(filteredCloud);
      debugPrint('Point cloud saved to: $savedPath');
      
      // Reconstruct mesh
      try {
        final mesh = _meshService.reconstructMesh(filteredCloud);
        debugPrint('Mesh reconstructed: ${mesh.triangleCount} triangles');
        
        // Save mesh
        final meshPath = await _storageService.saveMesh(mesh, pointCloud.name ?? 'scan');
        debugPrint('Mesh saved to: $meshPath');
        
        // Analyze mesh quality
        final analysis = _meshService.analyzeMesh(mesh);
        debugPrint('Mesh analysis: $analysis');
        
        if (!mounted) return;
        Navigator.pop(context); // Close progress dialog
        
        _showScanCompleteDialog(filteredCloud, mesh, analysis);
      } catch (e) {
        debugPrint('Mesh reconstruction error: $e');
        if (!mounted) return;
        Navigator.pop(context); // Close progress dialog
        _showMessage('Point cloud saved, but mesh reconstruction failed: $e');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog
      _showMessage('Error saving scan: $e');
    }
  }
  
  /// Show scan completion dialog
  void _showScanCompleteDialog(PointCloud pointCloud, Mesh mesh, Map<String, dynamic> analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Points collected: ${pointCloud.pointCount}'),
            Text('Triangles created: ${mesh.triangleCount}'),
            Text('Surface area: ${analysis['surfaceArea']?.toStringAsFixed(2) ?? 'N/A'} m²'),
            const SizedBox(height: 10),
            const Text('Scan saved successfully!', 
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Start a new scan
              _pointCloudService.startScan();
              setState(() {
                isScanning = true;
              });
            },
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }
  
  /// Show a simple message
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    arCoreController?.dispose();
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Initializing Scanner...'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Setting up camera and ARCore...'),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scanner Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  errorMessage!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (!isPermissionGranted)
                  ElevatedButton(
                    onPressed: () async {
                      final granted = await PermissionService.requestCameraPermission();
                      if (granted) {
                        _initializeCamera();
                      } else {
                        // Open app settings
                        await openAppSettings();
                      }
                    },
                    child: const Text('Grant Permission'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera Not Ready'),
        ),
        body: const Center(
          child: Text('Camera is not initialized'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Scanner'),
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.stop : Icons.play_arrow),
            onPressed: isScanning ? _stopScanning : _startScanning,
            tooltip: isScanning ? 'Stop Scanning' : 'Start Scanning',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ARCore view overlays the camera
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
            enableUpdateListener: true,
          ),
          
          // Scanning instructions overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scan statistics
                  if (_scanStats != null && isScanning)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_queue, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Points: ${_scanStats!['pointCount'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (_scanStats!['hasEnoughPoints'] == true) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.check_circle, 
                                color: Colors.green, size: 16),
                            const Text(
                              'Ready',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  
                  const Text(
                    'Scanning Instructions:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Place the dental model on a flat surface\n'
                    '2. Move your phone slowly around the model\n'
                    '3. Keep a consistent distance (20-30 cm)\n'
                    '4. Capture all angles of the model',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (isScanning)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.radio_button_checked,
                            color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Scanning...',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

