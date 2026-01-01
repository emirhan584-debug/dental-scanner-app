import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/point_cloud.dart';
import '../models/mesh.dart';

/// Service for saving and loading scans to/from files
/// 
/// This service handles file I/O for storing point clouds and meshes
/// on the device's storage.
class StorageService {
  static const String scansDirectory = 'dental_scans';
  static const String pointCloudExtension = '.pointcloud.json';
  static const String meshExtension = '.mesh.json';

  /// Get the directory where scans are stored
  Future<Directory> getScansDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${appDir.path}/$scansDirectory');
    
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }
    
    return scansDir;
  }

  /// Save a point cloud to a file
  Future<String> savePointCloud(PointCloud pointCloud) async {
    final scansDir = await getScansDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'scan_$timestamp$pointCloudExtension';
    final file = File('${scansDir.path}/$filename');

    final json = jsonEncode(pointCloud.toJson());
    await file.writeAsString(json);

    return file.path;
  }

  /// Load a point cloud from a file
  Future<PointCloud> loadPointCloud(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final jsonString = await file.readAsString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    
    return PointCloud.fromJson(json);
  }

  /// Save a mesh to a file
  Future<String> saveMesh(Mesh mesh, String baseName) async {
    final scansDir = await getScansDirectory();
    final filename = '${baseName}_mesh$meshExtension';
    final file = File('${scansDir.path}/$filename');

    final json = jsonEncode(mesh.toJson());
    await file.writeAsString(json);

    return file.path;
  }

  /// Load a mesh from a file
  Future<Mesh> loadMesh(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final jsonString = await file.readAsString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    
    return Mesh.fromJson(json);
  }

  /// List all saved scans
  Future<List<String>> listSavedScans() async {
    final scansDir = await getScansDirectory();
    final files = scansDir.listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(pointCloudExtension))
        .map((f) => f.path)
        .toList();
    
    return files;
  }

  /// Delete a scan file
  Future<bool> deleteScan(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        
        // Also try to delete associated mesh file
        final meshPath = filePath.replaceAll(pointCloudExtension, meshExtension);
        final meshFile = File(meshPath);
        if (await meshFile.exists()) {
          await meshFile.delete();
        }
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Get total storage used by all scans (in MB)
  Future<double> getTotalStorageUsed() async {
    try {
      final scansDir = await getScansDirectory();
      int totalBytes = 0;

      await for (final entity in scansDir.list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }

      return totalBytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      return 0;
    }
  }
}






