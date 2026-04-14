import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'providers/articles_provider.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'screens/feed_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise WorkManager with the background callback dispatcher
  await Workmanager().initialize(callbackDispatcher);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ArticlesProvider(),
      child: const AiPulseApp(),
    ),
  );
}

class AiPulseApp extends StatelessWidget {
  const AiPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ArticlesProvider>().themeMode;
    return MaterialApp(
      title: 'AI Pulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const _MainShell(),
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    FeedScreen(),
    SavedScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await NotificationService.instance.init();
    if (mounted) {
      await context.read<ArticlesProvider>().init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticlesProvider>();
    final isDark = provider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : null,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: PulseBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
