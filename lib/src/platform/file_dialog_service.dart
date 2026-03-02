import 'dart:io';

import 'package:famon/src/platform/file_dialog_interface.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:process/process.dart';

/// Cross-platform file dialog service implementation.
///
/// Uses platform-specific tools for file save dialogs:
/// - macOS: AppleScript via `osascript`
/// - Linux: `zenity` (requires zenity to be installed)
/// - Windows: PowerShell with Windows Forms
///
/// Falls back to terminal prompt if native dialogs are unavailable.
@injectable
class FileDialogService implements FileDialogInterface {
  /// Creates a new file dialog service.
  FileDialogService({ProcessManager? processManager, Logger? logger})
      : _processManager = processManager ?? const LocalProcessManager(),
        _logger = logger;

  final ProcessManager _processManager;
  final Logger? _logger;

  @override
  bool get isSupported =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  @override
  Future<String?> showSaveDialog({
    String? defaultFileName,
    String? initialDirectory,
  }) async {
    try {
      if (Platform.isMacOS) {
        return _showMacOSDialog(defaultFileName, initialDirectory);
      } else if (Platform.isLinux) {
        return _showLinuxDialog(defaultFileName, initialDirectory);
      } else if (Platform.isWindows) {
        return _showWindowsDialog(defaultFileName, initialDirectory);
      }
      // Fallback to terminal prompt
      return promptForPath(defaultFileName: defaultFileName);
    } on Exception catch (_) {
      // Fallback to terminal prompt
      return promptForPath(defaultFileName: defaultFileName);
    }
  }

  @override
  Future<String?> promptForPath({String? defaultFileName}) async {
    final fileName = defaultFileName ?? _generateDefaultFileName();
    _logger?.prompt('Enter file path [$fileName]: ');

    final input = stdin.readLineSync();
    if (input == null || input.isEmpty) {
      return fileName;
    }
    return input;
  }

  /// Generate a default file name with timestamp.
  String _generateDefaultFileName() {
    final now = DateTime.now();
    final date = '${now.year}${_pad(now.month)}${_pad(now.day)}';
    final time = '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    return 'famon_export_${date}_$time.json';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  /// Show file dialog on macOS using AppleScript.
  ///
  /// Escapes special characters in the filename to prevent AppleScript
  /// injection attacks.
  Future<String?> _showMacOSDialog(String? fileName, String? initialDir) async {
    final defaultName = fileName ?? _generateDefaultFileName();

    // Escape special characters to prevent AppleScript injection
    // AppleScript strings use backslash escaping for quotes and backslashes
    final escapedName =
        defaultName.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

    // Build AppleScript command
    final script = '''
      tell application "System Events"
        activate
        set filePath to choose file name default name "$escapedName"
        return POSIX path of filePath
      end tell
    ''';

    final result = await _processManager.run(['osascript', '-e', script]);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
    return null;
  }

  /// Show file dialog on Linux using zenity.
  Future<String?> _showLinuxDialog(String? fileName, String? initialDir) async {
    final defaultName = fileName ?? _generateDefaultFileName();
    final args = [
      '--file-selection',
      '--save',
      '--confirm-overwrite',
      '--filename=$defaultName',
    ];

    final result = await _processManager.run(['zenity', ...args]);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
    return null;
  }

  /// Show file dialog on Windows using PowerShell.
  Future<String?> _showWindowsDialog(
    String? fileName,
    String? initialDir,
  ) async {
    final defaultName = fileName ?? _generateDefaultFileName();

    // PowerShell script for save file dialog
    final script = '''
      Add-Type -AssemblyName System.Windows.Forms
      \$dialog = New-Object System.Windows.Forms.SaveFileDialog
      \$dialog.Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"
      \$dialog.FileName = "$defaultName"
      \$dialog.Title = "Save Firebase Analytics Events"
      if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Write-Output \$dialog.FileName
      }
    ''';

    final result = await _processManager.run(
      [
        'powershell',
        '-command',
        script,
      ],
      runInShell: true,
    );

    if (result.exitCode == 0) {
      final output = (result.stdout as String).trim();
      if (output.isNotEmpty) {
        return output;
      }
    }
    return null;
  }
}
