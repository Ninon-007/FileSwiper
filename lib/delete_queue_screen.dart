import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';
import 'file_provider.dart';

class DeleteQueueScreen extends StatelessWidget {
  const DeleteQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Trash (${fileProvider.deleteQueue.length})",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        foregroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: fileProvider.deleteQueue.isEmpty
          ? _buildEmptyState()
          : _buildGridView(context, fileProvider),
      bottomNavigationBar: _buildBottomBar(context, fileProvider),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.delete_outline_rounded,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            "Trash is empty.",
            style: GoogleFonts.lexend(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(BuildContext context, FileProvider fileProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Hold a file to restore it, Tap to preview.",
                    style: GoogleFonts.lexend(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
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

              return GestureDetector(
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  fileProvider.restoreFile(file);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Restored $name"),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onTap: () => _showPreview(context, file, extension),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, FileProvider fileProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.delete_forever),
        label: Text(
          "DELETE ALL PERMANENTLY",
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        onPressed: fileProvider.deleteQueue.isEmpty
            ? null
            : () => _confirmDeletion(context, fileProvider),
      ),
    );
  }

  void _showPreview(
    BuildContext context,
    FileSystemEntity file,
    String extension,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(child: _buildFullPreview(file, extension)),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPreview(FileSystemEntity file, String extension) {
    if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      return PhotoView(
        imageProvider: FileImage(File(file.path)),
        minScale: PhotoViewComputedScale.contained,
      );
    } else if (extension == 'pdf') {
      return PDFView(filePath: file.path);
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return FullVideoPlayer(file: File(file.path));
    } else {
      return const Center(
        child: Icon(Icons.insert_drive_file, size: 100, color: Colors.white),
      );
    }
  }

  void _confirmDeletion(BuildContext context, FileProvider fileProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text("Confirm Delete"),
            ],
          ),
          content: Text(
            "Are you sure you want to permanently delete these ${fileProvider.deleteQueue.length} files?",
            style: GoogleFonts.lexend(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final messenger = ScaffoldMessenger.of(context);

                // ✅ Variable to track if the user panicked and hit UNDO
                bool isUndoClicked = false;

                fileProvider.prepareCommitDeletion();

                Navigator.pop(dialogContext);
                Navigator.pop(context);

                messenger.clearSnackBars();

                messenger
                    .showSnackBar(
                      SnackBar(
                        content: Text(
                          "Files permanently deleted!",
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.black87,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: "UNDO",
                          textColor: const Color(0xFFFF8A65),
                          onPressed: () {
                            isUndoClicked = true; // ✅ Mark that they clicked it
                            fileProvider.undoCommitDeletion();
                            messenger.hideCurrentSnackBar();
                          },
                        ),
                      ),
                    )
                    .closed
                    .then((reason) {
                      if (reason != SnackBarClosedReason.action) {
                        fileProvider.executeFinalDeletion();
                      }
                    });

                // ✅ THE OVERRIDE:
                // Force the SnackBar to close after exactly 2 seconds,
                // completely bypassing Android's accessibility blockage.
                Future.delayed(const Duration(seconds: 2), () {
                  if (!isUndoClicked) {
                    messenger.hideCurrentSnackBar();
                  }
                });
              },
              child: const Text("DELETE ALL"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniPreview(
    FileSystemEntity file,
    String extension,
    BuildContext context,
  ) {
    if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        cacheWidth: 200,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.withValues(alpha: 0.1),
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      );
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return FutureBuilder<Uint8List?>(
        future: Provider.of<FileProvider>(
          context,
          listen: false,
        ).getThumbnail(file.path),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.black12),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          }
          return Container(
            color: Colors.red.withValues(alpha: 0.1),
            child: const Icon(Icons.videocam, size: 40, color: Colors.red),
          );
        },
      );
    } else if (['mp3', 'wav', 'aac'].contains(extension)) {
      return Container(
        color: Colors.orange.withValues(alpha: 0.1),
        child: const Icon(Icons.audiotrack, size: 40, color: Colors.orange),
      );
    } else if (extension == 'pdf') {
      return Container(
        color: Colors.blue.withValues(alpha: 0.05),
        child: IgnorePointer(
          child: PDFView(
            filePath: file.path,
            enableSwipe: false,
            autoSpacing: false,
            pageFling: false,
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.grey.withValues(alpha: 0.1),
        child: Icon(
          Icons.insert_drive_file,
          size: 40,
          color: Theme.of(context).primaryColor,
        ),
      );
    }
  }
}

class FullVideoPlayer extends StatefulWidget {
  final File file;
  const FullVideoPlayer({super.key, required this.file});

  @override
  State<FullVideoPlayer> createState() => _FullVideoPlayerState();
}

class _FullVideoPlayerState extends State<FullVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
          _controller.play();
          _controller.setLooping(true);
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator());
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          VideoProgressIndicator(_controller, allowScrubbing: true),
        ],
      ),
    );
  }
}
