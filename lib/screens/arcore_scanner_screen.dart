import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/permission_service.dart';
import '../services/point_cloud_service.dart';
import '../services/mesh_reconstruction_service.dart';
import '../services/storage_service.dart';

class ARCoreScannerScreen extends StatefulWidget {
  const ARCoreScannerScreen({super.key});

  @override
  State<ARCoreScannerScreen> createState() => _ARCoreScannerScreenState();
}

class _ARCoreScannerScreenState extends State<ARCoreScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isScanning = false;
  bool _isLoading = true;
  String? _errorMessage;

  final PointCloudService _pointCloudService = PointCloudService();
  final MeshReconstructionService _meshService =
      MeshReconstructionService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final granted =
          await PermissionService.requestCameraPermission();
      if (!granted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Camera permission denied';
        });
        return;
      }

      _cameras = await availableCameras();
      final backCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _startScan() {
    _pointCloudService.startScan();
    setState(() {
      _isScanning = true;
    });
  }

  Future<void> _stopScan() async {
    setState(() {
      _isScanning = false;
    });

    final pointCloud = _pointCloudService.stopScan();
    if (pointCloud == null || pointCloud.isEmpty) return;

    final filtered = pointCloud.filterNoise();
    final mesh = _meshService.reconstructMesh(filtered);

    await _storageService.savePointCloud(filtered);
    await _storageService.saveMesh(mesh, 'scan');
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Scanner'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
            onPressed: _isScanning ? _stopScan : _startScan,
          ),
        ],
      ),
      body: CameraPreview(_cameraController!),
    );
  }
}
