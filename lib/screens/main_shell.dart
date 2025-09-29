import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sikkim_app/screens/homescreen.dart';
import 'package:sikkim_app/screens/maps.dart';
import 'package:sikkim_app/screens/chatbot.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final List<Widget> _screens = [
    const Home(),
    StreetViewExample(),
    const Chatbot(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _buildIOSLiquidGlassNav(),
    );
  }

  Widget _buildIOSLiquidGlassNav() {
    return Container(
      height: 90,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.6),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 1,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIOSNavItem(Icons.home_rounded, "Home", 0),
                  _buildIOSNavItem(Icons.map_rounded, "Map", 1),
                  _buildIOSNavItem(Icons.headphones_rounded, "Guide", 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSNavItem(IconData icon, String label, int index) {
    bool isSelected = _index == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _index = index;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                )
              : null,
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.2), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                size: isSelected ? 26 : 24,
              ),
            ),
            SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
