import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PeopleFirstBottomNav
//
//  Glassmorphic floating bottom navigation bar with spring-physics pill.
//
//  Design spec : Figma node 39333-67620
//  Spring      : stiffness=320, damping=34  (matches HTML prototype)
//  Glass nav   : white 64 % opacity, blur 28 px
//  Glass pill  : #A3B6CB 50 % opacity, blur 12 px
//
//  Usage
//  ─────
//    Stack(children: [
//      YourPageContent(),
//      Positioned(
//        bottom: 22 + MediaQuery.of(context).padding.bottom,
//        left: 0, right: 0,
//        child: Center(
//          child: PeopleFirstBottomNav(
//            onTabChanged: (idx) => setState(() => _tab = idx),
//          ),
//        ),
//      ),
//    ])
//
//  See README.md for full setup instructions.
// ─────────────────────────────────────────────────────────────────────────────

// ── Tab model ─────────────────────────────────────────────────────────────────

class NavTab {
  final String label;

  /// Path to an SVG asset, e.g. 'assets/svg/home.svg'
  final String svgAsset;

  const NavTab({required this.label, required this.svgAsset});
}

const List<NavTab> kPeopleFirstTabs = [
  NavTab(label: 'Home',       svgAsset: 'assets/svg/home.svg'),
  NavTab(label: 'Attendance', svgAsset: 'assets/svg/attendance.svg'),
  NavTab(label: 'Payroll',    svgAsset: 'assets/svg/payroll.svg'),
  NavTab(label: 'Reimburse',  svgAsset: 'assets/svg/reimburse.svg'),
  NavTab(label: 'Menu',       svgAsset: 'assets/svg/menu.svg'),
];

// ── Layout constants (Figma-exact) ────────────────────────────────────────────

const double _kNavWidth   = 344.0;
const double _kNavHeight  = 62.0;
const double _kNavRadius  = 80.0;
const double _kPillW      = 78.0;
const double _kPillH      = 50.0;
const double _kPillTop    = 6.0;
const double _kIconSize   = 24.0;
const double _kLabelSize  = 11.0;
const double _kGap        = 4.0;
const double _kSlotTop    = 8.0;
const double _kSlotW      = 37.0;
const double _kSlotH      = 46.0;

/// Left edge of the pill for each tab index
const List<double> _kPillX = [6.0, 63.0, 130.0, 197.0, 264.0];

/// Left edge of each slot for each tab index
const List<double> _kSlotX = [17.0, 85.0, 152.0, 219.0, 286.0];

// ── Colors ────────────────────────────────────────────────────────────────────

const Color _kBrand     = Color(0xFF0078AD);
const Color _kInactive  = Color(0xA6000000); // rgba(0,0,0,0.65)
const Color _kPillFill  = Color(0xFFA3B6CB);

// ── Spring ────────────────────────────────────────────────────────────────────

const SpringDescription _kSpring = SpringDescription(
  mass:      1,
  stiffness: 320,
  damping:   34,
);

// ── Widget ────────────────────────────────────────────────────────────────────

class PeopleFirstBottomNav extends StatefulWidget {
  /// Tab definitions. Defaults to the five PeopleFirst tabs.
  final List<NavTab> tabs;

  /// Zero-based index of the initially selected tab.
  final int initialIndex;

  /// Called whenever the active tab changes (tap or drag-snap).
  final ValueChanged<int>? onTabChanged;

  const PeopleFirstBottomNav({
    super.key,
    this.tabs         = kPeopleFirstTabs,
    this.initialIndex = 0,
    this.onTabChanged,
  }) : assert(
         tabs.length == 5,
         'PeopleFirstBottomNav requires exactly 5 tabs to match Figma layout.',
       );

  @override
  State<PeopleFirstBottomNav> createState() => _PeopleFirstBottomNavState();
}

class _PeopleFirstBottomNavState extends State<PeopleFirstBottomNav>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;

  int    _activeIdx      = 0;
  double _pillX          = _kPillX[0];
  double _prevPillX      = _kPillX[0];
  double _velocity       = 0.0;   // pixels/second, used for pill stretch

  // ── Drag state ──────────────────────────────────────────────────────────────
  bool   _dragging       = false;
  double _dragStartGX    = 0.0;
  double _dragStartPillX = 0.0;
  double _dragVelocity   = 0.0;
  double _totalDragDist  = 0.0;

  @override
  void initState() {
    super.initState();
    _activeIdx = widget.initialIndex.clamp(0, widget.tabs.length - 1);
    _pillX     = _kPillX[_activeIdx];
    _prevPillX = _pillX;

    _ctrl = AnimationController.unbounded(vsync: this)
      ..addListener(_onAnimation);
  }

  void _onAnimation() {
    final newX = _ctrl.value;
    // Derive velocity from frame delta (~60 fps assumed by AnimationController).
    _velocity  = (newX - _prevPillX) * 60.0;
    _prevPillX = _pillX;
    setState(() => _pillX = newX);
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onAnimation)
      ..dispose();
    super.dispose();
  }

  // ── Spring navigation ────────────────────────────────────────────────────────

  void _springTo(int idx) {
    setState(() => _activeIdx = idx);
    widget.onTabChanged?.call(idx);
    _ctrl.animateWith(
      SpringSimulation(_kSpring, _pillX, _kPillX[idx], _velocity),
    );
  }

  // ── Drag helpers ─────────────────────────────────────────────────────────────

  int _nearestTab(double pillLeft) {
    final cx      = pillLeft + _kPillW / 2;
    int    best   = 0;
    double bestD  = double.infinity;
    for (int i = 0; i < _kPillX.length; i++) {
      final d = (_kPillX[i] + _kPillW / 2 - cx).abs();
      if (d < bestD) { bestD = d; best = i; }
    }
    return best;
  }

  // ── Pill squash-and-stretch ──────────────────────────────────────────────────

  /// Returns (scaleX, scaleY) based on displacement and velocity.
  (double, double) get _stretch {
    final dx       = _pillX - _kPillX[_activeIdx];
    final dStretch = (dx.abs() * 0.010).clamp(0.0, 1.0);
    final vStretch = (_velocity.abs() * 0.00003).clamp(0.0, 0.45);
    final sX       = 1.0 + dStretch + vStretch;
    return (sX, 1.0 / sqrt(sX));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final (sX, sY) = _stretch;

    return GestureDetector(
      onHorizontalDragStart:  _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd:    _onDragEnd,
      child: SizedBox(
        width:  _kNavWidth,
        height: _kNavHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kNavRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: _NavContainer(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _Pill(x: _pillX, scaleX: sX, scaleY: sY),
                  for (int i = 0; i < widget.tabs.length; i++)
                    _Slot(
                      tab:      widget.tabs[i],
                      x:        _kSlotX[i],
                      isActive: i == _activeIdx,
                      onTap:    () {
                        if (_totalDragDist <= 6) _springTo(i);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Gesture handlers ─────────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails d) {
    _dragging       = true;
    _dragStartGX    = d.globalPosition.dx;
    _dragStartPillX = _pillX;
    _dragVelocity   = 0.0;
    _totalDragDist  = 0.0;
    _ctrl.stop();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    final delta = d.primaryDelta ?? 0.0;
    _dragVelocity  = delta * 60.0;
    _totalDragDist += delta.abs();
    final newX = (_dragStartPillX + (d.globalPosition.dx - _dragStartGX))
        .clamp(6.0, 264.0);
    setState(() {
      _pillX     = newX;
      _velocity  = _dragVelocity * 0.4;
      _activeIdx = _nearestTab(newX);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_dragging) return;
    _dragging = false;
    if (_totalDragDist <= 6) return;   // treat as tap — let GestureDetector handle
    _velocity = d.primaryVelocity ?? 0.0;
    _springTo(_nearestTab(_pillX));
  }
}

// ─── Private sub-widgets ─────────────────────────────────────────────────────

/// Frosted-glass container for the nav bar background.
class _NavContainer extends StatelessWidget {
  final Widget child;
  const _NavContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  _kNavWidth,
      height: _kNavHeight,
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.64),
        borderRadius: BorderRadius.circular(_kNavRadius),
        border:       Border.all(color: Colors.white.withOpacity(0.75)),
        boxShadow: [
          BoxShadow(
            color:       Colors.black.withOpacity(0.12),
            blurRadius:  32,
            offset:      const Offset(0, 8),
          ),
          BoxShadow(
            color:       Colors.white.withOpacity(0.9),
            blurRadius:  0,
            offset:      const Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Squash-and-stretch frosted-glass active indicator pill.
class _Pill extends StatelessWidget {
  final double x;
  final double scaleX;
  final double scaleY;

  const _Pill({required this.x, required this.scaleX, required this.scaleY});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top:  _kPillTop,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              width:  _kPillW,
              height: _kPillH,
              decoration: BoxDecoration(
                color:        _kPillFill.withOpacity(0.5),
                borderRadius: BorderRadius.circular(100),
                border:       Border.all(color: Colors.white.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color:        Colors.white.withOpacity(0.7),
                    blurRadius:   0,
                    offset:       const Offset(0, 1),
                    spreadRadius: -1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single tappable icon + label slot.
class _Slot extends StatelessWidget {
  final NavTab tab;
  final double x;
  final bool   isActive;
  final VoidCallback onTap;

  const _Slot({
    required this.tab,
    required this.x,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _kBrand : _kInactive;

    return Positioned(
      left:   x,
      top:    _kSlotTop,
      width:  _kSlotW,
      height: _kSlotH,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:    onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale:    isActive ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 320),
              curve:    const ElasticOutCurve(0.8),
              child: SvgPicture.asset(
                tab.svgAsset,
                width:       _kIconSize,
                height:      _kIconSize,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: _kGap),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize:      _kLabelSize,
                fontWeight:    FontWeight.w500,
                height:        14 / 11,
                letterSpacing: -0.055,
                color:         color,
                fontFamily:    'JioType',
                decoration:    TextDecoration.none,
              ),
              child: Text(tab.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
