# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HeadsUp is a minimalist iOS posture tracking app built with Flutter. It monitors phone tilt angle using iOS CoreMotion sensors to encourage better posture by tracking how the user holds their phone. Features real-time Dynamic Island Live Activity integration for iPhone 14 Pro and newer.

## Development Commands

### Flutter Commands
```bash
# Working directory for all Flutter commands
cd headsup_app

# Install dependencies
flutter pub get

# Run on iOS simulator/device
flutter run

# Build iOS release
flutter build ios --release

# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

### iOS Native Development
```bash
# Open Xcode workspace (for native Swift development)
open headsup_app/ios/Runner.xcworkspace

# Build from command line
cd headsup_app/ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug

# Clean build
flutter clean
cd ios && rm -rf Pods Podfile.lock
pod install
```

## Architecture Overview

### Core Data Flow
1. **Sensor Pipeline**: `MotionPlugin.swift` → `MotionChannel` (Dart) → `PostureService` → `SessionProvider`
2. **State Management**: Riverpod providers manage session state, which flows to UI components
3. **Live Activity**: `SessionProvider` updates → `LiveActivityChannel` → `LiveActivityPlugin.swift` → Dynamic Island UI
4. **Persistence**: Session data saved to Supabase on session end, daily summaries calculated automatically

### Key Architectural Patterns

#### Native iOS Plugins (Platform Channels)
The app uses three custom Flutter platform channels to access iOS-only features:

1. **MotionPlugin** (`ios/Runner/MotionPlugin.swift`)
   - Accesses CMDeviceMotion for sensor fusion (pitch, roll, yaw)
   - Uses Location Keep-Alive to maintain background execution
   - Streams motion data via EventChannel `com.headsup/motion_stream`
   - Critical for posture angle calculation

2. **LiveActivityPlugin** (`ios/Runner/LiveActivityPlugin.swift`)
   - Manages iOS 16.1+ Live Activities for Dynamic Island
   - Implements stale date mechanism (4-second buffer) to detect app termination
   - Updates throttled to 500ms to prevent spam
   - Shared attributes defined in `HeadsUpActivityAttributes.swift`

3. **Widget Extension** (`ios/headsupwidget/HeadsUpLiveActivity.swift`)
   - SwiftUI-based Live Activity widget
   - Displays compact, minimal, and expanded Dynamic Island views
   - Shows session timer, posture state, points, and angle in real-time

#### Posture Detection System
Located in `lib/services/posture_service.dart`:

- **3D Tilt Calculation**: Converts CMDeviceMotion pitch/roll to single tilt angle (0° = upright, 90° = flat)
- **Multi-Layer Filtering**:
  - Outlier rejection (max 30° instant change)
  - Moving average filter (5-sample buffer)
  - Temporal smoothing (5-second threshold for poor posture)
- **Context Detection**: Auto-pauses on face-down, adjusts thresholds for landscape mode
- **5-Tier Posture States**: excellent (0-15°), good (16-25°), okay (26-35°), bad (36-65°), poor (66°+)

#### Session Management
`lib/providers/session_provider.dart` orchestrates:

- Timer-based tracking (1-second intervals)
- Auto-pause triggers: phone calls, proximity sensor (pocket mode), stationary timeout (30s)
- Points system: Additive only (excellent: +5/min, good: +3/min, okay: +1/min, bad/poor: +0/min)
- Haptic feedback on posture state transitions (configurable patterns: single, double, triple, continuous)
- Live Activity updates synchronized with session state

#### Supabase Backend
Database schema in `headsup_app/supabase_migration.sql`:

- **sessions**: Tracks individual posture sessions with duration, scores, and angle data
- **daily_summaries**: Aggregated daily stats (auto-calculated from sessions)
- **user_settings**: User preferences for alerts, reminders, thresholds
- Row-Level Security (RLS) enforced for multi-user support
- Anonymous mode available for MVP (see commented policies in migration file)

### Critical Implementation Details

#### Background Execution Strategy
The app uses Location Keep-Alive to maintain background execution:
- `MotionPlugin.swift` starts location updates with minimal accuracy (`kCLLocationAccuracyThreeKilometers`)
- `UIBackgroundModes` includes `location` in `Info.plist`
- This allows CMDeviceMotion to continue streaming even when app is backgrounded
- Location data itself is discarded; only used for execution time

#### Live Activity Persistence
To prevent Live Activity freezing on app termination:
- Stale date set to 4 seconds from update time
- If app is alive (foreground/background), updates every second extend this
- If app terminates, Live Activity shows "Session Ended" after 4 seconds
- On app restart, check for existing activities and clean up stale ones

#### Posture Scoring vs. Points
Two separate metrics:
- **Posture Score**: Percentage of time in good+ posture (0-100%), used for daily summary
- **Total Points**: Additive accumulation based on time in each tier, never decreases
- Points displayed in Live Activity and session summary for gamification

## File Organization

```
headsup_app/
├── lib/
│   ├── config/              # App configuration
│   │   ├── supabase_config.dart   # Supabase connection
│   │   └── theme.dart             # App theme/styling
│   ├── models/              # Data models
│   │   ├── session.dart           # Session data structure
│   │   ├── daily_summary.dart     # Daily stats
│   │   └── user_settings.dart     # User preferences
│   ├── providers/           # Riverpod state management
│   │   └── session_provider.dart  # Core session state
│   ├── screens/             # UI screens
│   │   ├── home_screen.dart       # Main landing page
│   │   ├── active_session_screen.dart  # Real-time tracking
│   │   ├── session_summary_screen.dart # Post-session review
│   │   └── onboarding/            # First-time setup flow
│   ├── services/            # Business logic & platform integration
│   │   ├── posture_service.dart   # Angle calculation & filtering
│   │   ├── motion_channel.dart    # Native motion data bridge
│   │   ├── live_activity_channel.dart  # Dynamic Island bridge
│   │   ├── supabase_service.dart  # Database operations
│   │   ├── notification_service.dart   # Local notifications
│   │   └── health_service.dart    # HealthKit integration
│   ├── widgets/             # Reusable UI components
│   │   ├── character/       # Posture character animations
│   │   ├── sheets/          # Bottom sheets (settings, history)
│   │   └── common/          # Shared widgets
│   ├── utils/
│   │   └── constants.dart   # App-wide constants & enums
│   └── main.dart            # App entry point
├── ios/
│   ├── Runner/              # Main app target
│   │   ├── MotionPlugin.swift          # CMDeviceMotion access
│   │   ├── LiveActivityPlugin.swift    # Live Activity management
│   │   ├── HeadsUpActivityAttributes.swift  # Shared LA attributes
│   │   └── AppDelegate.swift           # Flutter app initialization
│   └── headsupwidget/       # Widget Extension target
│       └── HeadsUpLiveActivity.swift   # Dynamic Island UI
└── supabase_migration.sql   # Database schema
```

## Posture State Constants

All posture thresholds defined in `lib/utils/constants.dart`:

- **Angle Tiers**: 0-15° (excellent), 16-25° (good), 26-35° (okay), 36-65° (bad), 66°+ (poor)
- **Points per Minute**: excellent=5, good=3, okay=1, bad=0, poor=0
- **Sensor Sampling**: 5 Hz (200ms interval) via CMDeviceMotion
- **Alert Thresholds**: Bad posture after 20 min, Poor posture after 10 min
- **Auto-pause**: Face-down=2min, Stationary=30s (increased to prevent accidental pauses)

## Testing & Debugging

### Testing Posture Detection
Use `PostureService.setAngle(double)` to manually inject angles for testing state transitions without moving the device.

### Live Activity Debugging
- Check Xcode console for logs prefixed with ✅/❌
- `LiveActivityChannel` logs start/update/end operations
- `HeadsUpLiveActivity` logs initialization and stale state changes
- Use Xcode's Live Activity simulator to test without physical device

### Common Issues
1. **Live Activity not showing**: Verify iOS 16.1+, check ActivityKit entitlements in Xcode
2. **Background tracking stops**: Ensure location permissions granted, check Info.plist UIBackgroundModes
3. **Sensor data frozen**: CMDeviceMotion requires physical device (simulator only provides mock data)
4. **Supabase errors**: Verify RLS policies match auth state (anonymous vs authenticated)

## Dependencies

Core packages (see `pubspec.yaml`):
- `flutter_riverpod`: State management
- `supabase_flutter`: Backend database/auth
- `sensors_plus`: Fallback for non-iOS sensor access (deprecated in favor of CMDeviceMotion)
- `flutter_local_notifications`: Reminder notifications
- `phone_state`: Auto-pause on phone calls
- `proximity_sensor`: Pocket mode detection
- `shadcn_ui`: UI component library

Native iOS:
- ActivityKit (iOS 16.1+): Live Activities
- CoreMotion: CMDeviceMotion sensor fusion
- CoreLocation: Background execution keep-alive
- AudioToolbox: Haptic feedback
