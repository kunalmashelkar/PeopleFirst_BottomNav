import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

// ─── Tab model ───────────────────────────────────────────────────────────────

class NavTab {
  final String label;
  final IconData icon;
  const NavTab({required this.label, required this.icon});
}

// Default PeopleFirst tabs — swap icons with actual Jio SVG assets if needed.
const _kDefaultTabs = [
  NavTab(label: 'Home',       icon: Icons.home_rounded),
  NavTab(label: 'Attendance', icon: Icons.calendar_month_outlined),
  NavTab(label: 'Payroll',    icon: Icons.currency_rupee_rounded),
  NavTab(label: 'Reimburse',  icon: Icons.receipt_long_outlined),
  NavTab(label: 'Menu',       icon: Icons.grid_view_rounded),
];

// ─── Layout constants (Figma spec) ───────────────────────────────────────────

const _kNavWidth    = 344.0;
const _kNavHeight   = 62.0;
const _kNavRadius   = 80.0;
const _kPillW       = 68.0;
const _kPillH       = 50.0;
const _kPillTop     = 6.0;
const _kSlotW       = 37.0;
const _kSlotTop     = 8.0;
const _kSlotH       = 46.0;
const _kIconSize    = 24.0;
const _kLabelSize   = 11.0;
const _kGap         = 4.0;

// Pill left-edge positions per tab
const _kPillX  = [6.0, 70.0, 137.0, 204.0, 271.0];
// Slot left-edge positions per tab
const _kSlotX  = [17.0, 85.0, 152.0, 219.0, 286.0];

// ─── Colors ───────────────────────────────────────────────────────────────────

const _kBrand      = Color(0xFF0078AD);
final  _kInactive  = Colors.black.withOpacity(0.65);
const _kPillColor  = Color(0xFFA3B6CB);

// ─── Spring ───────────────────────────────────────────────────────────────────

const _kSpring = SpringDescription(mass: 1, stiffness: 320, damping: 34);

// ─── Widget ───────────────────────────────────────────────────────────────────

class PeopleFirstBottomNav extends StatefulWidget {
  final int initialIndex;
  final List<NavTab> tabs;
  final ValueChanged<int>? onTabChanged;

  const PeopleFirstBottomNav({
    super.key,
    this.initialIndex = 0,
    this.tabs = _kDefaultTabs,
    this.onTabChanged,
  });

  @override
  State<PeopleFirstBottomNav> createState() => _PeopleFirstBottomNavState();
}

class _PeopleFirstBottomNavState extends State<PeopleFirstBottomNav>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;

  int    _activeIdx      = 0;
  double _pillX          = _kPillX[0];
  double _prevPillX      = _kPillX[0];
  double _velocity       = 0.0;   // px/s

  // Drag tracking
  bool   _dragging       = false;
  double _dragStartGX    = 0;     // global x at drag start
  double _dragStartPillX = 0;
  double _dragVelocity   = 0;     // px/s from gesture
  double _totalDragDist  = 0;

  @override
  void initState() {
    super.initState();
    _activeIdx = widget.initialIndex;
    _pillX     = _kPillX[_activeIdx];
    _prevPillX = _pillX;

    _ctrl = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        final newX = _ctrl.value;
        // Approximate velocity in px/s (controller drives ~60fps)
        _velocity  = (newX - _prevPillX) * 60;
        _prevPillX = _pillX;
        setState(() => _pillX = newX);
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Spring to a tab ────────────────────────────────────────────────────────

  void _springTo(int idx) {
    if (idx == _activeIdx && !_dragging) return;
    setState(() => _activeIdx = idx);
    widget.onTabChanged?.call(idx);
    _ctrl.animateWith(
      SpringSimulation(_kSpring, _pillX, _kPillX[idx], _velocity),
    );
  }

  // ── Nearest tab to a pill x ────────────────────────────────────────────────

  int _nearestTab(double x) {
    final cx = x + 34;
    int   best     = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < _kPillX.length; i++) {
      final d = ((_kPillX[i] + 34) - cx).abs();
      if (d < bestDist) { bestDist = d; best = i; }
    }
    return best;
  }

  // ── Stretch transform ──────────────────────────────────────────────────────

  (double sX, double sY) get _stretch {
    final dx       = _pillX - _kPillX[_activeIdx];
    final dStretch = (dx.abs() * 0.010).clamp(0.0, 1.0);
    final vStretch = (_velocity.abs() * 0.00003).clamp(0.0, 0.45);
    final sX       = 1.0 + dStretch + vStretch;
    return (sX, 1.0 / sqrt(sX));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final (sX, sY) = _stretch;

    return GestureDetector(
      onHorizontalDragStart: (d) {
        _dragging       = true;
        _dragStartGX    = d.globalPosition.dx;
        _dragStartPillX = _pillX;
        _dragVelocity   = 0;
        _totalDragDist  = 0;
        _ctrl.stop();
      },
      onHorizontalDragUpdate: (d) {
        if (!_dragging) return;
        _dragVelocity  = d.primaryDelta! * 60;        // px/s approx
        _totalDragDist += d.primaryDelta!.abs();
        final newX = (_dragStartPillX +
            (d.globalPosition.dx - _dragStartGX))
            .clamp(6.0, 271.0);
        setState(() {
          _pillX     = newX;
          _activeIdx = _nearestTab(newX);
          _velocity  = _dragVelocity * 0.4;
        });
      },
      onHorizontalDragEnd: (d) {
        if (!_dragging) return;
        _dragging = false;
        if (_totalDragDist <= 6) return;
        _velocity = (d.primaryVelocity ?? 0);
        _springTo(_nearestTab(_pillX));
      },
      child: SizedBox(
        width:  _kNavWidth,
        height: _kNavHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kNavRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.64),
                borderRadius: BorderRadius.circular(_kNavRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.75),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildPill(sX, sY),
                  ..._buildSlots(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Glass pill ─────────────────────────────────────────────────────────────

  Widget _buildPill(double sX, double sY) {
    return Positioned(
      left: _pillX,
      top:  _kPillTop,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(sX, sY, 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              width:  _kPillW,
              height: _kPillH,
              decoration: BoxDecoration(
                color: _kPillColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
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

  // ── Nav slots ──────────────────────────────────────────────────────────────

  List<Widget> _buildSlots() {
    return List.generate(widget.tabs.length, (i) {
      final tab      = widget.tabs[i];
      final isActive = i == _activeIdx;

      return Positioned(
        left:   _kSlotX[i],
        top:    _kSlotTop,
        width:  _kSlotW,
        height: _kSlotH,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_totalDragDist <= 6) _springTo(i);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale:    isActive ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 320),
                curve:    const ElasticOutCurve(0.8),
                child: Icon(
                  tab.icon,
                  size:  _kIconSize,
                  color: isActive ? _kBrand : _kInactive,
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
                  color:         isActive ? _kBrand : _kInactive,
                  fontFamily:    'JioType',
                ),
                child: Text(tab.label, maxLines: 1),
              ),
            ],
          ),
        ),
      );
    });
  }
}
