import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'file_model.dart';

class FileService {
  Future<List<FileModel>> getFiles() async {
    List<FileModel> files = [];
    try {
      Directory? downloadsDir = await getExternalStorageDirectory();
      if (downloadsDir != null) {
        List<FileSystemEntity> entities = downloadsDir.listSync();
        for (var entity in entities) {
          if (entity is File) {
            final fileExtension = path.extension(entity.path).toLowerCase();
            final isImage = ['.jpg', '.jpeg', '.png'].contains(fileExtension);
            final isPdf = fileExtension == '.pdf';
            files.add(FileModel(entity, isImage: isImage, isPdf: isPdf));
          }
        }
      }
    } catch (e) {
      print('Error fetching files: $e');
    }
    return files;
  }

  Future<void> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
}
