import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kucits/firebase_options.dart';
import 'screens/timeline_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KucITSApp());
}

class KucITSApp extends StatefulWidget {
  const KucITSApp({super.key});

  @override
  State<KucITSApp> createState() => _KucITSAppState();
}

class _KucITSAppState extends State<KucITSApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seed = Colors.orange;
    return MaterialApp(
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
      themeMode: _themeMode,
      home: TimelineScreen(onToggleTheme: _toggleTheme),
    );
  }
}
