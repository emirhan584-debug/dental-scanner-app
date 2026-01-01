import 'package:permission_handler/permission_handler.dart';

/// Service to handle camera permissions
/// 
/// This class helps request and check camera permissions.
/// In Android, users must grant permission to use the camera.
class PermissionService {
  /// Request camera permission from the user
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check if camera permission is already granted
  static Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if camera permission can be requested
  /// (not permanently denied)
  static Future<bool> canRequestCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isDenied || status.isLimited;
  }
}






