import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_provider.dart';
import 'file_card.dart';
import 'delete_queue_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();
  bool _showTutorial = false;
  bool _isFinished = false;

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
    final theme = Theme.of(context);

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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
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
          : (fileProvider.files.isEmpty || _isFinished)
              ? _buildFinishedState(context)
              : Stack(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 7,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 0.0),
                              child: CardSwiper(
                                controller: controller,
                                cardsCount: fileProvider.files.length,
                                isLoop: false,
                                onEnd: () {
                                  setState(() {
                                    _isFinished = true;
                                  });
                                },
                                onSwipe: (
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
                                  
                                  // Prefetch next 3 thumbnails
                                  if (currentIndex != null) {
                                    fileProvider.prefetchThumbnails(currentIndex, 3);
                                  }
                                  
                                  return true;
                                },
                                numberOfCardsDisplayed: 3,
                                cardBuilder: (context, index, x, y) {
                                  return Hero(
                                    tag: fileProvider.files[index].path,
                                    child: FileCard(file: fileProvider.files[index]),
                                  );
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
                                    () {
                                      controller.swipe(CardSwiperDirection.left);
                                    },
                                    context,
                                  ),
                                  _buildPremiumButton(
                                    Icons.undo_rounded,
                                    theme.primaryColor,
                                    () {
                                      controller.undo();
                                      fileProvider.undoSwipe(0);
                                      HapticFeedback.mediumImpact();
                                    },
                                    context,
                                    isSmall: true,
                                  ),
                                  _buildPremiumButton(
                                    Icons.check_rounded,
                                    Colors.green,
                                    () {
                                      controller.swipe(CardSwiperDirection.right);
                                    },
                                    context,
                                  ),                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showTutorial && fileProvider.files.isNotEmpty)
                      _buildTutorialOverlay(context),
                  ],
                ),
    );
  }

  Widget _buildFinishedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 20),
          Text(
            "Folder completely scanned!",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            "You've reviewed all files here.",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Return to Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialOverlay(BuildContext context) {
    return Positioned.fill(
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                      backgroundColor: Theme.of(context).primaryColor,
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
    );
  }

  Widget _buildPremiumButton(
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context, {
    bool isSmall = false,
  }) {
    double size = isSmall ? 60 : 75;
    double iconSize = isSmall ? 28 : 38;
    return Container(
      width: size,
      height: size,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          customBorder: const CircleBorder(),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}
