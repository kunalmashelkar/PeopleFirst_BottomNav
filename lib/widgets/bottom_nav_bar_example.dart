import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

/// Minimal integration example — copy the relevant parts into your app.
class PeopleFirstHomeScreen extends StatefulWidget {
  const PeopleFirstHomeScreen({super.key});

  @override
  State<PeopleFirstHomeScreen> createState() => _PeopleFirstHomeScreenState();
}

class _PeopleFirstHomeScreenState extends State<PeopleFirstHomeScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      // No built-in bottomNavigationBar — we use a floating overlay instead.
      body: Stack(
        children: [
          // ── Your page content ──────────────────────────────────────────────
          _PageContent(index: _activeTab),

          // ── Floating bottom nav ────────────────────────────────────────────
          // 22 px above the safe-area edge, centred horizontally.
          Positioned(
            bottom: 22 + safeBottom,
            left:   0,
            right:  0,
            child: Center(
              child: PeopleFirstBottomNav(
                initialIndex: _activeTab,
                onTabChanged: (idx) => setState(() => _activeTab = idx),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Placeholder page bodies ────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final int index;
  const _PageContent({required this.index});

  static const _labels = [
    'Home', 'Attendance', 'Payroll', 'Reimburse', 'Menu',
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF2F4F7),
      child: Center(
        child: Text(
          _labels[index],
          style: const TextStyle(
            fontSize:   24,
            fontWeight: FontWeight.w500,
            fontFamily: 'JioType',
          ),
        ),
      ),
    );
  }
}
