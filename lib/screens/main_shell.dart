import 'package:flutter/material.dart';
import 'package:sikkim_app/screens/homescreen.dart';
import 'package:sikkim_app/screens/maps.dart';
import 'package:sikkim_app/screens/chatbot.dart';
import 'package:sikkim_app/screens/profile.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  late final PageController _pageController;
  final List<Widget> _screens = [
    const Home(),
    StreetViewExample(),
    const Chatbot(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (int pageIndex) {
          setState(() => _index = pageIndex);
        },
        children: _screens,
      ),
      bottomNavigationBar: _buildIOSLiquidGlassNav(),
    );
  }

  Widget _buildIOSLiquidGlassNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1127),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildIOSNavItem(Icons.home_rounded, "HOME", 0)),
          Expanded(child: _buildIOSNavItem(Icons.map_rounded, "MAP", 1)),
          Expanded(child: _buildIOSNavItem(Icons.headphones_rounded, "AUDIO GUIDE", 2)),
          Expanded(child: _buildIOSNavItem(Icons.person_rounded, "ACCOUNT", 3)),
        ],
      ),
    );
  }

  Widget _buildIOSNavItem(IconData icon, String label, int index) {
    bool isSelected = _index == index;
    const selectedColor = Color(0xFF4A90FF);

    return GestureDetector(
      onTap: () {
        if (_index != index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? selectedColor
                  : Colors.white.withOpacity(0.45),
              size: 26,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? selectedColor
                    : Colors.white.withOpacity(0.45),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
