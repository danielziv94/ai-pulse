import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Writes timestamped log lines to device storage when logging is enabled.
///
/// Priority order for log directory:
///   1. /storage/emulated/0/DCIM/PulseLogs/   (Android ≤10 with legacy storage)
///   2. [external-app-files]/PulseLogs/       (Android 11+, no special permission needed,
///                                             visible in file manager under Android/data/)
///   3. [app-documents]/PulseLogs/            (internal storage, last resort)
class LoggerService {
  LoggerService._();
  static final LoggerService instance = LoggerService._();

  bool _enabled = false;
  IOSink? _sink;
  String? _logFilePath;

  // Prevents multiple concurrent _ensureFileOpen() calls
  Completer<void>? _openingCompleter;

  void setEnabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    if (!value) {
      _closeFile();
    }
  }

  bool get isEnabled => _enabled;

  /// Returns the path of the current log file, or null if not open.
  String? get logFilePath => _logFilePath;

  Future<void> log(String message) async {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    final line = '[$timestamp] $message';
    debugPrint(line);
    if (!_enabled) return;
    try {
      await _ensureFileOpen();
      _sink?.writeln(line);
    } catch (e) {
      debugPrint('[Logger] write error: $e');
    }
  }

  Future<void> _ensureFileOpen() async {
    if (_sink != null) return;

    // Serialise concurrent callers
    if (_openingCompleter != null) {
      await _openingCompleter!.future;
      return;
    }
    _openingCompleter = Completer<void>();

    try {
      final file = await _resolveLogFile();
      if (file != null) {
        _logFilePath = file.path;
        _sink = file.openWrite(mode: FileMode.append);
        debugPrint('[Logger] Log file: ${file.path}');
      } else {
        debugPrint('[Logger] Could not create log file on any storage path');
      }
      _openingCompleter!.complete();
    } catch (e) {
      debugPrint('[Logger] _ensureFileOpen error: $e');
      _openingCompleter!.completeError(e);
    } finally {
      _openingCompleter = null;
    }
  }

  /// Tries each storage location in priority order and returns the first
  /// File object that was successfully created/opened.
  Future<File?> _resolveLogFile() async {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'pulse_$stamp.log';

    // 1. DCIM — works on Android ≤ 10 with requestLegacyExternalStorage
    final dcimDir = Directory('/storage/emulated/0/DCIM/PulseLogs');
    final dcimFile = await _tryCreateFile(dcimDir, fileName);
    if (dcimFile != null) return dcimFile;

    // 2. App-specific external storage — no permission needed, visible in
    //    file manager at: Android/data/com.danielziv94.ai_pulse/files/PulseLogs
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final dir = Directory('${extDir.path}/PulseLogs');
        final file = await _tryCreateFile(dir, fileName);
        if (file != null) return file;
      }
    } catch (e) {
      debugPrint('[Logger] getExternalStorageDirectory error: $e');
    }

    // 3. Internal documents directory — always works, but hidden from file managers
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/PulseLogs');
      final file = await _tryCreateFile(dir, fileName);
      if (file != null) {
        debugPrint('[Logger] WARNING: using internal storage, file not visible in file manager');
        return file;
      }
    } catch (e) {
      debugPrint('[Logger] getApplicationDocumentsDirectory error: $e');
    }

    return null;
  }

  Future<File?> _tryCreateFile(Directory dir, String fileName) async {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('${dir.path}/$fileName');
      // Touch the file to verify it can be written
      await file.writeAsString('', mode: FileMode.append, flush: false);
      return file;
    } catch (e) {
      debugPrint('[Logger] Cannot write to ${dir.path}: $e');
      return null;
    }
  }

  void _closeFile() {
    _sink?.flush();
    _sink?.close();
    _sink = null;
    _logFilePath = null;
    _openingCompleter = null;
  }

  void dispose() {
    _closeFile();
  }
}
