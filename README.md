# Mini Finan — Personal Finance Tracker (Flutter + Firebase)

A modern, real-time personal finance tracker built with **Flutter**, **Riverpod**, **GoRouter**, and **Firebase** (Auth + Firestore + Storage).  
It supports CSV import, rule-based auto-tagging, category management, and a dashboard with charts and monthly summaries.

> Demo goals: snappy UX, clean architecture, and production-ready patterns.

---

## ✨ Features

- **Auth**: Anonymous sign-in (ready to extend to Google/Apple).
- **Transactions**: Add/Edit/Delete, CSV import, real-time streams.
- **Categories**: CRUD with colors, codes, and `type: income | expense`.
- **Rule Engine**: Auto-tag new transactions by matching merchant/description.
- **Dashboard**: Monthly totals, top categories, recent transactions, trend chart.
- **Navigation**: `go_router` with URL query params (month filters).
- **State**: `flutter_riverpod` + `riverpod_annotation`.
- **Storage**: Firestore with user-scoped collections & security rules.
- **Local Prefs**: `shared_preferences` (e.g., collapsible sections).
- **Dev Flow**: Firebase emulators, flavors (dev/prod), build_runner codegen.

---

## 🧱 Tech Stack

- Flutter 3.x
- Riverpod / riverpod_annotation / freezed / json_serializable
- GoRouter
- Firebase (Auth, Firestore, Storage) + Emulators
- Shared Preferences
- fl_chart

---

## 📦 Project Structure (high-level)

lib/
app/
app_router.dart
auth_sync.dart
features/
auth/
providers.dart
presentation/...
categories/
data/
category_model.dart
category_repository.dart
rule_model.dart
categories_providers.dart
presentation/
categories_screen.dart
rules_screen.dart
dashboard/
providers.dart
presentation/
dashboard_screen.dart
widgets/
monthly_trend_chart.dart
expandable_card.dart
transactions/
data/
transaction_model.dart
transactions_repository.dart
categories.dart
logic/
rule_engine.dart
presentation/
transactions_screen.dart
add_transaction_screen.dart
import_csv_screen.dart
add_tx_controller.dart
services/
firebase_providers.dart
widgets/
error_card.dart

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK installed (`flutter doctor` should be green)
- CocoaPods (macOS/iOS): `brew install cocoapods`
- Ruby (>= 3.x recommended)
- Firebase CLI: `curl -sL https://firebase.tools | bash`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

###

1. Install dependencies

```bash
flutter pub get
dart run build_runner build -d

2) Firebase setup

Create Firebase projects for dev and prod (or use existing):

# Dev flavor
flutterfire configure \
  --project=your-dev-project-id \
  --out=lib/firebase_options_dev.dart \
  --platforms=ios,android,web

# Prod flavor (optional now)
flutterfire configure \
  --project=your-prod-project-id \
  --out=lib/firebase_options_prod.dart \
  --platforms=ios,android,web

  Ensure the iOS Podfile uses platform :ios, '15.0'. If CocoaPods is stale:
  cd ios && pod repo update && pod install && cd -

3) Emulators (local dev)

  firebase init emulators
  # choose Auth, Firestore, Storage + UI
  firebase emulators:start

  Run the app (dev, with emulators):

  # iOS Simulator example
  flutter run -t lib/main_dev.dart --dart-define=USE_EMULATORS=true -d "iPhone SE (3rd generation)"
```
