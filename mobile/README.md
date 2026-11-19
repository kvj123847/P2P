# Learn Share Grow – Peer-to-Peer Student Learning App (Flutter Frontend)

A complete, clickable frontend for the peer-teaching app, built with **Flutter + Dart**.
Everything runs on **mock data**, so you can demo the whole workflow before the backend exists.
It uses **no third-party packages**, so it should build on the first try.

---

## 1. One-time setup (do this once on your laptop)

1. **Install Flutter**: follow https://docs.flutter.dev/get-started/install for your OS
   (Windows: download the zip, extract to `C:\src\flutter`, add `C:\src\flutter\bin` to PATH).
2. **Install Android Studio** (it gives you the Android SDK and an emulator).
   Open it once → *More Actions → SDK Manager* → install the latest Android SDK +
   *Android SDK Command-line Tools*.
3. **Install VS Code** + the **Flutter** extension (it installs the Dart extension too).
4. Open a terminal and run:

   ```bash
   flutter doctor
   flutter doctor --android-licenses   # press y to accept all
   ```

   Fix anything marked ✗ until Flutter and Android toolchain show ✓.

---

## 2. Run this project

```bash
# 1. Unzip, then go into the folder
cd mobile

# 2. Generate the platform folders (android/, ios/, web/ ...).
#    This does NOT touch the lib/ code that is already here.
flutter create . --project-name peer_learning_mobile --org com.learnsharegrow

# 3. Get dependencies
flutter pub get

# 4. Start an emulator (Android Studio → Device Manager → ▶) or plug in your phone
#    with USB debugging on, then:
flutter run
```

Quick alternative without an emulator: `flutter run -d chrome` (runs in the browser).

To build an APK you can install on any Android phone:

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 3. Demo walkthrough (for your review / viva)

| Step | What to do | What it shows |
|---|---|---|
| 1 | App opens on the **Splash** screen | Branding, animation |
| 2 | **Login** with any email + a 6+ character password (e.g. `alex@gmail.com` / `123456`) | Form validation, password masking |
| 3 | Choose **Learner / Tutor / Both** | Role selection (RBAC) |
| 4 | Choose **School (<18)** or **College (18+)**, pick date of birth, tap *Upload ID* | Age-tier verification (DOB must match the tier) |
| 5 | Fill or skip **Profile setup** | Onboarding |
| 6 | **Home dashboard** → Quick actions, popular subjects, recommended courses, top tutors | Learner dashboard |
| 7 | **Explore** → search, subject chips, filter button, sort | Tutor search + content library. Only the user's own age tier is shown. |
| 8 | Open a tutor → **Book Session** → pick date/time → **Pay** (try coupon `PEER10`) | Booking + checkout + payment success |
| 9 | **Sessions** tab → **Join** | 1:1 video call UI (mute, camera, screen share, chat, end + rating) |
| 10 | Join a **Group** session | Participant grid, raise hand, participant list |
| 11 | Open a course → **Buy / Enroll** → read or watch | Text reader & video player, progress tracking |
| 12 | **Chat** tab → open a chat → send a message or attach a file | Doubt-solving chat with typing indicator and auto reply |
| 13 | Log in again choosing **Both** → use the **Learning / Teaching** switch | Tutor dashboard, earnings, payouts |
| 14 | Tutor → **Create Course** → add lessons → **Submit for review** | Tutor content upload |
| 15 | Profile → **Mentor Panel (demo)** (or log in with an email containing `mentor`, e.g. `mentor@app.com`) → open the submission → tick the checklist → **Approve** | Mentor review workflow. The approved course then appears in Explore. |
| 16 | Profile → Wallet, Notifications, Settings, Logout | Supporting screens |

---

## 4. Project structure

```
lib/
├── main.dart                 # Entry point – wraps the app in AppScope (state)
├── app.dart                  # MaterialApp + theme + first screen
├── core/
│   ├── constants/app_colors.dart
│   ├── theme/app_theme.dart  # Blue/white Material 3 theme
│   ├── utils/formatters.dart # Date / money helpers
│   └── widgets/              # Reusable widgets
│       ├── common_widgets.dart  (PrimaryButton, CustomTextField, AppCard, StatusChip…)
│       └── cards.dart           (CourseCard, TutorCard, SessionCard…)
├── models/models.dart        # Enums (UserRole, AgeTier, ReviewStatus…) + data classes
├── mock_data/mock_data.dart  # Sample tutors, courses, sessions, chats, payments
├── state/app_state.dart      # App state (ChangeNotifier) – all actions live here
├── services/api_service.dart # REST endpoint list for the future backend
└── features/
    ├── authentication/       # splash, login, signup, forgot password
    ├── onboarding/           # role selection, age verification, profile setup
    ├── dashboard/            # bottom-nav shell, learner dashboard, tutor dashboard
    ├── tutors/               # explore/search, tutor profile, booking
    ├── sessions/             # session list, 1:1 call, group call, create session
    ├── content/              # course details, reader, video player, my learning, upload
    ├── chat/                 # chat list, chat screen
    ├── payments/             # checkout, success, wallet/history, tutor earnings
    ├── mentor/               # mentor dashboard (review queue), content review
    ├── profile/              # profile, edit profile, settings
    └── notifications/
```

**Screens: 33** · **Reusable widgets: 15+** · **External packages: 0**

---

## 5. How it works (technical explanation)

- **Widgets**: every screen is built from small reusable widgets (`AppCard`, `PrimaryButton`, `TutorCard`…).
- **State management**: `AppState` extends Flutter's `ChangeNotifier`. It is provided to the
  whole tree with an `InheritedNotifier` called `AppScope`.
  - `AppScope.of(context)` reads the state **and rebuilds** when it changes (used in `build`).
  - `AppScope.read(context)` reads it **without** listening (used in button callbacks).
  - When a method like `enroll()` calls `notifyListeners()`, every screen showing that data updates.
  - Same idea as Provider/Riverpod, without adding a package.
- **Navigation**: `Navigator.push / pushReplacement / pushAndRemoveUntil` with `MaterialPageRoute`;
  bottom navigation uses `NavigationBar` + `IndexedStack` (keeps each tab's state).
- **Form validation**: `Form` + `TextFormField.validator` (email/phone regex, password rules).
- **Role-based UI (RBAC)**: `UserRole` decides the dashboard (learner vs tutor) and which menu
  items appear. The **backend must also enforce this**; hiding a button is not security.
- **Age-tier separation**: `AppState.visibleTutors` / `visibleCourses` filter by `AgeTier`, so
  school and college users never see each other. The backend must apply the same rule.
- **Mentor review workflow**: tutor submits → `ReviewStatus.pending` → mentor approves/rejects
  with feedback → approved content becomes a live course.

---

## 6. Next steps: connecting real services

| Feature | Package to add | Where to plug it in |
|---|---|---|
| Backend REST API | `http` | `services/api_service.dart` → call from `AppState` methods |
| Secure token storage | `flutter_secure_storage` | after login |
| Google sign-in | `google_sign_in` / `firebase_auth` | `LoginScreen` → Continue with Google |
| Live video | `agora_rtc_engine` + `permission_handler` | `live_video_screen.dart`, `group_session_screen.dart` (replace `ParticipantTile` with `AgoraVideoView`) |
| Recorded video | `video_player` | `video_course_screen.dart` (`_PlayerArea`) |
| Image / file upload | `image_picker`, `file_picker` | age verification, profile photo, content upload, chat attach |
| Real-time chat | `socket_io_client` or Firebase | `chat_screen.dart` |
| Payments | `razorpay_flutter` (India) or `flutter_stripe` | `checkout_screen.dart` → create the order on the backend first |
| Push notifications | `firebase_messaging` | `notifications_screen.dart` |

Add a package with `flutter pub add <name>`.

Suggested backend: **Flask/FastAPI + PostgreSQL**. Endpoint list: `lib/services/api_service.dart`.

---

## 7. Troubleshooting

- **`flutter` not recognized** → Flutter's `bin` folder is not on PATH; restart the terminal after adding it.
- **No devices found** → start an emulator from Android Studio's Device Manager, or use `flutter run -d chrome`.
- **Gradle/Android build errors on first run** → run `flutter clean` then `flutter pub get` and try again;
  make sure `flutter doctor` is all ✓.
- **SDK version error** → this project needs Flutter **3.24 or newer** (`flutter --version`).
  Update with `flutter upgrade`.
- **Deprecation warnings** in the editor are harmless; the app still runs.
