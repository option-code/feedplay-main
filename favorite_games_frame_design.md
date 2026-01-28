# Favorite Games Horizontal List - Icon Frame Design

## Overview
The horizontal favorites list uses a modern, glass-morphism design with gradient borders and subtle shadows.

## Frame Structure

### 1. Outer Gradient Container
- **Border Radius**: 24px
- **Gradient Colors**: 
  - Start: `#6366F1` (Indigo)
  - Middle: `#8B5CF6` (Purple)
  - End: `#EC4899` (Pink)
- **Shadow**: 
  - Color: Black with 30% opacity
  - Blur Radius: 12px
  - Spread Radius: 2px
  - Offset: `(0, 6)`

### 2. Inner Container
- **Background Color**: `#1A1F2E` with 90% opacity
- **Border Radius**: 20px (slightly smaller than outer container)
- **Border**: 
  - Color: White with 20% opacity
  - Width: 1.5px
- **Clip Behavior**: Anti-alias for smooth edges

### 3. Image Section
- **Aspect Ratio**: Automatically fills container
- **Image Handling**: Uses `CachedNetworkImage` with:
  - `BoxFit.cover` scaling
  - Mem cache size: 280x280
  - Circular progress indicator placeholder
  - Games icon fallback for errors

### 4. Game Name Section
- **Padding**: 8px horizontal, 6px vertical
- **Text Style**: 
  - Color: White
  - Font Size: 11px
  - Height: 1.15
  - Weight: 600 (semi-bold)
  - Max Lines: 2
  - Soft Wrap: Enabled

### 5. Badge System

#### FREE Badge (for free games)
- **Position**: Top-left corner
- **Padding**: 6px horizontal, 3px vertical
- **Gradient Colors**: 
  - Start: `#10B981` (Green)
  - Middle: `#3B82F6` (Blue)
  - End: `#6366F1` (Indigo)
- **Border Radius**: 12px
- **Shadow**: 
  - Color: `#10B981` with 60% opacity
  - Blur Radius: 8px
  - Spread Radius: 2px
  - Offset: `(0, 3)`
- **Text**: "FREE" in white, 8px, bold

#### LOCKED Badge (for premium games)
- **Position**: Top-left corner
- **Size**: 28x28px
- **Background**: Black with 60% opacity, circular
- **Icon**: Lock icon, white, 16px

## Code Implementation
```dart
Widget buildItem(GameModel game) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6366F1),
          Color(0xFF8B5CF6),
          Color(0xFFEC4899),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          spreadRadius: 2,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    padding: const EdgeInsets.all(4),
    child: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: game.imagePath != null && game.imagePath!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _resolveImageUrl(game),
                        fit: BoxFit.cover,
                        memCacheWidth: 280,
                        memCacheHeight: 280,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B5CF6),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.games,
                            size: 36,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.games,
                          size: 36,
                          color: Colors.white70,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  game.gameName ?? game.name ?? 'Game',
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (widget.isFreeForToday(game))
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF3B82F6),
                      Color(0xFF6366F1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'FREE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else if (widget.isPremium(game))
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
```

## Design Features
- **Modern Aesthetic**: Glass-morphism with gradient borders
- **Depth**: Multiple shadow layers create a sense of elevation
- **Consistency**: Matches the app's overall purple/pink/indigo color scheme
- **Responsive**: Adapts to different screen sizes (shows navigation buttons on larger screens)
- **Performance**: Optimized image loading with caching
- **Accessibility**: Clear visual indicators for free vs premium games

## Usage
This frame is used for all games in the horizontal favorites list, providing a consistent and visually appealing design for user-selected favorite games.