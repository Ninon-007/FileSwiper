import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ✅ New Package Import
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'file_provider.dart'; 

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FileProvider()),
      ],
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ New Controller
  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<FileProvider>(context, listen: false).loadFiles()
    );
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
      appBar: AppBar(
        title: const Text("File Swiper 🗂️"),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_sweep, size: 30),
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const DeleteQueueScreen())
                  );
                },
              ),
              if (fileProvider.deleteQueue.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${fileProvider.deleteQueue.length}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                )
            ],
          )
        ],
      ),
      body: fileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : fileProvider.errorMessage != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 10),
                      Text(fileProvider.errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => fileProvider.loadFiles(),
                        child: const Text("Retry"),
                      )
                    ],
                  ),
                ))
              : fileProvider.files.isEmpty
                  ? const Center(child: Text("Downloads folder is empty!"))
                  : Column(
                      children: [
                        Expanded(
                          // ✅ New Swiper Widget
                          child: CardSwiper(
                            controller: controller,
                            cardsCount: fileProvider.files.length,
                            onSwipe: (int previousIndex, int? currentIndex, CardSwiperDirection direction) {
                              if (direction == CardSwiperDirection.left) {
                                // Add previousIndex to delete queue
                                fileProvider.swipeLeft(previousIndex);
                              } else {
                                fileProvider.swipeRight(previousIndex);
                              }
                              return true; // Return true to allow the swipe
                            },
                            numberOfCardsDisplayed: 2, // Equivalent to backgroundCardCount
                            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                              return FileCard(file: fileProvider.files[index]);
                            },
                          ),
                        ),
                        // Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildActionButton(
                                icon: Icons.delete,
                                color: Colors.red,
                                label: "Delete",
                                onTap: () => controller.swipe(CardSwiperDirection.left),
                              ),
                              _buildActionButton(
                                icon: Icons.check,
                                color: Colors.green,
                                label: "Keep",
                                onTap: () => controller.swipe(CardSwiperDirection.right),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: color.withValues(alpha: 0.1),
          elevation: 0,
          onPressed: onTap,
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))
      ],
    );
  }
}

class FileCard extends StatelessWidget {
  final FileSystemEntity file;

  const FileCard({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    String extension = file.path.split('.').last.toLowerCase();
    String fileName = file.path.split('/').last;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  color: Colors.grey[200],
                  width: double.infinity,
                  child: _buildPreview(extension, file),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(extension.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Text(
                        "${(File(file.path).lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB",
                        style: TextStyle(color: Colors.grey[600]),
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

  Widget _buildPreview(String extension, FileSystemEntity file) {
    if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      return PhotoView(
        imageProvider: FileImage(File(file.path)),
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        minScale: PhotoViewComputedScale.contained,
      );
    } else if (extension == 'pdf') {
      return PDFView(
        filePath: file.path,
        enableSwipe: false,
        autoSpacing: false,
        pageFling: false,
        onError: (e) => Center(child: Text("Error loading PDF: $e")),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text("No preview for .$extension", style: const TextStyle(color: Colors.grey)),
        ],
      );
    }
  }
}

class DeleteQueueScreen extends StatelessWidget {
  const DeleteQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Delete Queue (${fileProvider.deleteQueue.length})"),
        backgroundColor: Colors.red[50],
      ),
      body: Column(
        children: [
          Expanded(
            child: fileProvider.deleteQueue.isEmpty
                ? const Center(child: Text("No files queued for deletion."))
                : ListView.separated(
                    itemCount: fileProvider.deleteQueue.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      String fileName = fileProvider.deleteQueue[index].path.split('/').last;
                      return ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.red),
                        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: TextButton.icon(
                          icon: const Icon(Icons.undo, size: 16),
                          label: const Text("Keep"),
                          onPressed: () {
                            fileProvider.undoLastDelete();
                          },
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("PERMANENTLY DELETE ALL", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: fileProvider.deleteQueue.isEmpty 
                    ? null 
                    : () async {
                        await fileProvider.commitDeletion();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Files deleted successfully"))
                          );
                        }
                      },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}