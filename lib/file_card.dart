import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'file_provider.dart';

class FileCard extends StatefulWidget {
  final FileSystemEntity file;
  const FileCard({super.key, required this.file});

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isVideoInitialized = false;
  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
    _initVideoIfNeeded();
  }

  Future<void> _loadThumbnail() async {
    String extension = widget.file.path.split('.').last.toLowerCase();
    if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      final thumb = await fileProvider.getThumbnail(widget.file.path);
      if (mounted) {
        setState(() => _thumbnail = thumb);
      }
    }
  }

  @override
  void didUpdateWidget(FileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _stopAndResetAudio();
      _disposeVideoController();
      _thumbnail = null;
      _loadThumbnail();
      _initVideoIfNeeded();
    }
  }

  @override
  void dispose() {
    _stopAndResetAudio();
    _disposeVideoController();
    super.dispose();
  }

  void _initVideoIfNeeded() {
    String extension = widget.file.path.split('.').last.toLowerCase();
    if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      _videoController = VideoPlayerController.file(File(widget.file.path))
        ..initialize()
            .then((_) {
              if (mounted) {
                setState(() {
                  _isVideoInitialized = true;
                  _videoController?.setLooping(true);
                  _videoController?.play();
                  _videoController?.setVolume(0);
                  _isPlaying = true;
                });
              }
            })
            .catchError((error) {
              debugPrint("Video player initialization failed: $error");
            });
    }
  }

  void _disposeVideoController() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
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

  void _toggleVideo() {
    if (_videoController == null || !_isVideoInitialized) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      setState(() => _isPlaying = false);
    } else {
      _videoController!.play();
      setState(() => _isPlaying = true);
    }
  }

  Widget _buildVideoControls(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isPlaying
            ? Icons.pause_circle_outline_rounded
            : Icons.play_circle_outline_rounded,
        size: 24,
        color: Theme.of(context).primaryColor,
      ),
      onPressed: _toggleVideo,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(4),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showInfoSheet(BuildContext context) {
    final theme = Theme.of(context);
    final stat = File(widget.file.path).statSync();
    final size = (stat.size / 1024 / 1024).toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "File Details",
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              Icons.description_outlined,
              "Name",
              widget.file.path.split('/').last,
            ),
            _buildInfoRow(Icons.folder_outlined, "Path", widget.file.path),
            _buildInfoRow(Icons.straighten_rounded, "Size", "$size MB"),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              "Modified",
              stat.modified.toString().split('.')[0],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String extension = widget.file.path.split('.').last.toLowerCase();
    String fileName = widget.file.path.split('/').last;

    return Card(
      key: ValueKey(widget.file.path),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(35),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Video Controls (Pause/Resume)
                      if (['mp4', 'mov', 'avi', 'mkv'].contains(extension))
                        _buildVideoControls(context),

                      IconButton(
                        icon: const Icon(Icons.share_outlined, size: 20),
                        onPressed: () async {
                          final path = widget.file.path;
                          // ✅ Updated strictly for share_plus ^12.0 syntax
                          await SharePlus.instance.share(
                            ShareParams(files: [XFile(path)]),
                          );
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded, size: 20),
                        onPressed: () {
                          if (!mounted) return;
                          _showInfoSheet(context);
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTag(extension.toUpperCase(), context),
                      const Spacer(),
                      Text(
                        "${(File(widget.file.path).lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
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
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 80,
            color: Colors.grey,
          ),
        ),
      );
    } else if (extension == 'pdf') {
      return PDFView(
        key: ValueKey(file.path),
        filePath: file.path,
        enableSwipe: false,
        autoSpacing: false,
        pageFling: false,
        onError: (e) =>
            const Center(child: Icon(Icons.error, color: Colors.red)),
      );
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      if (_videoController != null && _isVideoInitialized) {
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio.clamp(0.1, 10.0),
          child: VideoPlayer(_videoController!),
        );
      }
      // Show thumbnail while loading if available
      if (_thumbnail != null) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.memory(
                _thumbnail!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.black12),
              ),
            ),
            const CircularProgressIndicator(strokeWidth: 2),
          ],
        );
      }
      return const Center(child: CircularProgressIndicator());
    } else if (['mp3', 'wav', 'aac', 'm4a', 'opus'].contains(extension)) {
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
    } else if (extension == 'apk') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.android, size: 80, color: Colors.green),
          SizedBox(height: 10),
          Text("Android App Installer", style: TextStyle(color: Colors.grey)),
        ],
      );
    } else {
      String fileName = file.path.split('/').last;
      String letter = fileName.isNotEmpty ? fileName[0].toUpperCase() : "?";
      Color lockedColor =
          Colors.primaries[fileName.hashCode.abs() % Colors.primaries.length];
      return Container(
        color: lockedColor.withValues(alpha: 0.2),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.bold,
              color: lockedColor,
            ),
          ),
        ),
      );
    }
  } // ✅ Missing bracket successfully restored!

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
}
