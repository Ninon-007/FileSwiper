import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'file_provider.dart';
import 'main.dart';
import 'whatsapp_screen.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin, RouteAware {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    // Storage refresh is now handled by provider or manual call
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _staggerController.forward();
    
    // Initial fetch from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FileProvider>(context, listen: false).refreshStorage();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _staggerController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this screen
    Provider.of<FileProvider>(context, listen: false).refreshStorage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onSurface;
    final fileProvider = Provider.of<FileProvider>(context);

    return Scaffold(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hey there,",
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        "Fileswiper",
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.palette_outlined, color: theme.primaryColor),
                    ),
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
              const SizedBox(height: 30),

              // --- STORAGE OVERVIEW CARD ---
              _buildAnimatedItem(
                index: 0,
                child: GestureDetector(
                  onTap: () => fileProvider.refreshStorage(), // Manual refresh on tap
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.05),
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
                          percent: fileProvider.percent.clamp(0.0, 1.0),
                          circularStrokeCap: CircularStrokeCap.round,
                          progressColor: theme.primaryColor,
                          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                          center: Icon(
                            Icons.pie_chart,
                            color: theme.primaryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Accessible Storage",
                                style: GoogleFonts.lexend(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${fileProvider.usedSpace.toStringAsFixed(1)}/${fileProvider.totalSpace.toStringAsFixed(1)} GB used",
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  color: textColor.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildLegendDot(theme.primaryColor, false),
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
                    _buildAnimatedItem(
                      index: 1,
                      child: _buildCategoryPill(
                        context,
                        "WhatsApp",
                        FontAwesomeIcons.whatsapp,
                        () async {
                          final navigator = Navigator.of(context);
                          final fileProvider = Provider.of<FileProvider>(context, listen: false);
                          await navigator.push(
                            MaterialPageRoute(
                              builder: (_) => const WhatsAppMenuScreen(),
                            ),
                          );
                          fileProvider.refreshStorage();
                        },
                      ),
                    ),
                    _buildAnimatedItem(
                      index: 2,
                      child: _buildCategoryPill(
                        context,
                        "Downloads",
                        Icons.download_rounded,
                        () => _openDownloadsCleaner(context),
                      ),
                    ),
                    _buildAnimatedItem(
                      index: 3,
                      child: _buildCategoryPill(
                        context,
                        "Gallery",
                        Icons.photo_library_rounded,
                        () => _openGalleryCleaner(context),
                      ),
                    ),
                    _buildAnimatedItem(
                      index: 4,
                      child: _buildCategoryPill(
                        context,
                        "Custom Folder",
                        Icons.folder_open_rounded,
                        () => _pickCustomFolder(context),
                      ),
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

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        final start = index * 0.1;
        final end = start + 0.5;
        final curve = CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        );
        return Opacity(
          opacity: curve.value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - curve.value)),
            child: child,
          ),
        );
      },
      child: child,
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
    final theme = Theme.of(context);
    final accentColor = theme.primaryColor;
    final textColor = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accentColor.withValues(alpha: 0.1)),
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
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: textColor.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDownloadsCleaner(BuildContext context) async {
    final navigator = Navigator.of(context);
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    fileProvider.setTargetFolder('/storage/emulated/0/Download');
    await navigator.push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
    fileProvider.refreshStorage();
  }

  Future<void> _openGalleryCleaner(BuildContext context) async {
    final navigator = Navigator.of(context);
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    fileProvider.setTargetFolder('/storage/emulated/0/DCIM/Camera');
    await navigator.push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
    fileProvider.refreshStorage();
  }

  Future<void> _pickCustomFolder(BuildContext context) async {
    final navigator = Navigator.of(context);
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      fileProvider.setTargetFolder(selectedDirectory);
      await navigator.push(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      fileProvider.refreshStorage();
    }
  }
}
