# FreeTimeTracker (FTT) 🎮 🎬

A native, sleek entertainment tracker for **Games, Movies, and TV Shows** inspired by the design language of [Nook](https://gamersnook.app/). Built with Flutter for Android and Linux Desktop.

---

## ✨ Features

- **Virtual 3D Shelves (Photo 2)**: Physical-style display shelves with wooden/gunmetal textures, bevels, and depth where game boxes and movie cases sit upright.
- **Play & Watch History Timeline (Photo 4)**: Vertical timeline track with date badges (`8 Sat`), session lengths, platforms, and 10-star ratings.
- **Floating Translucent Nav Dock (Photos 1 & 2)**: Glassmorphic navigation bar floating above content with `Home`, `Library`, `Timeline`, `Stats`, and `Search`.
- **Dynamic Ambient Hero Banner (Photo 3)**: Edge-to-edge backdrop artwork that softly gradients into an OLED dark background.
- **Playing & Watching Now Cards (Photo 3)**: Circular progress indicators, last activity relative timestamps, and one-tap `+` session logger.
- **Platforms & Formats Sheet (Photo 1 Screen 5)**: Track ownership (Steam, PS5, Switch, Netflix, 4K Blu-ray, etc.), digital vs physical, price paid, and purchase dates.
- **Ratings & Analytics (Photo 1 Screen 1)**: Visual ratings distribution bar chart (1 to 10 scale) and monthly activity calendar grid.
- **Steam Integration**: Connect via Steam Web API or try the instant **One-Click Demo Sync** to import your Steam library, total playtime hours, and recent activity.
- **Unified Media Engine**: Instant toggle between `[ 🎮 Games ]` and `[ 🎬 Cinema ]`.

---

## 🚀 How to Run

### Run on Linux Desktop (Instantly on this machine)
```bash
cd /home/tms/Documents/FTT
flutter run -d linux
```

### Build Android APK
```bash
cd /home/tms/Documents/FTT
flutter build apk --debug
# The APK will be generated at: build/app/outputs/flutter-apk/app-debug.apk
```

### Run Tests & Verification
```bash
flutter test
flutter analyze
```

---

## 📂 Project Structure

```
lib/
├── main.dart                       # App entry point & theme initialization
├── models/
│   ├── media_item.dart             # Unified Game/Movie/TV entity
│   ├── media_type.dart             # MediaType (game, movie, tvShow)
│   ├── library_entry.dart          # Status (Playing, Backlog, Finished), platform, price
│   ├── play_session.dart           # Timeline session with duration, date, rating
│   └── steam_profile.dart          # Steam profile, games & playtime model
├── services/
│   ├── database_service.dart       # Reactive state & offline repository
│   ├── steam_service.dart          # Steam Web API client + Demo generator
│   └── sample_data.dart            # Curated catalog (Zelda, Silent Hill f, Fable, Dune 2, Severance)
├── theme/
│   ├── app_colors.dart             # Nook OLED dark palette & shelf gradients
│   └── app_theme.dart              # Typography & Material 3 dark theme
├── widgets/
│   ├── shelf_view.dart             # 3D physical shelves with box covers & planks
│   ├── floating_nav_bar.dart       # Frosted glass floating pill dock
│   ├── timeline_view.dart          # Vertical timeline with date badges
│   ├── hero_banner.dart            # Ambient backdrop header
│   ├── playing_now_card.dart       # Circular progress card with quick session log
│   ├── format_bottom_sheet.dart    # Platforms, ownership & price sheet
│   └── stats_charts.dart           # Ratings distribution bar chart & monthly grid
└── screens/
    ├── main_shell.dart             # Tab container coordinating the floating dock
    ├── home_screen.dart            # Hero + Playing Now + Up Next + New Releases
    ├── library_screen.dart         # Virtual shelves view (Full, Backlog, Completed)
    ├── timeline_screen.dart        # Play & Watch History chronological timeline
    ├── statistics_screen.dart      # Ratings distribution chart & metrics
    ├── search_screen.dart          # Search & discover catalog
    ├── media_detail_screen.dart    # Detailed overview, session logger & format sheet
    └── steam_sync_screen.dart      # Steam account connection & sync settings
```
