import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool> connectionChangeController = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Stream<bool> get connectionChange => connectionChangeController.stream;

  void initialize() {
    _connectivity.onConnectivityChanged.listen(_connectionChange);
    checkConnection();
  }

  void _connectionChange(List<ConnectivityResult> results) {
    _checkConnectionStatus(results);
  }

  Future<bool> checkConnection() async {
    bool isConnected = false;
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      isConnected = _checkConnectionStatus(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
    }
    return isConnected;
  }

  bool _checkConnectionStatus(List<ConnectivityResult> results) {
    bool isConnected = false;
    
    for (ConnectivityResult result in results) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet) {
        isConnected = true;
        break;
      }
    }

    // Update connection status (silent - no user alerts)
    if (_isOnline != isConnected) {
      _isOnline = isConnected;
      connectionChangeController.add(isConnected);
      // Silent status change
    }

    return isConnected;
  }

  void dispose() {
    connectionChangeController.close();
  }
}
