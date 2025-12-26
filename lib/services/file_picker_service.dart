import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import '../models/shared_file.dart';

/// Service for picking files from device storage.
class FilePickerService {
  /// Pick multiple files from device storage
  Future<List<SharedFile>> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final sharedFiles = <SharedFile>[];
      for (final file in result.files) {
        if (file.path != null) {
          final fileInfo = File(file.path!);
          final stat = await fileInfo.stat();
          final mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';

          sharedFiles.add(SharedFile(
            id: _generateId(file.path!),
            name: file.name,
            path: file.path!,
            size: stat.size,
            mimeType: mimeType,
          ));
        }
      }

      return sharedFiles;
    } catch (e) {
      print('Error picking files: $e');
      return [];
    }
  }

  /// Pick a single video file
  Future<SharedFile?> pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty || result.files.first.path == null) {
        return null;
      }

      final file = result.files.first;
      final fileInfo = File(file.path!);
      final stat = await fileInfo.stat();
      final mimeType = lookupMimeType(file.path!) ?? 'video/mp4';

      return SharedFile(
        id: _generateId(file.path!),
        name: file.name,
        path: file.path!,
        size: stat.size,
        mimeType: mimeType,
      );
    } catch (e) {
      print('Error picking video: $e');
      return null;
    }
  }

  /// Generate a unique ID for a file based on its path
  String _generateId(String path) {
    return path.hashCode.abs().toRadixString(36);
  }
}
