import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null || _user == null) return;

      setState(() => _isUploading = true);
      
      final file = File(pickedFile.path);
      
      // Get file extension to support gifs, pngs, jpgs, etc.
      final extension = pickedFile.name.split('.').last;
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${_user!.uid}_${DateTime.now().millisecondsSinceEpoch}.$extension');
          
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      
      await _user!.updatePhotoURL(downloadUrl);
      // Reload the user after profile update to get latest properties
      await _user!.reload();
      
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _isUploading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      try {
        final box = Hive.box('guide_cache');
        await box.delete('cached_messages');
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userId');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeUsername() async {
    if (_user == null) return;
    
    final TextEditingController nameController = TextEditingController(text: _user!.displayName ?? '');
    
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Change Username', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter new username',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
              child: const Text('Save', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != _user!.displayName) {
      try {
        await _user!.updateDisplayName(newName);
        await _user!.reload();
        setState(() {
          _user = FirebaseAuth.instance.currentUser;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username updated successfully!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update username: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildTile(IconData icon, String title) {
    const Color surfaceColor = Color(0xFF1E293B);
    const Color primaryColor = Color(0xFF2563EB);
    const Color textColor = Colors.white;
    const Color textMuted = Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: textMuted, size: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF0F172A);
    const Color primaryColor = Color(0xFF2563EB);
    const Color textColor = Colors.white;
    const Color textMuted = Color(0xFF94A3B8);
    const Color redColor = Color(0xFFCC0000);

    final String displayName = _user?.displayName ?? 'Tashi Delek';
    final String email = _user?.email ?? 'tashi.delek@sikkimtravel.com';
    final String? photoUrl = _user?.photoURL;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Might not do anything depending on nav stack, but present in design
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: primaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Profile Image with Camera Icon Overlay
            Center(
              child: GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor.withValues(alpha:0.5), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: _isUploading
                            ? const CircularProgressIndicator(color: primaryColor)
                            : (photoUrl == null
                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                : null),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name and Edit Icon
            GestureDetector(
              onTap: _changeUsername,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, color: textMuted, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              email,
              style: const TextStyle(
                color: textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            // Preferences and Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACCOUNT SETTINGS',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTile(Icons.person_outline, 'Personal Information'),
                  _buildTile(Icons.outlined_flag, 'My Travel History'),
                  const SizedBox(height: 24),
                  const Text(
                    'PREFERENCES',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTile(Icons.notifications_none, 'Notifications'),
                  const SizedBox(height: 32),
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Version Footer
                  const Center(
                    child: Text(
                      'Sikkim Travel App v2.4.0',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
