import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestStoragePermission() async {
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
    final manageStatus = await Permission.manageExternalStorage.status;
    if (manageStatus.isGranted) return true;

    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted;
  }
}
