# DayByDay

DayByDay is a personal growth and emotional wellbeing assistant built with Flutter. It helps users track mood, daily patterns, habits, goals, and journal entries while offering a guiding dashboard and insights based on user activity.

## Project Overview

The app is designed to support self-awareness, progress tracking, and healthy habit formation. It combines a warm onboarding experience with daily check-ins, goal management, and journal tools that help users reflect and stay consistent.

Core features implemented in this codebase:

- Onboarding flow with introduction screens and login/signup entry points
- Firebase authentication and user profile management
- Home dashboard with mood, check-in, goal, and daily pattern summaries
- Mood check-ins for morning, evening, and night with task effectiveness and reflections
- Journal hub for general, reflection, and gratitude journaling
- Overview screen for mood trends, goals, and daily pattern analytics
- Goal setting, progress tracking, and completion history
- Insights generation and history storage
- Daily patterns logging for sleep, screen time, and activity

## What’s Included

### App Flow

- `lib/main.dart` — initializes Firebase and decides whether to show onboarding or the main app flow
- `lib/navigation/main_navigation.dart` — bottom tab navigation with Home, Overview, Journal, and Settings
- `lib/onboarding/onboarding_flow.dart` — onboarding carousel with get started and login/signup options

### Screens

- `lib/home_screen/home_screen.dart` — dashboard with onboarding progress, mood trends, and summaries
- `lib/overview/overview_screen.dart` — progress overview, streak tracking, and pattern summaries
- `lib/journal/journal_hub_screen.dart` — journal hub and stats for different journal types
- `lib/check_in/checkin_screen.dart` — daily check-in workflow for mood, effectiveness, and optional reflection
- `lib/daily_patterns/daily_patterns_screen.dart` — daily patterns input and tracking UI
- `lib/goal_setting/goal_setting_screen.dart` — goal list, filtering, and completion toggles
- `lib/goal_setting/goal_progress_overview_screen.dart` — progress history for daily, weekly, and monthly goals
- `lib/insights/insights_screen.dart` — generated insights and refresh action

### Services

The app uses Firebase Firestore and authentication, with dedicated service classes under `lib/services`:

- `user_service.dart`
- `checkin_service.dart`
- `goal_service.dart`
- `daily_patterns_service.dart`
- `analytics_service.dart`
- `journal_service.dart`
- `insights_service.dart`
- `assessment_service.dart`

## Getting Started

### Prerequisites

- Flutter SDK 3.12.x or newer
- Firebase CLI configured for your project
- A connected Firebase project for Android/iOS/web

### Install

1. Open the project root in your terminal.
2. Run:

```bash
flutter pub get
```

3. Ensure Firebase config is available in `lib/firebase_options.dart`.

### Run the app

```bash
flutter run
```

If you have multiple devices or targets, add `-d <device-id>`.

## Firebase Setup

This project uses Firebase for authentication and Firestore persistence. You should:

1. Configure your Firebase project in the Firebase console.
2. Add Android and/or iOS apps to the Firebase project.
3. Download and integrate Firebase config files (`google-services.json`, `GoogleService-Info.plist`) as needed.
4. Confirm `lib/firebase_options.dart` is generated for your current platform.

## App Vision

DayByDay is built to help users:

- Understand their mood and behavioral trends through daily tracking
- Build consistency with small habits and practical goals
- Reflect through journaling and gratitude practice
- Stay motivated with progress insights and visual feedback

## Notes

- The codebase currently implements the foundational experience and Firebase-backed persistence.
- Some screens and services are designed to support additional features like assessments, insights history, and expanded journal workflows.

## License

This project is currently private and not configured for pub.dev publication.

