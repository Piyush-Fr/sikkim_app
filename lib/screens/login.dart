import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
    serverClientId: '1081985017914-bs3aufagjsn2ioegmttrmea3f896cg5t.apps.googleusercontent.com',
  );
  bool _isLoading = false;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print('Initializing video: assets/videos/login_bg.mp4');
      _videoController = VideoPlayerController.asset(
        'assets/videos/login_bg.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      print('Video controller created, initializing...');
      await _videoController!.initialize();
      print('Video initialized successfully');

      // Add listener for video state changes
      _videoController!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      _videoController!.setLooping(true);
      _videoController!.setVolume(0.0); // Mute the video

      print('Starting video playback...');
      await _videoController!.play();
      print('Video playback started');

      if (mounted) {
        setState(() {
          _videoInitialized = true;
        });
        print('Video state updated to initialized');
      }
    } catch (e) {
      print('Video initialization error: $e');
      print('Error type: ${e.runtimeType}');
      if (mounted) {
        setState(() {
          _videoError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_videoController == null) return;
    if (state == AppLifecycleState.resumed) {
      // Ensure muted, looping, and playing when coming back to foreground
      _videoController!
        ..setVolume(0.0)
        ..setLooping(true);
      _videoController!.play();
    }
    // No action on pause/inactive; OS may stop playback in background.
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG [STEP 0]: Starting Google Sign-In...');
      // Ensure account chooser shows by clearing previous selection
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('DEBUG [STEP 0]: signOut failed (ignoring): $e');
      }

      // Step 1: Show account chooser
      print('DEBUG [STEP 1]: Waiting for user to select account...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Google Sign-In timed out at STEP 1 (account chooser).');
        },
      );

      if (googleUser == null) {
        print('DEBUG [STEP 1]: User canceled sign-in');
        if (mounted) {
          setState(() { _isLoading = false; });
        }
        return;
      }
      print('DEBUG [STEP 1]: Account selected: ${googleUser.email}');

      // Step 2: Get authentication tokens from Google
      print('DEBUG [STEP 2]: Getting Google auth tokens...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timed out at STEP 2 (getting auth tokens). This usually means SHA-1 fingerprint mismatch.');
        },
      );
      print('DEBUG [STEP 2]: Got tokens. AccessToken: ${googleAuth.accessToken != null}, IDToken: ${googleAuth.idToken != null}');

      // Check if we actually got the tokens
      if (googleAuth.idToken == null) {
        throw Exception(
          'idToken is null. This means the serverClientId is wrong or SHA-1 fingerprint is not registered in Firebase Console.',
        );
      }

      // Step 3: Create Firebase credential and sign in
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('DEBUG [STEP 3]: Signing in to Firebase...');
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timed out at STEP 3 (Firebase signInWithCredential).');
        },
      );
      print('DEBUG [STEP 3]: Firebase sign-in OK. User: ${userCredential.user?.uid}');

      final User? user = userCredential.user;
      if (user != null) {
        // Save login state to shared preferences first (fast, local)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', user.uid);

        // Save user data to Firestore (non-blocking - don't let this prevent navigation)
        print('DEBUG [STEP 4]: Saving user data to Firestore (non-blocking)...');
        _saveUserData(user).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('DEBUG [STEP 4]: Firestore save timed out (non-critical, continuing).');
          },
        ).catchError((e) {
          print('DEBUG [STEP 4]: Firestore save error (non-critical): $e');
        });

        // Navigate to main shell immediately
        if (mounted) {
          print('DEBUG [STEP 5]: Navigating to MainShell...');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainShell()),
          );
        }
      }
    } catch (e, stackTrace) {
      print('DEBUG: Sign-in ERROR: $e');
      print('DEBUG: StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserData(User user) async {
    // Save user data to Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video Background with fallback to image
          Positioned.fill(
            child: _videoInitialized && !_videoError && _videoController != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/home_monasery1.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
          ),

          // Black tint overlay
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha:0.4)),
          ),

          // Content
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha:0.08),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Welcome to Monastery360',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Please sign in to continue',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _signInWithGoogle,
                          icon: Image.asset(
                            'assets/images/google_logo.png',
                            height: 24,
                            width: 24,
                          ),
                          label: const Text(
                            'Login Using Google account',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _debugSkipLogin,
                    child: const Text(
                      'Skip Login (Debug)',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _debugSkipLogin() async {
    print('DEBUG: Skipping login...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', 'debug_user_123');

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainShell()),
      );
    }
  }
}
