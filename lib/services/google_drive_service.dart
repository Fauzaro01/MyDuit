import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class GoogleDriveService {
  static const _scopes = ['https://www.googleapis.com/auth/drive.file'];
  static const _backupFileName = 'myduit_backup.db';
  static const _folderName = 'MyDuit Backups';

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static GoogleSignInAccount? _currentUser;
  static GoogleSignInAccount? get currentUser => _currentUser;
  static String? get userEmail => _currentUser?.email;

  /// Last error for UI display
  static String? _lastError;
  static String? get lastError => _lastError;

  /// Sign in to Google — returns error message on failure, null on success
  static Future<String?> signIn() async {
    _lastError = null;
    try {
      _currentUser = await _googleSignIn.authenticate(scopeHint: _scopes);
      if (_currentUser == null) {
        _lastError = 'Login dibatalkan atau akun tidak dipilih';
        return _lastError;
      }
      return null; // success
    } catch (e) {
      final errStr = e.toString();
      debugPrint('Google Sign-In error: $e');

      if (errStr.contains('sign_in_canceled') || errStr.contains('canceled')) {
        _lastError = 'Login dibatalkan oleh pengguna';
      } else if (errStr.contains('network_error') ||
          errStr.contains('ApiException: 7')) {
        _lastError = 'Tidak ada koneksi internet';
      } else if (errStr.contains('ApiException: 12500') ||
          errStr.contains('DEVELOPER_ERROR') ||
          errStr.contains('ApiException: 10')) {
        _lastError =
            'Google Cloud Console belum dikonfigurasi.\n\n'
            'Buka Pengaturan > Backup & Restore untuk panduan setup.';
      } else if (errStr.contains('ApiException: 12501')) {
        _lastError = 'Login dibatalkan';
      } else {
        _lastError = 'Error: $errStr';
      }
      return _lastError;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _currentUser = null;
    _lastError = null;
  }

  /// Check if already signed in (try lightweight auth)
  static Future<bool> isSignedIn() async {
    try {
      final account = await _googleSignIn.attemptLightweightAuthentication();
      if (account != null) {
        _currentUser = account;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Get auth headers
  static Future<Map<String, String>?> _getAuthHeaders() async {
    if (_currentUser == null) {
      final error = await signIn();
      if (error != null) return null;
    }
    try {
      final headers = await _currentUser!.authorizationClient
          .authorizationHeaders(_scopes, promptIfNecessary: true);
      return headers;
    } catch (e) {
      debugPrint('Auth headers error: $e');
      _lastError = 'Gagal mendapatkan token akses: $e';
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
