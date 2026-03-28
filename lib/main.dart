import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'file_provider.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

class ThemeProvider with ChangeNotifier {
  String _currentTheme;
  ThemeProvider(this._currentTheme);
  String get currentTheme => _currentTheme;

  void setTheme(String theme) async {
    _currentTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', theme);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool seenOnboarding = false;
  String savedTheme = 'peach';

  try {
    final prefs = await SharedPreferences.getInstance();
    seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    savedTheme = prefs.getString('selected_theme') ?? 'peach';
  } catch (e) {
    debugPrint("Error reading preferences: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(savedTheme)),
      ],
      child: FileSwiperApp(seenOnboarding: seenOnboarding),
    ),
  );
}

class FileSwiperApp extends StatelessWidget {
  final bool seenOnboarding;

  const FileSwiperApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        bool isPeach = themeProvider.currentTheme == 'peach';

        ThemeData peachTheme = ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFFF5F0),
          cardColor: const Color(0xFFFBE8D5),
          primaryColor: const Color(0xFFFF8A65),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFF333333),
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          textTheme: GoogleFonts.lexendTextTheme(),
          iconTheme: const IconThemeData(color: Color(0xFF333333)),
        );

        ThemeData darkTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF1E1E1E),
          primaryColor: Colors.deepPurpleAccent,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme),
          iconTheme: const IconThemeData(color: Colors.white),
        );

        ThemeData lightTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          scaffoldBackgroundColor: Colors.grey[100],
          cardColor: Colors.white,
          primaryColor: Colors.deepPurple,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          textTheme: GoogleFonts.lexendTextTheme(ThemeData.light().textTheme),
          iconTheme: const IconThemeData(color: Colors.black),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Fileswiper',
          themeMode: isPeach ? ThemeMode.light : ThemeMode.system,
          theme: isPeach ? peachTheme : lightTheme,
          darkTheme: isPeach ? peachTheme : darkTheme,
          home: seenOnboarding
              ? const DashboardScreen()
              : const OnboardingScreen(),
        );
      },
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
  bool _showTutorial = false;
  bool _isFinished = false; // ✅ Added to track when the deck empties

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('seen_swipe_tutorial') ?? false;
    if (!seen) {
      setState(() => _showTutorial = true);
    }
  }

  Future<void> _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_swipe_tutorial', true);
    setState(() => _showTutorial = false);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 8.0, bottom: 8.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeleteQueueScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${fileProvider.deleteQueue.length}",
                      style: GoogleFonts.lexend(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: fileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (fileProvider.files.isEmpty ||
                _isFinished) // ✅ NOW CHECKS IF FINISHED
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined, // Changed to a premium box icon
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  // ✅ UPDATED PREMIUM END MESSAGE
                  Text(
                    "Folder completely scanned!",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "You've reviewed all files here.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Return to Dashboard",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: CardSwiper(
                            controller: controller,
                            cardsCount: fileProvider.files.length,
                            isLoop: false,
                            // ✅ THIS TRIGGERS THE "END OF FILES" SCREEN
                            onEnd: () {
                              setState(() {
                                _isFinished = true;
                              });
                            },
                            onSwipe:
                                (
                                  int previousIndex,
                                  int? currentIndex,
                                  CardSwiperDirection direction,
                                ) {
                                  HapticFeedback.mediumImpact();
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
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 60.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildPremiumButton(
                                Icons.close_rounded,
                                Colors.redAccent,
                                () =>
                                    controller.swipe(CardSwiperDirection.left),
                                context,
                              ),
                              _buildPremiumButton(
                                Icons.check_rounded,
                                Colors.green,
                                () =>
                                    controller.swipe(CardSwiperDirection.right),
                                context,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showTutorial && fileProvider.files.isNotEmpty)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.8),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 80,
                            right: 30,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Review & delete\nhere",
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        const Icon(
                                          Icons.swipe_left_rounded,
                                          color: Colors.redAccent,
                                          size: 60,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Swipe Left\nto Delete",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.lexend(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Icon(
                                          Icons.swipe_right_rounded,
                                          color: Colors.greenAccent,
                                          size: 60,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Swipe Right\nto Keep",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.lexend(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 80),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF8A65),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 15,
                                    ),
                                  ),
                                  onPressed: _dismissTutorial,
                                  child: Text(
                                    "GOT IT!",
                                    style: GoogleFonts.lexend(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildPremiumButton(
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 38),
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
          ? Center(
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
            )
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
                                child: _buildMiniPreview(
                                  file,
                                  extension,
                                  context,
                                ),
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
                          child: const Icon(
                            Icons.restore,
                            color: Colors.green,
                            size: 28,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          fileProvider.restoreFile(file);
                        },
                      ),
                    ),
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
              : () {
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
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 28,
                            ),
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
                            child: const Text(
                              "CANCEL",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              fileProvider.prepareCommitDeletion();
                              Navigator.pop(dialogContext);
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Files marked for permanent deletion.",
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
                                      duration: const Duration(seconds: 4),
                                      action: SnackBarAction(
                                        label: "UNDO",
                                        textColor: const Color(0xFFFF8A65),
                                        onPressed: () {
                                          fileProvider.undoCommitDeletion();
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
                            },
                            child: const Text("DELETE ALL"),
                          ),
                        ],
                      );
                    },
                  );
                },
        ),
      ),
    );
  }

  Widget _buildMiniPreview(
    FileSystemEntity file,
    String extension,
    BuildContext context,
  ) {
    if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      return Image.file(File(file.path), fit: BoxFit.cover, cacheWidth: 200);
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return Container(
        color: Colors.red.withValues(alpha: 0.1),
        child: const Icon(Icons.videocam, size: 40, color: Colors.red),
      );
    } else if (['mp3', 'wav', 'aac'].contains(extension)) {
      return Container(
        color: Colors.orange.withValues(alpha: 0.1),
        child: const Icon(Icons.audiotrack, size: 40, color: Colors.orange),
      );
    } else if (extension == 'pdf') {
      return Container(
        color: Colors.blue.withValues(alpha: 0.1),
        child: const Icon(Icons.picture_as_pdf, size: 40, color: Colors.blue),
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
