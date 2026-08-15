import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class BackupService extends ChangeNotifier {
  static const String _keyLastBackupTime = 'local_backup_last_time';

  String? _lastBackupTimestamp;
  bool _isBusy = false;

  String? get lastBackupTimestamp => _lastBackupTimestamp;
  bool get isBusy => _isBusy;

  BackupService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _lastBackupTimestamp = prefs.getString(_keyLastBackupTime);
    notifyListeners();
  }

  /// Export database backup file and share via WhatsApp, Email, USB, etc.
  Future<bool> exportBackup(BuildContext context) async {
    _isBusy = true;
    notifyListeners();

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(docDir.path, 'billing_system.db'));

      if (!await dbFile.exists()) {
        _isBusy = false;
        notifyListeners();
        return false;
      }

      // Create a timestamped copy for sharing
      final now = DateTime.now();
      final timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";
      final backupFileName = 'billing_backup_$timestamp.db';

      final tempDir = await getApplicationCacheDirectory();
      final backupFile = await dbFile.copy(p.join(tempDir.path, backupFileName));

      // Share via system share sheet (WhatsApp, Email, Bluetooth, USB, etc.)
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Billing System Database Backup',
        text: 'Billing System backup file from $timestamp. Use "Import Backup" in the app to restore.',
      );

      // Update last backup timestamp
      final formattedDate = "${now.day}-${now.month}-${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastBackupTime, formattedDate);
      _lastBackupTimestamp = formattedDate;

      _isBusy = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isBusy = false;
      notifyListeners();
      return false;
    }
  }

  /// Import and restore database from a backup .db file
  Future<bool> importBackup() async {
    _isBusy = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty || result.files.first.path == null) {
        _isBusy = false;
        notifyListeners();
        return false;
      }

      final selectedFile = File(result.files.first.path!);

      // Validate it's a valid SQLite file (starts with "SQLite format 3")
      final bytes = await selectedFile.readAsBytes();
      if (bytes.length < 16) {
        _isBusy = false;
        notifyListeners();
        return false;
      }

      final header = String.fromCharCodes(bytes.sublist(0, 15));
      if (!header.startsWith('SQLite format 3')) {
        _isBusy = false;
        notifyListeners();
        return false;
      }

      // Replace the current database with the backup
      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(docDir.path, 'billing_system.db');

      // Close existing DB connection before replacing
      await DatabaseHelper.instance.close();

      // Copy backup over the current database
      await selectedFile.copy(dbPath);

      // Re-open database connection
      await DatabaseHelper.instance.database;

      // Update timestamp
      final now = DateTime.now();
      final formattedDate = "${now.day}-${now.month}-${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastBackupTime, formattedDate);
      _lastBackupTimestamp = formattedDate;

      _isBusy = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isBusy = false;
      notifyListeners();
      return false;
    }
  }
}
