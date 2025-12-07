/// HeadsUp - Minimalist posture tracking app
/// Main entry point
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  // Initialize notifications and restore scheduled reminders
  await NotificationService().initialize();
  await NotificationService().restoreRemindersFromPrefs();
  
  runApp(const ProviderScope(child: HeadsUpApp()));
}

class HeadsUpApp extends StatelessWidget {
  const HeadsUpApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'HeadsUp',
      debugShowCheckedModeBanner: false,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
