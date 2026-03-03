import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'file_provider.dart';
import 'main.dart'; // To navigate to Swiper

class WhatsAppMenuScreen extends StatelessWidget {
  const WhatsAppMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Base path for Android 11+ (Adjust if needed for older phones)
    String basePath =
        '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "WhatsApp Cleaner",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              FontAwesomeIcons.whatsapp,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              "Select a category to clean",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildOption(
                    context,
                    "Images",
                    Icons.image,
                    Colors.green,
                    "$basePath/WhatsApp Images",
                  ),
                  _buildOption(
                    context,
                    "Videos",
                    Icons.videocam,
                    Colors.red,
                    "$basePath/WhatsApp Video",
                  ),
                  _buildOption(
                    context,
                    "Audio",
                    Icons.audiotrack,
                    Colors.orange,
                    "$basePath/WhatsApp Audio",
                  ),
                  _buildOption(
                    context,
                    "Documents",
                    Icons.description,
                    Colors.blue,
                    "$basePath/WhatsApp Documents",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String path,
  ) {
    return GestureDetector(
      onTap: () {
        Provider.of<FileProvider>(context, listen: false).setTargetFolder(path);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
