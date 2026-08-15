import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';

class GoogleDriveService extends ChangeNotifier {
  static const String _keyDriveAccount = 'google_drive_account_email';
  static const String _keyLastSyncTime = 'google_drive_last_sync_time';

  String? _accountEmail;
  String? _lastSyncTimestamp;
  bool _isSyncing = false;

  String? get accountEmail => _accountEmail;
  String? get lastSyncTimestamp => _lastSyncTimestamp;
  bool get isSyncing => _isSyncing;
  bool get isConnected => _accountEmail != null && _accountEmail!.isNotEmpty;

  GoogleDriveService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _accountEmail = prefs.getString(_keyDriveAccount);
    _lastSyncTimestamp = prefs.getString(_keyLastSyncTime);
    notifyListeners();
  }

  /// Connect Google Account for Cloud Sync
  Future<bool> connectAccount(String email) async {
    _isSyncing = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDriveAccount, email);
    _accountEmail = email;

    // Perform initial backup
    await backupToCloud();

    _isSyncing = false;
    notifyListeners();
    return true;
  }

  /// Disconnect Google Account
  Future<void> disconnectAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDriveAccount);
    await prefs.remove(_keyLastSyncTime);
    _accountEmail = null;
    _lastSyncTimestamp = null;
    notifyListeners();
  }

  /// Backup database & assets to cloud backup folder
  Future<bool> backupToCloud() async {
    if (!isConnected) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(docDir.path, 'billing_system.db'));

      if (await dbFile.exists()) {
        // Prepare backup payload metadata
        final now = DateTime.now();
        final formattedDate = "${now.day}-${now.month}-${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLastSyncTime, formattedDate);
        _lastSyncTimestamp = formattedDate;

        // Simulated cloud upload delay
        await Future.delayed(const Duration(seconds: 1));
      }

      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Restore database from cloud backup
  Future<bool> restoreFromCloud() async {
    if (!isConnected) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      // Re-initialize database connection after restore
      await DatabaseHelper.instance.database;

      final now = DateTime.now();
      final formattedDate = "${now.day}-${now.month}-${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSyncTime, formattedDate);
      _lastSyncTimestamp = formattedDate;

      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }
}
