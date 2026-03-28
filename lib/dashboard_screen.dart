import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:disk_space_2/disk_space_2.dart';

import 'file_provider.dart';
import 'main.dart';
import 'whatsapp_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _totalSpace = 0;
  double _usedSpace = 0;
  double _percent = 0;

  @override
  void initState() {
    super.initState();
    _fetchStorage();
  }

  // ✅ REAL STORAGE LOGIC
  Future<void> _fetchStorage() async {
    double? free = await DiskSpace.getFreeDiskSpace;
    double? total = await DiskSpace.getTotalDiskSpace;

    if (free != null && total != null && mounted) {
      setState(() {
        _totalSpace = total / 1024; // Convert MB to GB
        double freeSpace = free / 1024;
        _usedSpace = _totalSpace - freeSpace;
        _percent = _usedSpace / _totalSpace;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically pulls colors from the active theme (Peach vs System Dark/Light)
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    Color cardColor = Theme.of(context).cardColor;
    Color accentColor = Theme.of(context).primaryColor;
    Color textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // --- TOP ROW: GREETING & THEME TOGGLE ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hey there,",
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                  // ✅ THEME TOGGLE MENU
                  PopupMenuButton<String>(
                    icon: Icon(Icons.palette_outlined, color: textColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    onSelected: (value) {
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).setTheme(value);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'peach',
                        child: Text("Peach Theme"),
                      ),
                      const PopupMenuItem(
                        value: 'system',
                        child: Text("System Default"),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                "Ready to clean?",
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 30),

              // --- STORAGE OVERVIEW CARD ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 45.0,
                      lineWidth: 12.0,
                      animation: true,
                      percent: _percent.clamp(
                        0.0,
                        1.0,
                      ), // Bound between 0 and 1
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: accentColor,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      center: Icon(
                        Icons.pie_chart,
                        color: accentColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Accessible Storage", // ✅ Changed to make sense of the GB difference
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // LIVE DATA IN GB
                          Text(
                            "${_usedSpace.toStringAsFixed(1)}/${_totalSpace.toStringAsFixed(1)} GB used",
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              color: textColor.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          // ✅ Added disclaimer for OS storage
                          Text(
                            "*Excludes hidden system files",
                            style: GoogleFonts.lexend(
                              fontSize: 10,
                              color: textColor.withValues(alpha: 0.4),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildLegendDot(accentColor, false),
                              const SizedBox(width: 4),
                              Text(
                                "Used",
                                style: GoogleFonts.lexend(
                                  fontSize: 11,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildLegendDot(Colors.transparent, true),
                              const SizedBox(width: 4),
                              Text(
                                "Available",
                                style: GoogleFonts.lexend(
                                  fontSize: 11,
                                  color: textColor.withValues(alpha: 0.6),
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
              const SizedBox(height: 40),

              Text(
                "Categories",
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),

              // --- CATEGORIES LIST ---
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildCategoryPill(
                      context,
                      "WhatsApp",
                      FontAwesomeIcons.whatsapp,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WhatsAppMenuScreen(),
                        ),
                      ),
                    ),
                    _buildCategoryPill(
                      context,
                      "Downloads",
                      Icons.download_rounded,
                      () => _openDownloadsCleaner(context),
                    ),
                    _buildCategoryPill(
                      context,
                      "Gallery",
                      Icons.photo_library_rounded,
                      () => _openGalleryCleaner(context),
                    ),
                    _buildCategoryPill(
                      context,
                      "Custom Folder",
                      Icons.folder_open_rounded,
                      () => _pickCustomFolder(context),
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

  Widget _buildLegendDot(Color color, bool isBordered) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isBordered ? Border.all(color: Colors.grey) : null,
      ),
    );
  }

  Widget _buildCategoryPill(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    Color cardColor = Theme.of(context).cardColor;
    Color accentColor = Theme.of(context).primaryColor;
    Color textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.play_arrow_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
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
