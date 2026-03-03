import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:open_file/open_file.dart';
import 'package:audioplayers/audioplayers.dart'; // ✅ Audio Support

import 'file_provider.dart';
import 'dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FileProvider())],
      child: const FileSwiperApp(),
    ),
  );
}

class FileSwiperApp extends StatelessWidget {
  const FileSwiperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'File Swiper',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.grey[100],
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const DashboardScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Swipe to Clean",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeleteQueueScreen()),
            ),
          ),
        ],
      ),
      body: fileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : fileProvider.files.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "All Clean!",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back to Dashboard"),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: CardSwiper(
                    controller: controller,
                    cardsCount: fileProvider.files.length,
                    onSwipe:
                        (
                          int previousIndex,
                          int? currentIndex,
                          CardSwiperDirection direction,
                        ) {
                          if (direction == CardSwiperDirection.left) {
                            fileProvider.swipeLeft(previousIndex);
                          } else {
                            fileProvider.swipeRight(previousIndex);
                          }
                          return true;
                        },
                    numberOfCardsDisplayed: 2,
                    cardBuilder: (context, index, x, y) {
                      return FileCard(file: fileProvider.files[index]);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30.0,
                    horizontal: 50.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCircleButton(
                        Icons.delete,
                        Colors.red,
                        () => controller.swipe(CardSwiperDirection.left),
                      ),
                      _buildCircleButton(
                        Icons.check,
                        Colors.green,
                        () => controller.swipe(CardSwiperDirection.right),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCircleButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 35),
        onPressed: onTap,
      ),
    );
  }
}

class FileCard extends StatefulWidget {
  final FileSystemEntity file;
  const FileCard({super.key, required this.file});

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  late Future<Uint8List?> _thumbnailFuture;
  AudioPlayer? _audioPlayer; // ✅ Audio Player
  bool _isPlaying = false; // ✅ Playing State

  @override
  void initState() {
    super.initState();
    String extension = widget.file.path.split('.').last.toLowerCase();

    // Generate Video Thumbnail if it's a video
    if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      _thumbnailFuture = VideoThumbnail.thumbnailData(
        video: widget.file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 50,
      );
    } else {
      _thumbnailFuture = Future.value(null); // Return null for non-videos
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose(); // ✅ Clean up audio player
    super.dispose();
  }

  void _toggleAudio() async {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setSourceDeviceFile(widget.file.path);

      // Listen for when audio finishes
      _audioPlayer!.onPlayerComplete.listen((event) {
        if (mounted)
          setState(() {
            _isPlaying = false;
          });
      });
    }

    if (_isPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.resume();
    }
    if (mounted)
      setState(() {
        _isPlaying = !_isPlaying;
      });
  }

  @override
  Widget build(BuildContext context) {
    String extension = widget.file.path.split('.').last.toLowerCase();
    String fileName = widget.file.path.split('/').last;

    return GestureDetector(
      onTap: () {
        OpenFile.open(widget.file.path);
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: Container(
                    color: Colors.black12,
                    width: double.infinity,
                    child: _buildContent(extension, widget.file),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTag(extension.toUpperCase()),
                        const Spacer(),
                        Text(
                          "${(File(widget.file.path).lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String extension, FileSystemEntity file) {
    // 1. IMAGES
    if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      return PhotoView(
        key: ValueKey(file.path),
        imageProvider: FileImage(File(file.path)),
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        minScale: PhotoViewComputedScale.contained,
      );
    }
    // 2. PDF
    else if (extension == 'pdf') {
      return PDFView(
        key: ValueKey(file.path),
        filePath: file.path,
        enableSwipe: false,
        autoSpacing: false,
        pageFling: false,
        onError: (e) =>
            const Center(child: Icon(Icons.error, color: Colors.red)),
      );
    }
    // 3. VIDEO (Show Thumbnail)
    else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return FutureBuilder<Uint8List?>(
        future: _thumbnailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null) {
            return Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                Image.memory(snapshot.data!, fit: BoxFit.cover),
                const Icon(
                  Icons.play_circle_fill,
                  size: 60,
                  color: Colors.white70,
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    // 4. AUDIO (✅ Correctly placed inside the function now)
    else if (['mp3', 'wav', 'aac', 'm4a', 'opus'].contains(extension)) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.audiotrack,
            size: 80,
            color: Colors.orange.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _toggleAudio,
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            label: Text(_isPlaying ? "Pause" : "Play Preview"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              foregroundColor: Colors.orange,
              elevation: 0,
            ),
          ),
        ],
      );
    }
    // 5. APK
    else if (extension == 'apk') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.android, size: 80, color: Colors.green),
          SizedBox(height: 10),
          Text("Android App Installer", style: TextStyle(color: Colors.grey)),
        ],
      );
    }
    // 6. GENERIC
    else {
      String letter = fileName.isNotEmpty ? fileName[0].toUpperCase() : "?";
      Color randomColor =
          Colors.primaries[Random().nextInt(Colors.primaries.length)];

      return Container(
        color: randomColor.withValues(alpha: 0.2),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.bold,
              color: randomColor,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String get fileName => widget.file.path.split('/').last;
}

class DeleteQueueScreen extends StatelessWidget {
  const DeleteQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Delete Queue (${fileProvider.deleteQueue.length})"),
      ),
      body: fileProvider.deleteQueue.isEmpty
          ? const Center(child: Text("No files queued."))
          : ListView.builder(
              itemCount: fileProvider.deleteQueue.length,
              itemBuilder: (context, index) {
                String name = fileProvider.deleteQueue[index].path
                    .split('/')
                    .last;
                return ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(name),
                  trailing: TextButton(
                    child: const Text("Undo"),
                    onPressed: () => fileProvider.undoLastDelete(),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: fileProvider.deleteQueue.isEmpty
              ? null
              : () {
                  fileProvider.commitDeletion();
                  Navigator.pop(context);
                },
          child: const Text("DELETE ALL"),
        ),
      ),
    );
  }
}
