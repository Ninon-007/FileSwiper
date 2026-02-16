import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(const FileSwiperApp());
}

class FileSwiperApp extends StatelessWidget {
  const FileSwiperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Swiper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FileSystemEntity> files = [];
  List<FileSystemEntity> filesToDelete = [];
  bool isLoading = true;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+)
      if (await Permission.photos.request().isGranted ||
          await Permission.videos.request().isGranted ||
          await Permission.manageExternalStorage.request().isGranted) {
        await _loadFiles();
      } else {
        // For older Android versions
        var status = await Permission.storage.request();
        if (status.isGranted) {
          await _loadFiles();
        } else {
          _showPermissionDialog();
        }
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is needed to access and manage files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFiles() async {
    setState(() => isLoading = true);

    try {
      // Get Downloads directory
      Directory? downloadsDir;

      // Try to get the Downloads directory
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = Directory('/storage/emulated/0/Downloads');
        }
      }

      if (downloadsDir != null && await downloadsDir.exists()) {
        final allFiles = downloadsDir.listSync();

        // Filter only PDFs and images
        files = allFiles.where((file) {
          final ext = path.extension(file.path).toLowerCase();
          return ext == '.pdf' ||
              ext == '.jpg' ||
              ext == '.jpeg' ||
              ext == '.png' ||
              ext == '.gif' ||
              ext == '.webp';
        }).toList();
      }
    } catch (e) {
      print('Error loading files: $e');
    }

    setState(() {
      isLoading = false;
      currentIndex = 0;
    });
  }

  void _onSwipeLeft() {
    if (currentIndex < files.length) {
      setState(() {
        filesToDelete.add(files[currentIndex]);
        currentIndex++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to delete queue'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _onSwipeRight() {
    if (currentIndex < files.length) {
      setState(() {
        currentIndex++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kept'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _deleteFiles() {
    if (filesToDelete.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete ${filesToDelete.length} file(s) permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              for (var file in filesToDelete) {
                try {
                  await file.delete();
                } catch (e) {
                  print('Error deleting ${file.path}: $e');
                }
              }

              setState(() {
                files.removeWhere((file) => filesToDelete.contains(file));
                filesToDelete.clear();
                if (currentIndex > files.length) {
                  currentIndex = files.length;
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Files deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _previewFile(FileSystemEntity file) {
    final ext = path.extension(file.path).toLowerCase();

    if (ext == '.pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFPreviewPage(filePath: file.path),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewPage(filePath: file.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Swiper'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (filesToDelete.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Badge(
                  label: Text('${filesToDelete.length}'),
                  child: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteFiles,
                    tooltip: 'Delete queued files',
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No files found in Downloads',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadFiles,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : currentIndex >= files.length
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'All done!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${filesToDelete.length} file(s) queued for deletion',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  if (filesToDelete.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _deleteFiles,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _loadFiles,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '${currentIndex + 1} / ${files.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: SwipeableCard(
                    file: files[currentIndex],
                    onSwipeLeft: _onSwipeLeft,
                    onSwipeRight: _onSwipeRight,
                    onPreview: () => _previewFile(files[currentIndex]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: 'delete',
                        onPressed: _onSwipeLeft,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.delete),
                      ),
                      FloatingActionButton(
                        heroTag: 'preview',
                        onPressed: () => _previewFile(files[currentIndex]),
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.visibility),
                      ),
                      FloatingActionButton(
                        heroTag: 'keep',
                        onPressed: _onSwipeRight,
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.check),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class SwipeableCard extends StatefulWidget {
  final FileSystemEntity file;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onPreview;

  const SwipeableCard({
    super.key,
    required this.file,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onPreview,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> {
  double _dragPosition = 0;

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(widget.file.path);
    final ext = path.extension(widget.file.path).toLowerCase();
    final isPdf = ext == '.pdf';

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragPosition += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragPosition < -100) {
          widget.onSwipeLeft();
        } else if (_dragPosition > 100) {
          widget.onSwipeRight();
        }
        setState(() {
          _dragPosition = 0;
        });
      },
      child: Transform.translate(
        offset: Offset(_dragPosition, 0),
        child: Transform.rotate(
          angle: _dragPosition / 1000,
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 8,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _dragPosition < -50
                    ? Colors.red.withOpacity(0.1)
                    : _dragPosition > 50
                    ? Colors.green.withOpacity(0.1)
                    : null,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: isPdf
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  size: 120,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'PDF Document',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(widget.file.path),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 120,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getFileSize(widget.file),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_dragPosition.abs() > 50)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _dragPosition < 0
                                ? Icons.arrow_back
                                : Icons.arrow_forward,
                            color: _dragPosition < 0
                                ? Colors.red
                                : Colors.green,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _dragPosition < 0 ? 'DELETE' : 'KEEP',
                            style: TextStyle(
                              color: _dragPosition < 0
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFileSize(FileSystemEntity file) {
    try {
      final bytes = File(file.path).lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown size';
    }
  }
}

class PDFPreviewPage extends StatelessWidget {
  final String filePath;

  const PDFPreviewPage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(path.basename(filePath))),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      ),
    );
  }
}

class ImagePreviewPage extends StatelessWidget {
  final String filePath;

  const ImagePreviewPage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(path.basename(filePath)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(child: InteractiveViewer(child: Image.file(File(filePath)))),
    );
  }
}
