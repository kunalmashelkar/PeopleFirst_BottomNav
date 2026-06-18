import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

// ── Usage example ─────────────────────────────────────────────────────────────
//
//  Wrap your Scaffold body with a Stack and place PeopleFirstBottomNav
//  at the bottom, 22px above the safe-area edge — matching the Figma spec.
//
//  pubspec.yaml dependencies needed:
//    flutter:
//      sdk: flutter
//
//  Add JioType font (already in /Font folder):
//    flutter:
//      fonts:
//        - family: JioType
//          fonts:
//            - asset: Font/JioType-Medium.ttf
//              weight: 500
//            - asset: Font/JioType-Bold.ttf
//              weight: 700
//            - asset: Font/JioType-Black.ttf
//              weight: 900

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── Page content ────────────────────────────────────────────────
          _buildPage(_currentIndex),

          // ── Bottom nav ──────────────────────────────────────────────────
          Positioned(
            bottom: 22 + bottomPadding,
            left: 0,
            right: 0,
            child: Center(
              child: PeopleFirstBottomNav(
                initialIndex: _currentIndex,
                onTabChanged: (idx) => setState(() => _currentIndex = idx),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    const pages = ['Home', 'Attendance', 'Payroll', 'Reimburse', 'Menu'];
    return Container(
      color: const Color(0xFFF2F4F7),
      child: Center(
        child: Text(
          pages[index],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
