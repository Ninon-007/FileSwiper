import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:disk_space_2/disk_space_2.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class FileProvider with ChangeNotifier {
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> _deleteQueue = [];
  List<FileSystemEntity> _limboQueue = [];
  bool _isLoading = true;
  String? _errorMessage;
  final List<CardSwiperDirection> _swipeHistory = [];
  
  // Thumbnail cache
  final Map<String, Uint8List?> _thumbnailCache = {};

  double _totalSpace = 0;
  double _usedSpace = 0;
  double _percent = 0;

  String _currentPath = '/storage/emulated/0/Download';

  List<FileSystemEntity> get files => _files;
  List<FileSystemEntity> get deleteQueue => _deleteQueue;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalSpace => _totalSpace;
  double get usedSpace => _usedSpace;
  double get percent => _percent;

  void setTargetFolder(String path) {
    _currentPath = path;
    _files = [];
    _deleteQueue = [];
    _limboQueue = [];
    _swipeHistory.clear();
    _thumbnailCache.clear(); // Clear cache for new folder
    notifyListeners();
    loadFiles();
  }

  Future<Uint8List?> getThumbnail(String path) async {
    if (_thumbnailCache.containsKey(path)) {
      return _thumbnailCache[path];
    }

    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200, // Small for cache efficiency
        quality: 25,
      );
      _thumbnailCache[path] = uint8list;
      return uint8list;
    } catch (e) {
      debugPrint("Error generating thumbnail: $e");
      _thumbnailCache[path] = null;
      return null;
    }
  }

  void prefetchThumbnails(int currentIndex, int count) {
    for (int i = 1; i <= count; i++) {
      int nextIndex = currentIndex + i;
      if (nextIndex < _files.length) {
        String path = _files[nextIndex].path;
        String extension = path.split('.').last.toLowerCase();
        if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
          getThumbnail(path); // This will populate the cache
        }
      }
    }
  }

  Future<void> refreshStorage() async {
    double? free = await DiskSpace.getFreeDiskSpace;
    double? total = await DiskSpace.getTotalDiskSpace;

    if (free != null && total != null) {
      _totalSpace = total / 1024; // Convert MB to GB
      double freeSpace = free / 1024;
      _usedSpace = _totalSpace - freeSpace;
      _percent = _usedSpace / _totalSpace;
      notifyListeners();
    }
  }

  Future<void> loadFiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    // Also refresh storage when loading files
    await refreshStorage();

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
    _swipeHistory.add(CardSwiperDirection.left);
    notifyListeners();
  }

  void swipeRight(int index) {
    _swipeHistory.add(CardSwiperDirection.right);
    notifyListeners();
  }

  void undoSwipe(int index) {
    if (_swipeHistory.isNotEmpty) {
      final lastDirection = _swipeHistory.removeLast();
      if (lastDirection == CardSwiperDirection.left) {
        _deleteQueue.removeLast();
      }
      notifyListeners();
    }
  }

  void restoreFile(FileSystemEntity file) {
    if (_deleteQueue.contains(file)) {
      _deleteQueue.remove(file);
      // We don't easily know where it was in swipeHistory if we restore from Trash screen,
      // but restoreFile is mainly used in DeleteQueueScreen.
      notifyListeners();
    }
  }

  void prepareCommitDeletion() {
    _limboQueue = List.from(_deleteQueue);
    _deleteQueue.clear();
    _swipeHistory.clear();
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
    // Refresh storage and files after deletion
    await loadFiles();
  }
}
