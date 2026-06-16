import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kucits/firebase_options.dart';

// Services
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/cat_service.dart';
import 'services/post_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'app/theme_provider.dart';
import 'app/theme.dart';

// Router
import 'app/router.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Route Flutter and async errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  NotificationService.messengerKey = scaffoldMessengerKey;
  await NotificationService.initialize();

  CatService().seedCatsIfEmpty();

  runApp(const KucITSApp());
}

class KucITSApp extends StatelessWidget {
  const KucITSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<UserService>(create: (_) => UserService()),
        Provider<CatService>(create: (_) => CatService()),
        Provider<PostService>(create: (_) => PostService()),
        Provider<StorageService>(create: (_) => StorageService()),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          return MaterialApp.router(
            title: 'KucITS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
            scaffoldMessengerKey: scaffoldMessengerKey,
          );
        },
      ),
    );
  }
}
