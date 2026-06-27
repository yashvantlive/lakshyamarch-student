# LM Champs — Student App (Flutter)

> Student Learning Portal for LakshyaMarch Education, Begusarai, Bihar.

**Status**: 🟡 In Active Development  
**Platform**: Android (Primary), iOS (Planned)  
**App Name**: `LM Champs`

---

## 📱 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Provider |
| Offline Cache | **Hive** (binary, 0ms reads) |
| HTTP | `http` package |
| Auth | JWT + SharedPreferences |
| Charts | fl_chart |
| Push Notifications | OneSignal Flutter |
| Icons | Lucide Icons |
| Google Fonts | google_fonts |
| Splash/Icon | flutter_native_splash, flutter_launcher_icons |

---

## 🗂️ Project Structure

```
lib/
├── main.dart                        # App entry, cache init
├── models/                          # Data models (Test, Fee, Homework, etc.)
├── providers/
│   ├── academic_provider.dart       # Core: attendance, fees, tests, homework, schedule
│   ├── auth_provider.dart           # Login/logout, token management
│   ├── notice_provider.dart         # Notices feed
│   └── schedule_provider.dart       # Schedule data
├── screens/
│   ├── public_screen.dart           # Public info & program details (Pre-login)
│   ├── login_screen.dart            # User authentication
│   ├── dashboard_screen.dart        # Main home with stats overview
│   ├── homework_history_screen.dart # Homework log with skipped slot detection
│   ├── attendance_screen.dart       # Interactive monthly attendance calendar
│   ├── fees_screen.dart             # Fee status and payment info
│   ├── tests_screen.dart            # Test series + results
│   ├── performance_screen.dart      # Performance charts (fl_chart)
│   ├── syllabus_screen.dart         # Curriculum progress
│   ├── schedule_screen.dart         # Weekly timetable
│   ├── notice_feed_screen.dart      # School/coaching notices
│   ├── profile_screen.dart          # Student profile + leaderboard
│   ├── support_screen.dart          # Help & support
│   └── study_hub/                   # Study material hub (PDFs, notes)
├── services/
│   ├── api_service.dart             # REST API calls
│   ├── app_cache.dart               # Hive offline cache layer
│   └── notification_service.dart    # OneSignal push notification setup
├── theme/
│   └── app_theme.dart               # Design tokens (colors, typography)
└── widgets/                         # Reusable premium UI widgets
```

---

## ⚡ Offline-First Architecture (Hive)

The Student App uses **Hive** with binary serialization for offline-first rendering:

```
1. App launches → Synchronous Hive read → Instant UI render (0ms)
2. Background: SWR (Stale-While-Revalidate) silent network fetch
3. On success → Update cache → Re-render UI with fresh data
4. On failure → Show cached data, no crash, no loading state
```

### Cache TTL Settings
| Data | TTL |
|------|-----|
| Attendance | 2 hours |
| Fees | 6 hours |
| Tests | 2 hours |
| Syllabus | 24 hours |
| Homework | 1 hour |
| Submissions | 1 hour |
| Holidays | 7 days |
| Leaderboard | 2 hours |
| Schedules | 4 hours |
| Study Materials | 24 hours |

> ⚠️ **Note**: Both Student and Teacher apps use `Hive` (binary) for encrypted, high-performance local storage.

---

## ✅ Completed Features

### 🏢 Public & Auth
- [x] Pre-login Public Information Screen (Programs, CTAs for WhatsApp/Call)
- [x] Integration with `url_launcher` for social and contact redirection
- [x] Secure JWT-based Login System

### 🏠 Dashboard
- [x] Personalized greeting (Good Morning/Afternoon/Evening)
- [x] Attendance %, Average Score, Homework Completion stats
- [x] Quick navigation to all modules
- [x] Offline-first rendering

### 📋 Homework History
- [x] Date-range based homework log (past 45 days)
- [x] Class schedule vs homework cross-mapping (skipped slot detection)
- [x] **FANG-Level Smart Slot Categorization**:
  - 🔴 Academic missed → "Homework Missed" red card
  - 🟢 Food/Meal slots → "Fuel Your Brain! 🍳" green card
  - 🔵 Sports/Games slots → "Play Hard, Study Hard! ⚽" blue card
  - 🟣 Assembly/Rest/Library slots → "Peace & Recharge! 🧘" purple card

### 📅 Attendance (FAANG-Level Interactive Calendar)
- [x] Dynamic month-by-month interactive calendar grid
- [x] `<` and `>` quick month navigation with real-time state filtering
- [x] "Return to Today" quick jump calendar icon
- [x] Present/Absent/Leave/Holiday/Weekly-Off visual markers
- [x] Daily stats auto-calculated based on selected viewing month

### 💰 Fees
- [x] Fee structure display
- [x] Payment status (Paid/Pending)
- [x] Total fee and remarks

### 🧪 Tests & Results
- [x] Test list with status (upcoming, published)
- [x] Result detail with score + max marks
- [x] Performance percentage

### 📈 Performance
- [x] fl_chart graphs for test scores
- [x] Subject-wise performance breakdown
- [x] Leaderboard rank display

### 📖 Syllabus
- [x] Topic completion progress by subject
- [x] Drill-down to chapter detail

### 📢 Notices & Support
- [x] School + coaching notice feed
- [x] Doubt Room: Post doubt, reply, filter
- [x] Support / Suggestion Center

### 👤 Profile
- [x] Student info (name, class, wing)
- [x] Leaderboard position
- [x] Logout

### 🔔 Push Notifications
- [x] OneSignal integrated for push alerts

---

## 🎨 Design System

- **Style**: Premium modern design (some rounded, some sharp per screen)
- **Primary Color**: App-specific (from `AppTheme`)
- **Font**: Google Fonts (system + web)
- **Charts**: fl_chart for performance visualization

---

## 🏗️ Pending / TODO

- [ ] **Consistent Zero-Fillet Design** — Some screens still use `BorderRadius.circular(20+)`. Needs audit for uniform sharp-edge style.
- [ ] **Homework Submission Upload** — File/image upload from student side not implemented (only text submission tracking exists)
- [ ] **Study Material Downloads** — PDFs linked but offline download/save not implemented
- [ ] **Dark Mode** — Not implemented
- [ ] **Biometric Login** — No fingerprint/face unlock
- [ ] **Parent View** — No parent-facing portal (only student login)
- [ ] **App Version Check** — No forced update mechanism

---

## 🚀 Local Setup

```bash
# Install dependencies
flutter pub get

# Generate splash screen + icons
dart run flutter_native_splash:create
dart run flutter_launcher_icons

# Run on device/emulator
flutter run

# Analyze code
flutter analyze

# Build APK
flutter build apk --release
```

---

## 🔐 Environment

Connects to the **LakshyaMarch ERP backend** (`lakshyamarch.com/api`).  
Auth token stored via `SharedPreferences` after login.

---

*© 2026 LakshyaMarch Education — Internal Use Only*