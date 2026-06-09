import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kucits/firebase_options.dart';

// Services
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/cat_service.dart';
import 'services/post_service.dart';
import 'services/storage_service.dart';

import 'app/theme_provider.dart';

// Router
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CatService().seedCatsIfEmpty();
  runApp(const KucITSApp());
}

class KucITSApp extends StatelessWidget {
  const KucITSApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Colors.orange;

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
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: seed),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
