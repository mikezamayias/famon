import 'dart:io';

import 'package:famon/src/platform/clipboard_interface.dart';
import 'package:injectable/injectable.dart';
import 'package:process/process.dart';

/// Cross-platform clipboard service implementation.
///
/// Uses platform-specific command-line tools for clipboard access:
/// - macOS: `pbcopy` / `pbpaste`
/// - Linux: `xclip` (requires xclip to be installed)
/// - Windows: `clip.exe` / PowerShell `Get-Clipboard`
@injectable
class ClipboardService implements ClipboardInterface {
  /// Creates a new clipboard service.
  ClipboardService({ProcessManager? processManager})
      : _processManager = processManager ?? const LocalProcessManager();

  final ProcessManager _processManager;

  @override
  bool get isSupported =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  @override
  Future<bool> copy(String text) async {
    try {
      if (Platform.isMacOS) {
        return _copyMacOS(text);
      } else if (Platform.isLinux) {
        return _copyLinux(text);
      } else if (Platform.isWindows) {
        return _copyWindows(text);
      }
      return false;
    } on Exception catch (_) {
      return false;
    }
  }

  @override
  Future<String?> paste() async {
    try {
      if (Platform.isMacOS) {
        return _pasteMacOS();
      } else if (Platform.isLinux) {
        return _pasteLinux();
      } else if (Platform.isWindows) {
        return _pasteWindows();
      }
      return null;
    } on Exception catch (_) {
      return null;
    }
  }

  /// Copy to clipboard on macOS using pbcopy.
  Future<bool> _copyMacOS(String text) async {
    final process = await _processManager.start(['pbcopy']);
    process.stdin.write(text);
    await process.stdin.close();
    final exitCode = await process.exitCode;
    return exitCode == 0;
  }

  /// Paste from clipboard on macOS using pbpaste.
  Future<String?> _pasteMacOS() async {
    final result = await _processManager.run(['pbpaste']);
    if (result.exitCode == 0) {
      return result.stdout as String;
    }
    return null;
  }

  /// Copy to clipboard on Linux using xclip.
  Future<bool> _copyLinux(String text) async {
    final process = await _processManager.start([
      'xclip',
      '-selection',
      'clipboard',
    ]);
    process.stdin.write(text);
    await process.stdin.close();
    final exitCode = await process.exitCode;
    return exitCode == 0;
  }

  /// Paste from clipboard on Linux using xclip.
  Future<String?> _pasteLinux() async {
    final result = await _processManager.run([
      'xclip',
      '-selection',
      'clipboard',
      '-o',
    ]);
    if (result.exitCode == 0) {
      return result.stdout as String;
    }
    return null;
  }

  /// Copy to clipboard on Windows using clip.exe.
  ///
  /// Uses stdin to pass text to avoid command injection vulnerabilities.
  Future<bool> _copyWindows(String text) async {
    // Use PowerShell with stdin input to avoid command injection
    // The -Command parameter reads from stdin with $input
    final process = await _processManager.start(
      [
        'powershell',
        '-command',
        r'$input | Set-Clipboard',
      ],
      runInShell: true,
    );
    process.stdin.write(text);
    await process.stdin.close();
    final exitCode = await process.exitCode;
    return exitCode == 0;
  }

  /// Paste from clipboard on Windows using PowerShell.
  Future<String?> _pasteWindows() async {
    final result = await _processManager.run(
      [
        'powershell',
        '-command',
        'Get-Clipboard',
      ],
      runInShell: true,
    );
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
    return null;
  }
}
