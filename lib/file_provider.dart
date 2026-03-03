import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class FileProvider with ChangeNotifier {
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> _deleteQueue = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // ✅ NEW: Store the current target folder (Default to Downloads)
  String _currentPath = '/storage/emulated/0/Download'; 

  List<FileSystemEntity> get files => _files;
  List<FileSystemEntity> get deleteQueue => _deleteQueue;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ✅ NEW: Method to change the folder we are cleaning
  void setTargetFolder(String path) {
    _currentPath = path;
    _files = []; // Clear old files immediately so UI doesn't show wrong stuff
    _deleteQueue = []; // Clear delete queue to avoid accidents
    notifyListeners();
    loadFiles(); // Load the new folder
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

      // ✅ USE THE DYNAMIC PATH
      Directory dir = Directory(_currentPath);

      if (await dir.exists()) {
        // List files (non-recursive, top level only)
        var rawFiles = await dir.list().toList();
        
        // Filter: Keep only Files (ignore folders for now to prevent crashes)
        _files = rawFiles.whereType<File>().toList();
        
        // Sort by date modified (newest first)
        _files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      } else {
        _errorMessage = "Folder not found: $_currentPath";
      }
    } catch (e) {
      _errorMessage = "Error loading files: $e";
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
    // We don't remove from _files yet, visually handled by swiper
    notifyListeners();
  }

  void swipeRight(int index) {
    // Kept safe, do nothing
  }

  void undoLastDelete() {
    if (_deleteQueue.isNotEmpty) {
      _deleteQueue.removeLast();
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
    await loadFiles(); // Refresh list
  }
}