```dart
  bool _adInserted = false;

  void _buildInterleavedItems() {
    _interleavedItems.clear();
    _adInserted = false; // Reset the flag when rebuilding the list
    final List<int> adPositions = [1]; // Only show ad at position 1

    for (int i = 0; i < filteredGames.length; i++) {
      _interleavedItems.add(filteredGames[i]); // Add the current game

      // Check if an ad should be inserted after this game
      // i is 0-based index, so (i + 1) is the 1-based game number
      int currentGameNumber = i + 1;

      if (adPositions.contains(currentGameNumber) && !_adInserted) {
        final nativeAd = NativeAdsService.getAd();
        if (nativeAd != null) {
          print(
              'Native Ad: Ad found for insertion at position $currentGameNumber');
          _interleavedItems.add(nativeAd);
          _adInserted = true; // Mark ad as inserted
        } else {
          print(
              'Native Ad: No ad available for insertion at position $currentGameNumber');
        }
      }
    }
  }
```