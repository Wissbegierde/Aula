import 'package:flutter/foundation.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _initialized = true;
    } catch (e) {
      debugPrint('Firebase init skipped (config files needed): $e');
    }
  }
}
