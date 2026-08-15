import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService extends ChangeNotifier {
  static const String _keyPin = 'app_security_pin';
  static const String _keyPinEnabled = 'app_security_pin_enabled';

  bool _isLocked = false;
  bool _isPinSet = false;
  bool _isPinEnabled = false;

  bool get isLocked => _isLocked;
  bool get isPinSet => _isPinSet;
  bool get isPinEnabled => _isPinEnabled;

  AppLockService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_keyPin);
    _isPinEnabled = prefs.getBool(_keyPinEnabled) ?? false;
    _isPinSet = pin != null && pin.isNotEmpty;

    if (_isPinEnabled && _isPinSet) {
      _isLocked = true;
    } else {
      _isLocked = false;
    }
    notifyListeners();
  }

  Future<bool> setPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPin, newPin);
    await prefs.setBool(_keyPinEnabled, true);
    _isPinSet = true;
    _isPinEnabled = true;
    _isLocked = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_keyPin);
    if (savedPin == enteredPin) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPinEnabled, enabled);
    _isPinEnabled = enabled;
    notifyListeners();
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPin);
    await prefs.setBool(_keyPinEnabled, false);
    _isPinSet = false;
    _isPinEnabled = false;
    _isLocked = false;
    notifyListeners();
  }

  void lockApp() {
    if (_isPinEnabled && _isPinSet) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void unlockApp() {
    _isLocked = false;
    notifyListeners();
  }
}
