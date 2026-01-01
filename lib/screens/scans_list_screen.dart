import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/point_cloud.dart';
import 'mesh_viewer_screen.dart';

/// Screen showing list of all saved scans
class ScansListScreen extends StatefulWidget {
  const ScansListScreen({super.key});

  @override
  State<ScansListScreen> createState() => _ScansListScreenState();
}

class _ScansListScreenState extends State<ScansListScreen> {
  final StorageService _storageService = StorageService();
  List<String> _scanFiles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final files = await _storageService.listSavedScans();
      setState(() {
        _scanFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load scans: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteScan(String filePath, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final deleted = await _storageService.deleteScan(filePath);
      if (deleted && mounted) {
        setState(() {
          _scanFiles.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan deleted')),
        );
      }
    }
  }

  Future<void> _loadAndViewScan(String filePath) async {
    try {
      final pointCloud = await _storageService.loadPointCloud(filePath);
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeshViewerScreen(pointCloud: pointCloud),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load scan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getScanName(String filePath) {
    final fileName = filePath.split('/').last;
    // Extract timestamp from filename: scan_1234567890.pointcloud.json
    final match = RegExp(r'scan_(\d+)').firstMatch(fileName);
    if (match != null) {
      final timestamp = int.tryParse(match.group(1)!);
      if (timestamp != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return 'Scan ${date.toString().substring(0, 19)}';
      }
    }
    return fileName.replaceAll('.pointcloud.json', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Scans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 20),
                      Text(_errorMessage!),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadScans,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _scanFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 20),
                          const Text(
                            'No scans yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Start scanning to create your first 3D model',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadScans,
                      child: ListView.builder(
                        itemCount: _scanFiles.length,
                        itemBuilder: (context, index) {
                          final filePath = _scanFiles[index];
                          final scanName = _getScanName(filePath);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.scanner, size: 40),
                              title: Text(scanName),
                              subtitle: FutureBuilder<int>(
                                future: _storageService.getFileSize(filePath),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final sizeMB = snapshot.data! / (1024 * 1024);
                                    return Text('Size: ${sizeMB.toStringAsFixed(2)} MB');
                                  }
                                  return const Text('Loading...');
                                },
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('View'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'view') {
                                    _loadAndViewScan(filePath);
                                  } else if (value == 'delete') {
                                    _deleteScan(filePath, index);
                                  }
                                },
                              ),
                              onTap: () => _loadAndViewScan(filePath),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}






