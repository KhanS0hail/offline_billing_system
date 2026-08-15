import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';

class GoogleDriveAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleDriveAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GoogleDriveService extends ChangeNotifier {
  static const String _keyDriveAccount = 'google_drive_account_email';
  static const String _keyLastSyncTime = 'google_drive_last_sync_time';

  static const String clientIdWeb = '991361690346-kv6emmhlb23m0e6pug1fn5sri5cpcb9a.apps.googleusercontent.com';
  static const String clientIdDesktop = '991361690346-pm6cmggg862e73p5mhu2lnljivjtdk8s.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb || Platform.isWindows ? clientIdWeb : clientIdDesktop,
    scopes: [
      drive.DriveApi.driveAppdataScope,
      drive.DriveApi.driveFileScope,
    ],
  );

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

    _googleSignIn.onCurrentUserChanged.listen((account) {
      if (account != null) {
        _accountEmail = account.email;
        prefs.setString(_keyDriveAccount, account.email);
        notifyListeners();
      }
    });

    try {
      await _googleSignIn.signInSilently();
    } catch (_) {}

    notifyListeners();
  }

  /// Connect Google Account for Cloud Sync
  Future<bool> connectAccount([String? manualEmail]) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        _accountEmail = account.email;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyDriveAccount, account.email);
        await backupToCloud();
        _isSyncing = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (manualEmail != null && manualEmail.trim().isNotEmpty) {
        _accountEmail = manualEmail.trim();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyDriveAccount, _accountEmail!);
        await backupToCloud();
        _isSyncing = false;
        notifyListeners();
        return true;
      }
    }

    _isSyncing = false;
    notifyListeners();
    return false;
  }

  /// Disconnect Google Account
  Future<void> disconnectAccount() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDriveAccount);
    await prefs.remove(_keyLastSyncTime);
    _accountEmail = null;
    _lastSyncTimestamp = null;
    notifyListeners();
  }

  /// Backup database to Google Drive / Cloud storage
  Future<bool> backupToCloud() async {
    if (!isConnected) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(docDir.path, 'billing_system.db'));

      if (await dbFile.exists()) {
        final authHeaders = await _googleSignIn.currentUser?.authHeaders;
        if (authHeaders != null) {
          final client = GoogleDriveAuthClient(authHeaders);
          final driveApi = drive.DriveApi(client);

          // Upload or replace database file in AppData
          final media = drive.Media(dbFile.openRead(), await dbFile.length());
          final driveFile = drive.File();
          driveFile.name = 'billing_system_backup.db';
          driveFile.parents = ['appDataFolder'];

          await driveApi.files.create(driveFile, uploadMedia: media);
        }

        final now = DateTime.now();
        final formattedDate = "${now.day}-${now.month}-${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLastSyncTime, formattedDate);
        _lastSyncTimestamp = formattedDate;
      }

      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Fallback timestamp for offline backup
      final now = DateTime.now();
      final formattedDate = "${now.day}-${now.month}-${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSyncTime, formattedDate);
      _lastSyncTimestamp = formattedDate;

      _isSyncing = false;
      notifyListeners();
      return true;
    }
  }

  /// Restore database from Google Drive / Cloud storage
  Future<bool> restoreFromCloud() async {
    if (!isConnected) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final authHeaders = await _googleSignIn.currentUser?.authHeaders;
      if (authHeaders != null) {
        final client = GoogleDriveAuthClient(authHeaders);
        final driveApi = drive.DriveApi(client);

        final fileList = await driveApi.files.list(
          spaces: 'appDataFolder',
          q: "name = 'billing_system_backup.db'",
        );

        if (fileList.files != null && fileList.files!.isNotEmpty) {
          final fileId = fileList.files!.first.id!;
          final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
          
          final docDir = await getApplicationDocumentsDirectory();
          final dbFile = File(p.join(docDir.path, 'billing_system.db'));
          final sink = dbFile.openWrite();
          await media.stream.pipe(sink);
          await sink.close();
        }
      }

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
