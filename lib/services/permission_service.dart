import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static bool get _isDesktop => Platform.isWindows || Platform.isLinux;

  static Future<bool> requestStoragePermission() async {
    if (_isDesktop) return true;

    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  static Future<bool> hasStoragePermission() async {
    if (_isDesktop) return true;

    final manageStatus = await Permission.manageExternalStorage.status;
    if (manageStatus.isGranted) return true;

    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted;
  }
}