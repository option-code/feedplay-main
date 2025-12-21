# GamePlus - HTML5 Games App

A Flutter application for playing HTML5 games with support for both mobile and web platforms.

## Features

- 📱 **Mobile & Web Support**: Works on Android, iOS, and Web browsers
- 🎮 **Horizontal Games**: Loads games from local `games.json` file
- 📲 **Vertical Games**: Loads games from HTMLGames.com API
- 🎨 **Dark Theme**: Beautiful dark theme with custom colors
- 🔍 **Search**: Search games by name or category
- 🌐 **WebView**: Play HTML5 games directly in the app

## Setup

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run on Android:**
   ```bash
   flutter run
   ```

3. **Run on Web:**
   ```bash
   flutter run -d chrome
   ```

## Configuration

The app uses:
- **Background Color**: `#0B1C2C`
- **Theme Color**: `#0B1C2C`
- **Adaptive Icon Background**: `#0A0E1A`

Icons and splash screens are located in the `res/` folder and will be automatically loaded for Android builds.

## Project Structure

```
lib/
  ├── main.dart                 # App entry point
  ├── models/
  │   └── game_model.dart      # Game data model
  ├── services/
  │   └── game_service.dart    # Game loading service
  └── screens/
      ├── home_screen.dart           # Main navigation screen
      ├── horizontal_games_screen.dart  # Horizontal games list
      ├── vertical_games_screen.dart    # Vertical games list
      └── game_player_screen.dart      # WebView game player
```

## License

This project is private and proprietary.

