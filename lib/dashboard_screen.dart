import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'file_provider.dart';
import 'main.dart';
import 'whatsapp_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Removed hardcoded background color, letting the Theme take over
      appBar: AppBar(
        title: const Text(
          "File Swiper",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        // ✅ Removed hardcoded AppBar colors
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            // ✅ Brush container completely removed
            const SizedBox(height: 10), // A little breathing room at the top
            // The 4 Main Options
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio:
                    1.1, // ✅ Makes the cards slightly more rectangular/smaller
                children: [
                  _buildDashboardCard(
                    context,
                    title: "WhatsApp",
                    icon: FontAwesomeIcons.whatsapp,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WhatsAppMenuScreen(),
                      ),
                    ),
                  ),
                  _buildDashboardCard(
                    context,
                    title: "Downloads",
                    icon: Icons.download,
                    color: Colors.blue,
                    onTap: () => _openDownloadsCleaner(context),
                  ),
                  _buildDashboardCard(
                    context,
                    title: "Gallery",
                    icon: Icons.photo_library,
                    color: Colors.purple,
                    onTap: () => _openGalleryCleaner(context),
                  ),
                  _buildDashboardCard(
                    context,
                    title: "Custom Folder",
                    icon: Icons.folder_open,
                    color: Colors.orange,
                    onTap: () => _pickCustomFolder(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, // ✅ Uses system theme card color
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ), // Subtle colored border
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(
                14,
              ), // ✅ Slightly smaller icon container
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ), // ✅ Slightly smaller icon
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color, // ✅ Adapts to dark/light text
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDownloadsCleaner(BuildContext context) {
    Provider.of<FileProvider>(
      context,
      listen: false,
    ).setTargetFolder('/storage/emulated/0/Download');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _openGalleryCleaner(BuildContext context) {
    Provider.of<FileProvider>(
      context,
      listen: false,
    ).setTargetFolder('/storage/emulated/0/DCIM/Camera');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _pickCustomFolder(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (!context.mounted) return;
    if (selectedDirectory != null) {
      Provider.of<FileProvider>(
        context,
        listen: false,
      ).setTargetFolder(selectedDirectory);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}
