import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'app_theme.dart';
import 'file_model.dart';
import 'file_service.dart';
import 'permission_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Swiper',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const FileSwiperPage(),
    );
  }
}

class FileSwiperPage extends StatefulWidget {
  const FileSwiperPage({super.key});

  @override
  _FileSwiperPageState createState() => _FileSwiperPageState();
}

class _FileSwiperPageState extends State<FileSwiperPage> {
  final FileService _fileService = FileService();
  final PermissionService _permissionService = PermissionService();
  List<FileModel> _files = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    bool hasPermission = await _permissionService.requestPermissions();
    if (hasPermission) {
      _files = await _fileService.getFiles();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _onSwipe(bool keep) {
    if (!keep) {
      _fileService.deleteFile(_files[_currentIndex].file as File);
    }
    setState(() {
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Swiper')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(child: Text('No files found.'))
              : _buildFileViewer(),
    );
  }

  Widget _buildFileViewer() {
    if (_currentIndex >= _files.length) {
      return const Center(child: Text('All files reviewed!'));
    }

    final fileModel = _files[_currentIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: fileModel.isImage
              ? Image.file(fileModel.file as File)
              : fileModel.isPdf
                  ? PDFView(filePath: fileModel.file.path)
                  : const Center(child: Text('Unsupported file type')),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _onSwipe(false),
                child: const Text('Delete'),
              ),
              ElevatedButton(
                onPressed: () => _onSwipe(true),
                child: const Text('Keep'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
