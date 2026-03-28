import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class FileProvider with ChangeNotifier {
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> _deleteQueue = [];
  List<FileSystemEntity> _limboQueue = []; 
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
    _limboQueue = [];
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
        var rawFiles = await dir.list(recursive: true).toList();
        var filesOnly = rawFiles.whereType<File>().where((f) => !f.path.contains('/.')).toList();

        // Fetch stats (size, modified date) for all files safely
        var fileStats = await Future.wait(
          filesOnly.map((f) async {
            try {
              var stat = await f.stat();
              return {'file': f, 'modified': stat.modified, 'size': stat.size, 'name': f.path.split('/').last};
            } catch (e) {
              return null; // Skip unreadable files
            }
          }),
        );

        var validStats = fileStats.where((e) => e != null).toList();

        // ✅ THE ULTIMATE DUPLICATE FIX: Filter by Name + Exact Byte Size
        final seenSignatures = <String>{};
        final deduplicatedStats = [];

        for (var stat in validStats) {
          // Creates a unique ID like "image.jpg_409600"
          String signature = "${stat!['name']}_${stat['size']}";
          if (seenSignatures.add(signature)) {
            deduplicatedStats.add(stat);
          }
        }

        // Sort by newest first
        deduplicatedStats.sort(
          (a, b) => (b['modified'] as DateTime).compareTo(a['modified'] as DateTime),
        );

        _files = deduplicatedStats.map((e) => e['file'] as File).toList();
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

  void swipeRight(int index) {}

  void restoreFile(FileSystemEntity file) {
    if (_deleteQueue.contains(file)) {
      _deleteQueue.remove(file);
      notifyListeners();
    }
  }

  void prepareCommitDeletion() {
    _limboQueue = List.from(_deleteQueue);
    _deleteQueue.clear();
    notifyListeners();
  }

  void undoCommitDeletion() {
    _deleteQueue = List.from(_limboQueue);
    _limboQueue.clear();
    notifyListeners();
  }

  Future<void> executeFinalDeletion() async {
    for (var file in _limboQueue) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint("Error deleting file: $e");
      }
    }
    _limboQueue.clear();
    await loadFiles();
  }
}