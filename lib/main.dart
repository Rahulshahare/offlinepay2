import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait only — payment app should not rotate
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const OfflinePayApp());
}

class OfflinePayApp extends StatelessWidget {
  const OfflinePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OfflinePay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
