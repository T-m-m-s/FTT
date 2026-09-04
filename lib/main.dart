import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_shell.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge to edge translucent system status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize offline database & sample dataset
  await DatabaseService().init();

  runApp(const FreeTimeTrackerApp());
}

class FreeTimeTrackerApp extends StatelessWidget {
  const FreeTimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreeTimeTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}
