import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/game_model.dart';
import 'game_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Notification messages pool
  static final List<String> _messages = [
    "Try these games! 🎮",
    "New games waiting for you! 🚀",
    "Discover amazing games! ✨",
    "Start playing now! 🎯",
    "Your daily dose of fun! 🎊",
    "Time to play! 🕹️",
    "Ready for some gaming? 🎮",
    "Check out these awesome games! 🌟",
  ];

  static Future<bool?> requestNotificationPermissions() async {
    if (kIsWeb) {
      print('Notifications not supported on web platform');
      return false;
    }
    // Request permission for Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      return await androidImplementation.requestNotificationsPermission();
        }
        return false;
      }

  static Future<bool> checkNotificationPermissions() async {
    if (kIsWeb) {
      return false;
    }
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.areNotificationsEnabled();
      return granted ?? false;
    }
    return false;
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    // Skip notifications on web platform
    if (kIsWeb) {
      print('Notifications not supported on web platform');
      _initialized = true;
      return;
    }

    try {
      // Initialize timezone - automatically uses system timezone
      tz.initializeTimeZones();
      // tz.local will automatically use the device's system timezone
      // No need to set it manually - works globally for all countries

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'daily_games_channel',
        'Daily Games Notifications',
        description: 'Notifications about daily game recommendations',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _initialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
      _initialized = true; // Mark as initialized to prevent retries
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen
    print('Notification tapped: ${response.payload}');
  }

  static Future<void> scheduleDailyNotifications() async {
    await initialize();

    // Skip on web
    if (kIsWeb) {
      print('Skipping notification scheduling on web platform');
      return;
    }

    try {
      // Cancel existing notifications first
      await _notifications.cancelAll();

      // Schedule 4 notifications per day - (hour, minute)
      final times = [
        (9, 0), // 9:00 AM
        (13, 0), // 1:00 PM
        (17, 0), // 5:00 PM
        (20, 0), // 8:00 PM
      ];

      for (int i = 0; i < times.length; i++) {
        await _scheduleNotification(times[i].$1, times[i].$2, i);
      }

      print('Scheduled 4 daily notifications');
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  static Future<void> _scheduleNotification(
      int hour, int minute, int id) async {
    // Use system's local timezone automatically
    // DateTime.now() uses device's system timezone
    final now = DateTime.now();

    // Create scheduled time in local timezone
    // matchDateTimeComponents: DateTimeComponents.time will ensure
    // notifications fire at the same local time regardless of timezone
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      DateTime(now.year, now.month, now.day, hour, minute),
      tz.local,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(tz.TZDateTime.from(now, tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Get random games for notification
    final games = await _getRandomGames();

    final message = _messages[Random().nextInt(_messages.length)];
    final body = _buildNotificationBody(games);

    await _notifications.zonedSchedule(
      id,
      message,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_games_channel',
          'Daily Games Notifications',
          channelDescription: 'Notifications about daily game recommendations',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/notification_icon',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(body),
          enableLights: true,
          color: const Color(0xFF0B1C2C),
          ledColor: const Color(0xFF0B1C2C),
          ledOnMs: 1000, // Required for Android < Oreo
          ledOffMs: 500, // Required for Android < Oreo
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'games_notification_$id',
    );
  }

  static Future<List<GameModel>> _getRandomGames() async {
    final horizontalGames = await GameService.loadHorizontalGames();
    final allGames = [...horizontalGames];
    if (allGames.isEmpty) return [];
    final random = Random();
    final selected = <GameModel>[];
    final availableIndices = List<int>.generate(allGames.length, (i) => i);
    // Select 5 random games
    for (int i = 0; i < 5 && availableIndices.isNotEmpty; i++) {
      final index = random.nextInt(availableIndices.length);
      final gameIndex = availableIndices.removeAt(index);
      selected.add(allGames[gameIndex]);
    }
    return selected;
  }

  static String _buildNotificationBody(List<GameModel> games) {
    if (games.isEmpty) {
      return "Check out amazing HTML5 games in FeedPlay! 🎮\n\nDiscover new games and have endless fun!";
    }

    final gameNames = games
        .map((g) => '• ${g.gameName ?? g.name ?? 'Game'}')
        .take(5)
        .join('\n');

    return "🎮 Featured Games:\n$gameNames\n\n👉 Tap to play now!";
  }

  static Future<void> showInstantNotification(List<GameModel> games) async {
    await initialize();

    if (kIsWeb) {
      print('Notifications not supported on web platform');
      return;
    }

    try {
      final randomMessage = _messages[Random().nextInt(_messages.length)];

      final body = _buildNotificationBody(games);

      await _notifications.show(
        Random().nextInt(10000),
        randomMessage,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_games_channel',
            'Daily Games Notifications',
            channelDescription:
                'Notifications about daily game recommendations',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/notification_icon',
            largeIcon:
                const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(body),
            enableLights: true,
            color: const Color(0xFF0B1C2C),
            ledColor: const Color(0xFF0B1C2C),
            ledOnMs: 1000, // Required for Android < Oreo
            ledOffMs: 500, // Required for Android < Oreo
          ),
        ),
        payload: 'instant_notification',
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error cancelling notifications: $e');
    }
  }
}
