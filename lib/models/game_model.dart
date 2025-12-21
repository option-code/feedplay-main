class GameModel {
  final int? id;
  final String? name;
  final String? gameName;
  final String? url;
  final String? imagePath;
  final String? category;
  final String? description;
  final String? famobi;
  final String? embed;
  final bool? isHorizontalOrientation;
  final bool? isVerticalOrientation;
  final List<String>? images;
  final List<String>? genres;
  final List<String>? mobileReady;
  final List<String>? gender;
  final String? inGamePurchases;
  final List<String>? supportedLanguages;

  GameModel({
    this.id,
    this.name,
    this.gameName,
    this.url,
    this.imagePath,
    this.category,
    this.description,
    this.famobi,
    this.embed,
    this.isHorizontalOrientation,
    this.isVerticalOrientation,
    this.images,
    this.genres,
    this.mobileReady,
    this.gender,
    this.inGamePurchases,
    this.supportedLanguages,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    // Support for data.json format (GameMonetize format)
    // Check for 'thumb1' field (primary indicator) and 'name' field
    if (json.containsKey('thumb1') && json.containsKey('name')) {
      // data.json format (GameMonetize)
      // Try to get width and height if available, otherwise use defaults
      int width = 800;
      int height = 600;

      if (json.containsKey('width')) {
        final widthStr = json['width']?.toString();
        if (widthStr != null) {
          width = int.tryParse(widthStr) ?? 800;
        }
      }

      if (json.containsKey('height')) {
        final heightStr = json['height']?.toString();
        if (heightStr != null) {
          height = int.tryParse(heightStr) ?? 600;
        }
      }

      // Determine orientation: if width > height, it's horizontal
      // Default to horizontal if width/height not available
      final isHorizontal = width >= height;
      final isVertical = height > width;

      // Parse tags string into list
      final tagsStr = json['tags']?.toString() ?? '';
      final tagsList = tagsStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Parse ID - handle both string and int types
      int? gameId;
      if (json['id'] != null) {
        if (json['id'] is int) {
          gameId = json['id'] as int;
        } else if (json['id'] is String) {
          gameId = int.tryParse(json['id'] as String);
        } else {
          gameId = int.tryParse(json['id'].toString());
        }
      }

      return GameModel(
        id: gameId,
        name: json['name']?.toString(),
        gameName: json['name']?.toString(),
        url: json['url']?.toString(),
        imagePath: json['thumb1']?.toString(),
        category: json['category']?.toString(),
        description: json['description']?.toString(),
        famobi: json['url']?.toString(),
        embed: null,
        isHorizontalOrientation: isHorizontal,
        isVerticalOrientation: isVertical,
        images: [json['thumb']?.toString()].whereType<String>().toList(),
        genres: tagsList.isNotEmpty ? tagsList : null,
        // Extract mobileReady
        mobileReady: (json['mobileReady'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        // Extract gender
        gender: (json['gender'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        // Extract inGamePurchases
        inGamePurchases: json['inGamePurchases'] as String?,
        // Extract supportedLanguages
        supportedLanguages: (json['supportedLanguages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );
    }

    // Support for Playgama format
    if (json.containsKey('gameURL') ||
        (json.containsKey('title') && json.containsKey('segments'))) {
      // Playgama format
      final imagesList = json['images'] as List<dynamic>?;
      final firstImage = imagesList != null && imagesList.isNotEmpty
          ? imagesList[0] as String
          : null;

      // Convert images list to List<String>
      final images = imagesList?.map((e) => e.toString()).toList();

      final genresList = json['genres'] as List<dynamic>?;
      final category = genresList != null && genresList.isNotEmpty
          ? genresList[0] as String
          : null;

      // Convert genres list to List<String>
      final genres = genresList?.map((e) => e.toString()).toList();

      // Extract mobileReady
      final mobileReadyList = json['mobileReady'] as List<dynamic>?;
      final mobileReady = mobileReadyList?.map((e) => e.toString()).toList();

      // Extract gender
      final genderList = json['gender'] as List<dynamic>?;
      final gender = genderList?.map((e) => e.toString()).toList();

      // Extract inGamePurchases
      final inGamePurchases = json['inGamePurchases'] as String?;

      // Extract supportedLanguages
      final supportedLanguagesList =
          json['supportedLanguages'] as List<dynamic>?;
      final supportedLanguages =
          supportedLanguagesList?.map((e) => e.toString()).toList();

      // Extract screen orientation
      final screenOrientation =
          json['screenOrientation'] as Map<String, dynamic>?;
      final isHorizontal = screenOrientation?['horizontal'] as bool? ?? true;
      final isVertical = screenOrientation?['vertical'] as bool? ?? false;

      // Parse ID - handle both string and int types
      int? gameId;
      if (json['id'] != null) {
        if (json['id'] is int) {
          gameId = json['id'] as int;
        } else if (json['id'] is String) {
          gameId = int.tryParse(json['id'] as String);
        } else {
          gameId = int.tryParse(json['id'].toString());
        }
      }

      return GameModel(
        id: gameId,
        name: json['title'] ?? json['slug'],
        gameName: json['title'] ?? json['slug'],
        // Use gameURL (with clid parameter) for revenue tracking - this is the affiliate link
        url: json['gameURL'] ?? json['playgamaGameUrl'],
        imagePath: firstImage ?? json['imagePath'],
        category: category ?? json['category'],
        description: json['description'] ?? json['howToPlayText'],
        // Store gameURL (with clid) in famobi field for backup
        famobi: json['gameURL'],
        embed: json['embed'],
        isHorizontalOrientation: isHorizontal,
        isVerticalOrientation: isVertical,
        images: images,
        genres: genres,
        mobileReady: mobileReady,
        gender: gender,
        inGamePurchases: inGamePurchases,
        supportedLanguages: supportedLanguages,
      );
    }

    // Support for old format (backward compatibility)
    // Parse ID - handle both string and int types
    int? gameId;
    if (json['id'] != null) {
      if (json['id'] is int) {
        gameId = json['id'] as int;
      } else if (json['id'] is String) {
        gameId = int.tryParse(json['id'] as String);
      } else {
        gameId = int.tryParse(json['id'].toString());
      }
    }

    return GameModel(
      id: gameId,
      name: json['name'],
      gameName: json['gameName'] ?? json['name'],
      url: json['url'] ?? json['famobi'],
      imagePath: json['imagePath'],
      category: json['category'],
      description: json['description'],
      famobi: json['famobi'],
      embed: json['embed'],
      isHorizontalOrientation: null,
      isVerticalOrientation: null,
      images: null,
      genres: null,
      mobileReady: null,
      gender: null,
      inGamePurchases: null,
      supportedLanguages: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gameName': gameName,
      'url': url,
      'imagePath': imagePath,
      'category': category,
      'description': description,
      'famobi': famobi,
      'embed': embed,
      'isHorizontalOrientation': isHorizontalOrientation,
      'isVerticalOrientation': isVerticalOrientation,
      'images': images,
      'genres': genres,
      'mobileReady': mobileReady,
      'gender': gender,
      'inGamePurchases': inGamePurchases,
      'supportedLanguages': supportedLanguages,
    };
  }

  String get displayImagePath {
    if (imagePath != null && imagePath!.isNotEmpty) return imagePath!;
    return '';
  }

  String get gameUrl {
    // Priority: url (gameURL with clid) > famobi (gameURL backup) > embed extraction
    // gameURL contains clid parameter for revenue tracking - this is the affiliate link
    if (url != null && url!.isNotEmpty) return url!;
    if (famobi != null && famobi!.isNotEmpty) return famobi!;
    if (embed != null && embed!.isNotEmpty) {
      // Extract URL from embed iframe (may also contain clid)
      final uriMatch = RegExp(r'src="([^"]+)"').firstMatch(embed!);
      if (uriMatch != null) {
        return uriMatch.group(1)!;
      }
    }
    return '';
  }

  /// Check if game is horizontal based on screenOrientation
  bool get isHorizontal {
    if (isHorizontalOrientation != null) {
      return isHorizontalOrientation!;
    }
    // Default to horizontal for old format games
    return true;
  }

  /// Check if game is vertical based on screenOrientation
  bool get isVertical {
    if (isVerticalOrientation != null) {
      return isVerticalOrientation!;
    }
    // Default to false for old format games
    return false;
  }
}
