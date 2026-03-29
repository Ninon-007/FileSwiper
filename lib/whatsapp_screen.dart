import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'file_provider.dart';
import 'home_screen.dart';

class WhatsAppMenuScreen extends StatefulWidget {
  const WhatsAppMenuScreen({super.key});

  @override
  State<WhatsAppMenuScreen> createState() => _WhatsAppMenuScreenState();
}

class _WhatsAppMenuScreenState extends State<WhatsAppMenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    
    // Base path for Android 11+
    String basePath = '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "WhatsApp Cleaner",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildAnimatedItem(
              index: 0,
              child: Hero(
                tag: 'whatsapp_icon',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FontAwesomeIcons.whatsapp,
                    size: 60,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildAnimatedItem(
              index: 1,
              child: Text(
                "Select a category to clean",
                style: GoogleFonts.lexend(
                  fontSize: 18, 
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildAnimatedItem(
                    index: 2,
                    child: _buildOption(
                      context,
                      "Images",
                      Icons.image,
                      Colors.green,
                      "$basePath/WhatsApp Images",
                    ),
                  ),
                  _buildAnimatedItem(
                    index: 3,
                    child: _buildOption(
                      context,
                      "Videos",
                      Icons.videocam,
                      Colors.red,
                      "$basePath/WhatsApp Video",
                    ),
                  ),
                  _buildAnimatedItem(
                    index: 4,
                    child: _buildOption(
                      context,
                      "Audio",
                      Icons.audiotrack,
                      Colors.orange,
                      "$basePath/WhatsApp Audio",
                    ),
                  ),
                  _buildAnimatedItem(
                    index: 5,
                    child: _buildOption(
                      context,
                      "Documents",
                      Icons.description,
                      Colors.blue,
                      "$basePath/WhatsApp Documents",
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            offset: Offset(0, 30 * (1 - curve.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String path,
  ) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Provider.of<FileProvider>(context, listen: false).setTargetFolder(path);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
