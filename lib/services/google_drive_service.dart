import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_service.dart';

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

  /// Parse HTTP response status code into user-friendly error messages
  static String _parseHttpError(http.Response resp, {String? defaultMsg}) {
    final code = resp.statusCode;
    if (code == 401) {
      return 'Sesi Google Drive kedaluwarsa. Silakan masuk ulang.';
    } else if (code == 403) {
      return 'Penyimpanan Google Drive penuh atau izin akses ditolak.';
    } else if (code == 404) {
      return 'Berkas cadangan tidak ditemukan di Google Drive.';
    } else if (code == 429) {
      return 'Terlalu banyak permintaan ke Google Drive. Coba sesaat lagi.';
    } else if (code >= 500) {
      return 'Layanan Google Drive sedang mengalami gangguan sementara.';
    }
    return defaultMsg ?? 'Gagal menghubungi Google Drive ($code).';
  }

  /// Find or create the MyDuit backup folder
  static Future<String?> _getOrCreateFolder(Map<String, String> headers) async {
    try {
      final searchUrl = Uri.parse(
        'https://www.googleapis.com/drive/v3/files'
        '?q=name%3D%27$_folderName%27%20and%20mimeType%3D%27application/vnd.google-apps.folder%27%20and%20trashed%3Dfalse'
        '&fields=files(id,name)',
      );
      final searchResp = await http
          .get(searchUrl, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (searchResp.statusCode == 200) {
        final data = jsonDecode(searchResp.body);
        final files = data['files'] as List;
        if (files.isNotEmpty) {
          return files.first['id'] as String;
        }
      } else {
        _lastError = _parseHttpError(searchResp);
        return null;
      }

      final createUrl = Uri.parse('https://www.googleapis.com/drive/v3/files');
      final createResp = await http
          .post(
            createUrl,
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': _folderName,
              'mimeType': 'application/vnd.google-apps.folder',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (createResp.statusCode == 200) {
        return jsonDecode(createResp.body)['id'] as String;
      }
      _lastError = _parseHttpError(
        createResp,
        defaultMsg: 'Gagal membuat folder di Google Drive (${createResp.statusCode})',
      );
      return null;
    } catch (e) {
      _lastError = 'Koneksi ke Google Drive gagal: $e';
      return null;
    }
  }

  /// Backup database to Google Drive (with optional snapshot versioning)
  static Future<BackupResult> backup({bool createSnapshot = false}) async {
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

      // Checkpoint WAL before backing up
      await DatabaseService().checkpointWal();

      final folderId = await _getOrCreateFolder(headers);
      if (folderId == null) {
        return BackupResult(
          success: false,
          message: _lastError ?? 'Gagal membuat folder di Drive',
        );
      }

      final now = DateTime.now();
      final targetFileName = createSnapshot
          ? 'myduit_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.db'
          : _backupFileName;

      final existingId = createSnapshot ? null : await _findExistingBackup(headers, folderId);
      final dbBytes = await dbFile.readAsBytes();

      if (existingId != null) {
        final updateUrl = Uri.parse(
          'https://www.googleapis.com/upload/drive/v3/files/$existingId'
          '?uploadType=media',
        );
        final resp = await http
            .patch(
              updateUrl,
              headers: {...headers, 'Content-Type': 'application/octet-stream'},
              body: dbBytes,
            )
            .timeout(const Duration(seconds: 45));
        if (resp.statusCode != 200) {
          return BackupResult(
            success: false,
            message: _parseHttpError(resp, defaultMsg: 'Gagal memperbarui backup: ${resp.statusCode}'),
          );
        }
      } else {
        final metadata = jsonEncode({
          'name': targetFileName,
          'parents': [folderId],
          'description': 'MyDuit backup ${_formatTime(now)}',
        });

        final boundary = 'myduit_boundary_${now.millisecondsSinceEpoch}';
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

        final streamResp = await request.send();
        final resp = await http.Response.fromStream(streamResp);
        if (resp.statusCode != 200) {
          return BackupResult(
            success: false,
            message: _parseHttpError(resp, defaultMsg: 'Gagal upload backup: ${resp.statusCode}'),
          );
        }
      }

      // Keep max 5 snapshots
      await _pruneOldSnapshots(headers, folderId);

      return BackupResult(
        success: true,
        message: 'Backup berhasil pada ${_formatTime(now)}',
        timestamp: now,
      );
    } catch (e) {
      return BackupResult(success: false, message: 'Error: $e');
    }
  }

  /// Restore database from Google Drive with pre-restore safety snapshot and rollback protection
  static Future<BackupResult> restore({String? fileId}) async {
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
          message: _lastError ?? 'Folder backup tidak ditemukan',
        );
      }

      final targetFileId = fileId ?? await _findExistingBackup(headers, folderId);
      if (targetFileId == null) {
        return BackupResult(
          success: false,
          message: 'Tidak ada file backup di Google Drive',
        );
      }

      final downloadUrl = Uri.parse(
        'https://www.googleapis.com/drive/v3/files/$targetFileId?alt=media',
      );
      final resp = await http
          .get(downloadUrl, headers: headers)
          .timeout(const Duration(seconds: 45));

      if (resp.statusCode != 200) {
        return BackupResult(
          success: false,
          message: _parseHttpError(resp, defaultMsg: 'Gagal download backup: ${resp.statusCode}'),
        );
      }

      // Close active database handle before touching files
      await DatabaseService().closeDatabase();

      final dbPath = join(await getDatabasesPath(), 'myduit.db');
      final dbFile = File(dbPath);
      final snapshotFile = File('$dbPath.safety_snapshot');
      final walFile = File('$dbPath-wal');
      final shmFile = File('$dbPath-shm');

      // Create pre-restore safety snapshot
      if (await dbFile.exists()) {
        try {
          await dbFile.copy(snapshotFile.path);
        } catch (_) {}
      }

      // Remove leftover WAL/SHM files to prevent SQLite log corruption
      if (await walFile.exists()) {
        try {
          await walFile.delete();
        } catch (_) {}
      }
      if (await shmFile.exists()) {
        try {
          await shmFile.delete();
        } catch (_) {}
      }

      await dbFile.writeAsBytes(resp.bodyBytes);

      // Verify SQLite database integrity
      final isHealthy = await DatabaseService().integrityCheck();
      if (!isHealthy) {
        // Rollback to safety snapshot
        await DatabaseService().closeDatabase();
        if (await snapshotFile.exists()) {
          await snapshotFile.copy(dbFile.path);
          try {
            await snapshotFile.delete();
          } catch (_) {}
        }
        await DatabaseService().database;
        return BackupResult(
          success: false,
          message: 'File cadangan korup atau tidak valid. Database telah di-rollback secara aman.',
        );
      }

      // Success: clean up snapshot file
      if (await snapshotFile.exists()) {
        try {
          await snapshotFile.delete();
        } catch (_) {}
      }

      return BackupResult(
        success: true,
        message: 'Restore berhasil! Integritas database telah diverifikasi.',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return BackupResult(success: false, message: 'Error: $e');
    }
  }

  /// List all snapshots in Google Drive folder
  static Future<List<DriveBackupInfo>> getBackupList() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) return [];

      final folderId = await _getOrCreateFolder(headers);
      if (folderId == null) return [];

      final url = Uri.parse(
        'https://www.googleapis.com/drive/v3/files'
        "?q='$folderId'+in+parents+and+trashed=false+and+(name='$_backupFileName'+or+name+contains+'myduit_backup')"
        '&fields=files(id,name,modifiedTime,size,description)'
        '&orderBy=modifiedTime+desc',
      );
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final files = data['files'] as List;
        return files.map((f) {
          return DriveBackupInfo(
            fileId: f['id'] as String,
            fileName: f['name'] as String? ?? _backupFileName,
            modifiedTime: DateTime.tryParse(f['modifiedTime'] as String? ?? '') ?? DateTime.now(),
            sizeBytes: int.tryParse(f['size']?.toString() ?? '0') ?? 0,
            description: f['description'] as String?,
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Prune old backup snapshots, retaining max 5
  static Future<void> _pruneOldSnapshots(
    Map<String, String> headers,
    String folderId,
  ) async {
    try {
      final list = await getBackupList();
      if (list.length > 5) {
        for (int i = 5; i < list.length; i++) {
          final id = list[i].fileId;
          final delUrl = Uri.parse('https://www.googleapis.com/drive/v3/files/$id');
          await http.delete(delUrl, headers: headers);
        }
      }
    } catch (_) {}
  }

  static Future<String?> _findExistingBackup(
    Map<String, String> headers,
    String folderId,
  ) async {
    final url = Uri.parse(
      'https://www.googleapis.com/drive/v3/files'
      '?q=name%3D%27$_backupFileName%27%20and%20%27$folderId%27%20in%20parents%20and%20trashed%3Dfalse'
      '&fields=files(id,name,modifiedTime,size)',
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

  static Future<DriveBackupInfo?> getBackupInfo() async {
    final list = await getBackupList();
    if (list.isNotEmpty) return list.first;
    return null;
  }

  static Future<DateTime?> getLastBackupTime() async {
    final info = await getBackupInfo();
    return info?.modifiedTime;
  }

  static String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class DriveBackupInfo {
  final String fileId;
  final String fileName;
  final DateTime modifiedTime;
  final int sizeBytes;
  final String? description;

  DriveBackupInfo({
    required this.fileId,
    this.fileName = 'myduit_backup.db',
    required this.modifiedTime,
    required this.sizeBytes,
    this.description,
  });

  String get formattedSize {
    if (sizeBytes <= 0) return '0 B';
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class BackupResult {
  final bool success;
  final String message;
  final DateTime? timestamp;

  BackupResult({required this.success, required this.message, this.timestamp});
}
