import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:open_file/open_file.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light, 
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
  AudioPlayer? _audioPlayer; 
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  @override
  void didUpdateWidget(FileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _stopAndResetAudio(); 
      setState(() {
        _initMedia(); 
      });
    }
  }

  void _initMedia() {
    String extension = widget.file.path.split('.').last.toLowerCase();
    if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      _thumbnailFuture = VideoThumbnail.thumbnailData(
        video: widget.file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 50,
      );
    } else {
      _thumbnailFuture = Future.value(null);
    }
  }

  @override
  void dispose() {
    _stopAndResetAudio();
    super.dispose();
  }

  void _stopAndResetAudio() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
      await _audioPlayer!.dispose();
      _audioPlayer = null;
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  void _toggleAudio() async {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setSourceDeviceFile(widget.file.path);
      _audioPlayer!.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }

    if (_isPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.play(DeviceFileSource(widget.file.path));
    }
    if (mounted) setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    String extension = widget.file.path.split('.').last.toLowerCase();
    String fileName = widget.file.path.split('/').last;

    return Card(
      key: ValueKey(widget.file.path), 
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: AnimatedSwitcher( 
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(widget.file.path),
                    color: Colors.black12,
                    width: double.infinity,
                    child: _buildContent(extension, widget.file),
                  ),
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
                      _buildTag(extension.toUpperCase(), context),
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
    );
  }

  Widget _buildContent(String extension, FileSystemEntity file) {
    if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      return PhotoView(
        key: ValueKey(file.path),
        imageProvider: ResizeImage(FileImage(File(file.path)), width: 800),
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        minScale: PhotoViewComputedScale.contained,
      );
    }
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

  Widget _buildTag(String text, BuildContext context) {
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

// GRID VIEW TRASH BIN
class DeleteQueueScreen extends StatelessWidget {
  const DeleteQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Trash (${fileProvider.deleteQueue.length})"),
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        foregroundColor: Colors.redAccent,
      ),
      body: fileProvider.deleteQueue.isEmpty
          ? const Center(child: Text("No files queued for deletion."))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: fileProvider.deleteQueue.length,
              itemBuilder: (context, index) {
                final file = fileProvider.deleteQueue[index];
                String extension = file.path.split('.').last.toLowerCase();
                String name = file.path.split('/').last;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          color: Theme.of(context).cardColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildMiniPreview(file, extension, context),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                                child: Text(
                                  name, 
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -5,
                      right: -5,
                      child: IconButton(
                        icon: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.restore, color: Colors.green, size: 28),
                        ),
                        onPressed: () => fileProvider.restoreFile(file), 
                      ),
                    )
                  ],
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, 
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
          ),
          icon: const Icon(Icons.delete_forever),
          label: const Text("DELETE ALL PERMANENTLY", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          onPressed: fileProvider.deleteQueue.isEmpty 
              ? null 
              : () {
                  fileProvider.commitDeletion();
                  Navigator.pop(context);
                },
        ),
      ),
    );
  }

  Widget _buildMiniPreview(FileSystemEntity file, String extension, BuildContext context) {
    if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      return Image.file(File(file.path), fit: BoxFit.cover, cacheWidth: 200);
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return Container(color: Colors.red.withValues(alpha: 0.1), child: const Icon(Icons.videocam, size: 40, color: Colors.red));
    } else if (['mp3', 'wav', 'aac'].contains(extension)) {
      return Container(color: Colors.orange.withValues(alpha: 0.1), child: const Icon(Icons.audiotrack, size: 40, color: Colors.orange));
    } else if (extension == 'pdf') {
       return Container(color: Colors.blue.withValues(alpha: 0.1), child: const Icon(Icons.picture_as_pdf, size: 40, color: Colors.blue));
    } else {
      return Container(color: Colors.grey.withValues(alpha: 0.1), child: Icon(Icons.insert_drive_file, size: 40, color: Theme.of(context).primaryColor));
    }
  }
}