import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'file_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'whatsapp_screen.dart'; // ✅ NEW IMPORT
import 'main.dart'; // To navigate to the Swiper Screen

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "File Swiper",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header / Logo Area
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.cleaning_services,
                  size: 60,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // The 4 Main Options
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildDashboardCard(
                    context,
                    title: "WhatsApp",
                    icon: FontAwesomeIcons.whatsapp, // ✅ OFFICIAL ICON
                    color: Colors.green,
                    onTap: () {
                      // ✅ GO TO SUB-MENU INSTEAD OF DIRECT SWIPER
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WhatsAppMenuScreen(),
                        ),
                      );
                    },
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Logic for Buttons ---

  void _openDownloadsCleaner(BuildContext context) {
    // 1. Set the provider to target Downloads
    Provider.of<FileProvider>(
      context,
      listen: false,
    ).setTargetFolder('/storage/emulated/0/Download');

    // 2. Navigate to Swiper
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _openGalleryCleaner(BuildContext context) {
    // Standard Camera folder
    String path = '/storage/emulated/0/DCIM/Camera';

    Provider.of<FileProvider>(context, listen: false).setTargetFolder(path);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _pickCustomFolder(BuildContext context) async {
    // Pick a folder
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    // ✅ SAFETY CHECK: unexpected things happen if we don't check if the screen is still there
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
