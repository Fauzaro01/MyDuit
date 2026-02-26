import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Backup schedule options
enum BackupSchedule { none, weekly, monthly }

class GoogleDriveService {
  static const _scopes = ['https://www.googleapis.com/auth/drive.file'];
  static const _backupFileName = 'myduit_backup.db';
  static const _folderName = 'MyDuit Backups';

  // SharedPreferences keys
  static const _prefSignedIn = 'gdrive_signed_in';
  static const _prefUserEmail = 'gdrive_user_email';
  static const _prefSchedule = 'gdrive_backup_schedule';
  static const _prefLastAutoBackup = 'gdrive_last_auto_backup';

  /// Web Application OAuth Client ID from Google Cloud Console.
  /// This is required by google_sign_in v7.x on Android.
  static const _serverClientId =
      '1064880963972-ha7f2fissbeo8df8kpfns03arunh966o.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;

  /// Initialize GoogleSignIn — must be called once before any sign-in.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _googleSignIn.initialize(serverClientId: _serverClientId);
      _initialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn init error: $e');
    }
  }

  static GoogleSignInAccount? _currentUser;
  static GoogleSignInAccount? get currentUser => _currentUser;
  static String? get userEmail => _currentUser?.email ?? _cachedEmail;

  /// Cached email from SharedPreferences (shown while session restores)
  static String? _cachedEmail;

  /// Whether user has an active Google session object
  static bool get hasLiveSession => _currentUser != null;

  /// Last error for UI display
  static String? _lastError;
  static String? get lastError => _lastError;

  // ─── Step 1: Check connection status (SharedPreferences only) ───

  /// Fast check — reads only SharedPreferences, no network/auth calls.
  /// Returns true if user was previously signed in.
  static Future<bool> checkConnectionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final connected = prefs.getBool(_prefSignedIn) ?? false;
    if (connected) {
      _cachedEmail = prefs.getString(_prefUserEmail);
    }
    return connected;
  }

  // ─── Step 2: Silent session restore (lightweight auth, up to 3x) ───

  /// Try to silently restore the Google session without showing any UI.
  /// Attempts lightweight auth up to [maxAttempts] times.
  /// Returns true if session was restored.
  static Future<bool> restoreSessionSilently({int maxAttempts = 3}) async {
    await init();
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final account = await _googleSignIn.attemptLightweightAuthentication();
        if (account != null) {
          _currentUser = account;
          _cachedEmail = account.email;
          debugPrint('Session restored silently (attempt ${i + 1})');
          return true;
        }
      } catch (e) {
        debugPrint('Lightweight auth attempt ${i + 1} failed: $e');
      }
      // Small delay before retry
      if (i < maxAttempts - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    debugPrint('All $maxAttempts lightweight auth attempts failed');
    return false;
  }

  // ─── Step 3: Interactive sign-in (lightweight 3x → full auth) ────

  /// Full sign-in flow: tries lightweight 3x, then falls back to
  /// interactive authenticate() that shows Google UI.
  /// Returns error message on failure, null on success.
  static Future<String?> signIn() async {
    _lastError = null;
    await init();

    // First: try silent restore
    final silentOk = await restoreSessionSilently();
    if (silentOk) {
      await _persistSignIn();
      return null;
    }

    // Fallback: full interactive auth
    try {
      _currentUser = await _googleSignIn.authenticate(scopeHint: _scopes);
      if (_currentUser == null) {
        _lastError = 'Login dibatalkan atau akun tidak dipilih';
        return _lastError;
      }
      await _persistSignIn();
      return null; // success
    } catch (e) {
      _lastError = _parseAuthError(e);
      return _lastError;
    }
  }

  /// Save sign-in state to SharedPreferences
  static Future<void> _persistSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSignedIn, true);
    await prefs.setString(_prefUserEmail, _currentUser!.email);
    _cachedEmail = _currentUser!.email;
  }

  /// Parse auth exceptions into user-friendly messages
  static String _parseAuthError(Object e) {
    final errStr = e.toString();
    debugPrint('Google Sign-In error: $e');

    if (errStr.contains('sign_in_canceled') || errStr.contains('canceled')) {
      return 'Login dibatalkan oleh pengguna';
    } else if (errStr.contains('network_error') ||
        errStr.contains('ApiException: 7')) {
      return 'Tidak ada koneksi internet';
    } else if (errStr.contains('ApiException: 12500') ||
        errStr.contains('DEVELOPER_ERROR') ||
        errStr.contains('ApiException: 10') ||
        errStr.contains('clientConfigurationError')) {
      return 'Konfigurasi OAuth belum benar. Hubungi developer.';
    } else if (errStr.contains('ApiException: 12501')) {
      return 'Login dibatalkan';
    } else {
      return 'Error: $errStr';
    }
  }

  // ─── Step 4: Ensure authenticated (lazy auth for operations) ────

  /// Make sure we have a live session. Used before backup/restore.
  /// Tries silent restore first, then full auth if needed.
  /// Returns error message on failure, null on success.
  static Future<String?> ensureAuthenticated() async {
    if (_currentUser != null) return null; // already have session

    // Try silent first
    final silentOk = await restoreSessionSilently();
    if (silentOk) return null;

    // Need full interactive auth
    return await signIn();
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _currentUser = null;
    _cachedEmail = null;
    _lastError = null;
    // Clear persisted state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSignedIn, false);
    await prefs.remove(_prefUserEmail);
    await prefs.remove(_prefSchedule);
    await prefs.remove(_prefLastAutoBackup);
  }

  // ─── Backup Schedule ────────────────────────────────────────

  /// Get current backup schedule
  static Future<BackupSchedule> getBackupSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_prefSchedule) ?? 0;
    return BackupSchedule.values[idx.clamp(
      0,
      BackupSchedule.values.length - 1,
    )];
  }

  /// Set backup schedule
  static Future<void> setBackupSchedule(BackupSchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefSchedule, schedule.index);
  }

  /// Get last auto-backup timestamp
  static Future<DateTime?> getLastAutoBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_prefLastAutoBackup);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Run auto-backup if schedule is due. Call on app startup.
  static Future<void> runScheduledBackupIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final wasSigned = prefs.getBool(_prefSignedIn) ?? false;
    if (!wasSigned) return;

    final schedule = await getBackupSchedule();
    if (schedule == BackupSchedule.none) return;

    final lastAuto = await getLastAutoBackupTime();
    final now = DateTime.now();

    bool shouldBackup = false;
    if (lastAuto == null) {
      shouldBackup = true;
    } else {
      final diff = now.difference(lastAuto);
      if (schedule == BackupSchedule.weekly && diff.inDays >= 7) {
        shouldBackup = true;
      } else if (schedule == BackupSchedule.monthly && diff.inDays >= 30) {
        shouldBackup = true;
      }
    }

    if (shouldBackup) {
      // Try to silently restore session (no UI popup)
      final restored = await restoreSessionSilently();
      if (!restored) return;

      debugPrint('Running scheduled backup ($schedule)...');
      final result = await backup();
      if (result.success) {
        await prefs.setInt(_prefLastAutoBackup, now.millisecondsSinceEpoch);
        debugPrint('Scheduled backup completed successfully.');
      } else {
        debugPrint('Scheduled backup failed: ${result.message}');
      }
    }
  }

  /// Get auth headers — handles token refresh automatically.
  /// Uses ensureAuthenticated() for lazy session restore.
  static Future<Map<String, String>?> _getAuthHeaders() async {
    // Ensure we have a live session (silent → interactive if needed)
    final error = await ensureAuthenticated();
    if (error != null) return null;

    try {
      // authorizationHeaders handles refresh tokens internally.
      // promptIfNecessary: true lets it re-prompt if token expired.
      final headers = await _currentUser!.authorizationClient
          .authorizationHeaders(_scopes, promptIfNecessary: true);
      return headers;
    } catch (e) {
      debugPrint('Auth headers error: $e');
      _lastError = 'Gagal mendapatkan token akses: $e';
      // Session might be stale — clear so next call retries
      _currentUser = null;
      return null;
    }
  }

  /// Find or create the MyDuit backup folder
  static Future<String?> _getOrCreateFolder(Map<String, String> headers) async {
    final searchUrl = Uri.parse(
      'https://www.googleapis.com/drive/v3/files'
      '?q=name%3D%27$_folderName%27%20and%20mimeType%3D%27application/vnd.google-apps.folder%27%20and%20trashed%3Dfalse'
      '&fields=files(id,name)',
    );
    final searchResp = await http.get(searchUrl, headers: headers);

    if (searchResp.statusCode == 200) {
      final data = jsonDecode(searchResp.body);
      final files = data['files'] as List;
      if (files.isNotEmpty) {
        return files.first['id'] as String;
      }
    }

    final createUrl = Uri.parse('https://www.googleapis.com/drive/v3/files');
    final createResp = await http.post(
      createUrl,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _folderName,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );

    if (createResp.statusCode == 200) {
      return jsonDecode(createResp.body)['id'] as String;
    }
    return null;
  }

  /// Backup database to Google Drive
  static Future<BackupResult> backup() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) {
        return BackupResult(
          success: false,
          message: _lastError ?? 'Gagal login Google',
        );
      }

      final dbPath = join(await getDatabasesPath(), 'myduit.db');
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        return BackupResult(
          success: false,
          message: 'Database tidak ditemukan',
        );
      }

      final folderId = await _getOrCreateFolder(headers);
      if (folderId == null) {
        return BackupResult(
          success: false,
          message: 'Gagal membuat folder di Drive',
        );
      }

      final existingId = await _findExistingBackup(headers, folderId);
      final dbBytes = await dbFile.readAsBytes();
      final now = DateTime.now();

      if (existingId != null) {
        final updateUrl = Uri.parse(
          'https://www.googleapis.com/upload/drive/v3/files/$existingId'
          '?uploadType=media',
        );
        final resp = await http.patch(
          updateUrl,
          headers: {...headers, 'Content-Type': 'application/octet-stream'},
          body: dbBytes,
        );
        if (resp.statusCode != 200) {
          return BackupResult(
            success: false,
            message: 'Gagal memperbarui backup: ${resp.statusCode}',
          );
        }
      } else {
        final metadata = jsonEncode({
          'name': _backupFileName,
          'parents': [folderId],
          'description': 'MyDuit backup ${now.toIso8601String()}',
        });

        final boundary = '===myduit_boundary===';
        final body =
            '--$boundary\r\n'
            'Content-Type: application/json; charset=UTF-8\r\n\r\n'
            '$metadata\r\n'
            '--$boundary\r\n'
            'Content-Type: application/octet-stream\r\n\r\n';
        final bodyEnd = '\r\n--$boundary--';

        final request = http.Request(
          'POST',
          Uri.parse(
            'https://www.googleapis.com/upload/drive/v3/files'
            '?uploadType=multipart',
          ),
        );
        request.headers.addAll(headers);
        request.headers['Content-Type'] =
            'multipart/related; boundary=$boundary';
        request.bodyBytes = [
          ...utf8.encode(body),
          ...dbBytes,
          ...utf8.encode(bodyEnd),
        ];

        final resp = await request.send();
        if (resp.statusCode != 200) {
          return BackupResult(
            success: false,
            message: 'Gagal upload backup: ${resp.statusCode}',
          );
        }
      }

      return BackupResult(
        success: true,
        message: 'Backup berhasil pada ${_formatTime(now)}',
        timestamp: now,
      );
    } catch (e) {
      return BackupResult(success: false, message: 'Error: $e');
    }
  }

  /// Restore database from Google Drive
  static Future<BackupResult> restore() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) {
        return BackupResult(
          success: false,
          message: _lastError ?? 'Gagal login Google',
        );
      }

      final folderId = await _getOrCreateFolder(headers);
      if (folderId == null) {
        return BackupResult(
          success: false,
          message: 'Folder backup tidak ditemukan',
        );
      }

      final fileId = await _findExistingBackup(headers, folderId);
      if (fileId == null) {
        return BackupResult(
          success: false,
          message: 'Tidak ada file backup di Google Drive',
        );
      }

      final downloadUrl = Uri.parse(
        'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
      );
      final resp = await http.get(downloadUrl, headers: headers);

      if (resp.statusCode != 200) {
        return BackupResult(
          success: false,
          message: 'Gagal download backup: ${resp.statusCode}',
        );
      }

      final dbPath = join(await getDatabasesPath(), 'myduit.db');
      final dbFile = File(dbPath);
      await dbFile.writeAsBytes(resp.bodyBytes);

      return BackupResult(
        success: true,
        message: 'Restore berhasil! Restart aplikasi untuk menerapkan.',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return BackupResult(success: false, message: 'Error: $e');
    }
  }

  static Future<String?> _findExistingBackup(
    Map<String, String> headers,
    String folderId,
  ) async {
    final url = Uri.parse(
      'https://www.googleapis.com/drive/v3/files'
      '?q=name%3D%27$_backupFileName%27%20and%20%27$folderId%27%20in%20parents%20and%20trashed%3Dfalse'
      '&fields=files(id,name,modifiedTime)',
    );
    final resp = await http.get(url, headers: headers);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final files = data['files'] as List;
      if (files.isNotEmpty) {
        return files.first['id'] as String;
      }
    }
    return null;
  }

  static Future<DateTime?> getLastBackupTime() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) return null;

      final folderId = await _getOrCreateFolder(headers);
      if (folderId == null) return null;

      final url = Uri.parse(
        'https://www.googleapis.com/drive/v3/files'
        '?q=name%3D%27$_backupFileName%27%20and%20%27$folderId%27%20in%20parents%20and%20trashed%3Dfalse'
        '&fields=files(id,modifiedTime)',
      );
      final resp = await http.get(url, headers: headers);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final files = data['files'] as List;
        if (files.isNotEmpty) {
          return DateTime.parse(files.first['modifiedTime'] as String);
        }
      }
    } catch (_) {}
    return null;
  }

  static String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class BackupResult {
  final bool success;
  final String message;
  final DateTime? timestamp;

  BackupResult({required this.success, required this.message, this.timestamp});
}
