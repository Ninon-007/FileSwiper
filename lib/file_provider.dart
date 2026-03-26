import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class FileProvider with ChangeNotifier {
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> _deleteQueue = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _currentPath = '/storage/emulated/0/Download';

  List<FileSystemEntity> get files => _files;
  List<FileSystemEntity> get deleteQueue => _deleteQueue;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setTargetFolder(String path) {
    _currentPath = path;
    _files = [];
    _deleteQueue = [];
    notifyListeners();
    loadFiles();
  }

  Future<void> loadFiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!await _requestPermission()) {
        _errorMessage = "Permission denied. Please allow file access.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      Directory dir = Directory(_currentPath);

      if (await dir.exists()) {
        var rawFiles = await dir.list().toList();
        _files = rawFiles.whereType<File>().toList();

        // Sorts files so the most recently modified/added appear first
        _files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );
      } else {
        _errorMessage = "Folder not found: $_currentPath";
      }
    } catch (e) {
      debugPrint("Error loading files: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _requestPermission() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }
    return await Permission.storage.request().isGranted;
  }

  void swipeLeft(int index) {
    _deleteQueue.add(_files[index]);
    notifyListeners();
  }

  void swipeRight(int index) {
    // Kept safe, do nothing
  }

  // Target specific files to restore from the grid
  void restoreFile(FileSystemEntity file) {
    if (_deleteQueue.contains(file)) {
      _deleteQueue.remove(file);
      notifyListeners();
    }
  }

  Future<void> commitDeletion() async {
    for (var file in _deleteQueue) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint("Error deleting file: $e");
      }
    }
    _deleteQueue.clear();
    await loadFiles();
  }
}
