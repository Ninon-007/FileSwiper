import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class FileProvider with ChangeNotifier {
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> _deleteQueue = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<FileSystemEntity> get files => _files;
  List<FileSystemEntity> get deleteQueue => _deleteQueue;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize and load files
  Future<void> loadFiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Request Permissions
      if (!await _requestPermission()) {
        _errorMessage = "Permission denied. Please enable 'All Files Access' in settings.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Get Downloads Directory
      // targeting standard Android Download folder
      Directory downloadsDir = Directory('/storage/emulated/0/Download');

      if (await downloadsDir.exists()) {
        // 3. List files (async)
        // filtering for files only (skipping folders for now)
        var rawFiles = await downloadsDir.list().toList();
        _files = rawFiles.whereType<File>().toList();
        
        // Sort by date modified (newest first)
        _files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      } else {
        _errorMessage = "Downloads folder not found.";
      }
    } catch (e) {
      _errorMessage = "Error loading files: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _requestPermission() async {
    // Check for MANAGE_EXTERNAL_STORAGE (Android 11+)
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }
    // Fallback for older Android
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  void swipeLeft(int index) {
    if (index < _files.length) {
      _deleteQueue.add(_files[index]);
      // We don't remove it from _files yet to keep the card stack consistent until refresh
      notifyListeners();
    }
  }

  void swipeRight(int index) {
    // User kept the file
  }

  Future<void> commitDeletion() async {
    for (var file in _deleteQueue) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode) print("Failed to delete ${file.path}: $e");
      }
    }
    _deleteQueue.clear();
    await loadFiles(); // Refresh list
  }
  
  void undoLastDelete() {
    if (_deleteQueue.isNotEmpty) {
      _deleteQueue.removeLast();
      notifyListeners();
    }
  }
}