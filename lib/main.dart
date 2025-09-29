import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sikkim_app/screens/homescreen.dart';
import 'package:sikkim_app/screens/maps.dart';
import 'package:sikkim_app/screens/chatbot.dart';
import 'package:sikkim_app/screens/main_shell.dart';
import 'package:sikkim_app/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Optimize for better memory management
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage persistence
  await Hive.initFlutter();
  await Hive.openBox('guide_cache');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Anonymous sign-in removed - will be handled by login.dart
  Gemini.init(
    apiKey: const String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: 'AIzaSyCMdybWPrh8J3cAu62vIyfFbB6GO3jtaRo',
    ),
  );
  _configureHighRefresh();
  
  // Set preferred orientations to reduce graphics buffer usage
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Enable memory pressure handling
  SystemChannels.platform.setMethodCallHandler((call) async {
    if (call.method == 'System.gc') {
      // Handle garbage collection requests
      return;
    }
  });
  
  runApp(const MyApp());
}

Future<void> _configureHighRefresh() async {
  try {
    // Request highest available refresh rate on Android devices that support it
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (_) {
    // ignore if not supported
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in using shared preferences
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: (_isLoggedIn && FirebaseAuth.instance.currentUser != null)
          ? const MainShell()
          : const LoginScreen(),
    );
  }
}
