import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_provider.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';
import 'theme.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

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

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Fileswiper',
          themeMode: isPeach ? ThemeMode.light : ThemeMode.system,
          theme: isPeach ? AppTheme.peachTheme : AppTheme.lightTheme,
          darkTheme: isPeach ? AppTheme.peachTheme : AppTheme.darkTheme,
          navigatorObservers: [routeObserver],
          home: seenOnboarding
              ? const DashboardScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }
}
