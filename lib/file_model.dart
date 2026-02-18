import 'dart:io';

class FileModel {
  final FileSystemEntity file;
  bool isImage;
  bool isPdf;

  FileModel(this.file, {this.isImage = false, this.isPdf = false});
}
