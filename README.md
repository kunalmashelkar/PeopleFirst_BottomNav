# PeopleFirst — Bottom Navigation Bar

Glassmorphic floating bottom nav for the PeopleFirst (Jio HR) app.  
Figma spec: [node 39333-67620](https://www.figma.com/design/IAAFcjsyd2ysoGctbSI3ZP/PeopleFirst---Deliveries1?node-id=39333-67620)

---

## What's included

| File | Purpose |
|------|---------|
| `lib/widgets/bottom_nav_bar.dart` | Production Flutter widget |
| `lib/widgets/bottom_nav_bar_example.dart` | Minimal integration example |
| `home-screen.html` | HTML prototype — click + drag |
| `home-screen-click.html` | HTML prototype — click only |
| `assets/svg/` | Tab SVG icons |
| `Font/` | JioType font files |

---

## Design spec

| Property | Value |
|----------|-------|
| Nav width | 344 px |
| Nav height | 62 px |
| Bottom offset | 22 px above safe area |
| Nav background | `#FFFFFF` at 64 % opacity, blur 28 px |
| Active pill | `#A3B6CB` at 50 % opacity, blur 12 px |
| Active icon/label | `#0078AD` |
| Inactive icon/label | `rgba(0,0,0,0.65)` |
| Spring stiffness | 320 |
| Spring damping | 34 |
| Font | JioType Medium 500, 11 px |

---

## Setup

### 1. Add `flutter_svg` dependency

In your project's `pubspec.yaml`:

```yaml
dependencies:
  flutter_svg: ^2.0.10+1
```

Run:

```bash
flutter pub get
```

### 2. Register the JioType font

Copy the `Font/` folder into your project, then add to `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: JioType
      fonts:
        - asset: Font/JioType-Medium.ttf
          weight: 500
        - asset: Font/JioType-Bold.ttf
          weight: 700
        - asset: Font/JioType-Black.ttf
          weight: 900
```

### 3. Register SVG assets

Copy the `assets/svg/` folder into your project, then add to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/svg/
```

### 4. Copy the widget

Copy `lib/widgets/bottom_nav_bar.dart` into your project's widget folder.

---

## Usage

```dart
import 'package:your_app/widgets/bottom_nav_bar.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Your page content
          YourPageBody(tabIndex: _activeTab),

          // Floating bottom nav — 22 px above safe area, centred
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
```

> **Important:** Use `Scaffold` with no `bottomNavigationBar`. The nav bar floats above page content via a `Stack` + `Positioned`.

---

## API reference

```dart
PeopleFirstBottomNav({
  Key? key,

  /// Tab definitions. Defaults to the 5 PeopleFirst tabs.
  /// Must be exactly 5 entries to match the Figma layout.
  List<NavTab> tabs = kPeopleFirstTabs,

  /// Zero-based index of the initially selected tab.
  int initialIndex = 0,

  /// Called whenever the active tab changes (tap or drag-snap).
  ValueChanged<int>? onTabChanged,
})
```

### `NavTab`

```dart
NavTab({
  required String label,      // Display text below the icon
  required String svgAsset,   // Asset path, e.g. 'assets/svg/home.svg'
})
```

### Default tabs (`kPeopleFirstTabs`)

| Index | Label | SVG asset |
|-------|-------|-----------|
| 0 | Home | `assets/svg/home.svg` |
| 1 | Attendance | `assets/svg/attendance.svg` |
| 2 | Payroll | `assets/svg/payroll.svg` |
| 3 | Reimburse | `assets/svg/reimburse.svg` |
| 4 | Menu | `assets/svg/menu.svg` |

### Using custom tabs

```dart
PeopleFirstBottomNav(
  tabs: const [
    NavTab(label: 'Dashboard', svgAsset: 'assets/svg/dashboard.svg'),
    NavTab(label: 'Team',      svgAsset: 'assets/svg/team.svg'),
    NavTab(label: 'Tasks',     svgAsset: 'assets/svg/tasks.svg'),
    NavTab(label: 'Reports',   svgAsset: 'assets/svg/reports.svg'),
    NavTab(label: 'Settings',  svgAsset: 'assets/svg/settings.svg'),
  ],
  onTabChanged: (idx) => setState(() => _activeTab = idx),
)
```

---

## How the animation works

The pill moves using Flutter's `SpringSimulation` (not a fixed-duration `Tween`), which means it behaves exactly like a physical spring — it overshoots slightly and settles naturally.

- **Tap** → `springTo(idx)` launches a spring from the current pill position to the target  
- **Drag** → pill follows the finger directly; on release, it snaps to the nearest tab with the finger's release velocity fed into the spring (so a fast flick carries momentum)  
- **Squash & stretch** → the pill's `scaleX`/`scaleY` are computed from displacement and velocity each frame, giving it a jelly-like squash as it moves and snap as it arrives  

---

## Requirements

| Requirement | Minimum |
|-------------|---------|
| Flutter SDK | 3.10.0 |
| Dart SDK | 3.0.0 |
| `flutter_svg` | 2.0.0 |
| iOS | 12.0+ |
| Android | API 21+ |

---

## HTML prototypes

Two interactive HTML prototypes are included for design review / stakeholder demos.  
Open in any browser — no build step required.

| File | Interaction |
|------|-------------|
| `home-screen.html` | Click + drag |
| `home-screen-click.html` | Click only |
