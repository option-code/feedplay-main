# FeedPlay - Ultimate HTML5 Game Hub

FeedPlay is a comprehensive Flutter application designed to provide a seamless gaming experience across mobile (Android/iOS) and web platforms. It features a curated collection of HTML5 games, organized into intuitive categories, with robust offline capabilities and an integrated ad monetization system.

## 🎮 Features

-   **Cross-Platform Support**: Optimized for Android, iOS, and Web.
-   **Hybrid Game Library**:
    -   **Local Games**: Instant-load games from local assets (`games.json`).
    -   **Online Games**: Dynamic content fetched from remote APIs (HTMLGames.com).
-   **Smart Caching**:
    -   Images are cached using `CachedNetworkImage` for performance.
    -   Web games are optimized for smooth playback.
-   **Ad Monetization**:
    -   **Native Ads**: Seamlessly integrated into game lists (Mobile only).
    -   **Interstitial & Reward Ads**: Strategic placement during gameplay transitions.
    -   **Web Optimization**: Ads are automatically disabled or adjusted for web builds to ensure compliance and user experience.
-   **User Personalization**:
    -   **Favorites**: Save games to a personalized list.
    -   **History**: Quickly access recently played games.
-   **Modern UI/UX**:
    -   **Dark Theme**: Sleek, eye-friendly dark mode (`#0B1C2C`).
    -   **Glassmorphism**: Modern UI elements with blur and transparency effects.
    -   **Animations**: Smooth transitions and touch feedback.

## 🏗️ Architecture

The project follows a clean, service-oriented architecture:

### 📂 Directory Structure

```
lib/
├── main.dart                  # Application entry point and theme config
├── models/
│   └── game_model.dart        # Unified data model for local and API games
├── screens/
│   ├── home_screen.dart       # Main dashboard with favorites and categories
│   ├── horizontal_games_screen.dart # Horizontal list view for specific categories
│   ├── vertical_games_screen.dart   # Vertical grid/list for extensive libraries
│   └── game_player_screen.dart      # WebView container for game execution
├── services/
│   ├── game_service.dart      # Handles fetching games from JSON/API
│   ├── native_ads_service.dart    # Manages Native Ad loading and placement
│   ├── interstitial_ads_service.dart # Handles full-screen interstitial ads
│   ├── reward_ads_service.dart    # Manages rewarded video ads
│   ├── offline_storage_service.dart # Persists user data (favorites, settings)
│   └── rate_share_service.dart    # App rating and sharing functionality
└── widgets/                   # Reusable UI components
```

### 🧩 Key Components

#### Game Management
-   **GameService**: The central repository for game data. It merges local assets and remote API data into a unified stream.
-   **GameModel**: Supports various properties like `isPortrait`, `categories`, and `videoUrl` for rich game previews.

#### Ad System
-   **Native Ads**: Implemented in `_NativeAdWidget` and injected into lists using `SliverChildBuilderDelegate`. Logic in `_getGameIndex` ensures ads don't disrupt game indexing.
-   **Web Compatibility**: Uses `kIsWeb` constants to conditionally render ads, preventing errors on non-mobile platforms (e.g., "Null check operator" fixes).

#### Navigation & State
-   **HomeScreen**: Acts as the central hub, managing the "Favorites" and "All Games" views.
-   **WebView**: `GamePlayerScreen` uses `webview_flutter` (or `iframe` on web) to run HTML5 content securely.

## 🚀 Getting Started

### Prerequisites
-   Flutter SDK (Latest Stable)
-   Android Studio / VS Code
-   Valid AdMob App ID (configured in `AndroidManifest.xml` and `Info.plist`)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/yourusername/feedplay.git
    cd feedplay
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the App**
    -   **Android**: `flutter run`
    -   **Web**: `flutter run -d chrome`

## 🛠️ Configuration

-   **Ads**: Configure AdMob IDs in `lib/services/*_ads_service.dart`.
-   **Theme**: Modify `AppTheme` in `main.dart` to customize colors and fonts.
-   **Assets**: Add new local games to `assets/games.json` and place game icons in `assets/images/`.

## 📱 Screenshots

*(Add screenshots here)*

## 📄 License

Proprietary Software. All rights reserved.
