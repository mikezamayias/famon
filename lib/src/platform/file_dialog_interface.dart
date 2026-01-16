/// Interface for file save dialog operations.
///
/// Implementations provide cross-platform file save dialogs for selecting
/// a file path to save content to.
abstract class FileDialogInterface {
  /// Show a save file dialog.
  ///
  /// [defaultFileName] - Suggested file name.
  /// [initialDirectory] - Starting directory for the dialog.
  ///
  /// Returns the selected file path, or null if the dialog was cancelled.
  Future<String?> showSaveDialog({
    String? defaultFileName,
    String? initialDirectory,
  });

  /// Whether file dialogs are supported on this platform.
  bool get isSupported;

  /// Prompt for a file path in the terminal as a fallback.
  ///
  /// [defaultFileName] - Default file name to suggest.
  ///
  /// Returns the entered file path, or null if empty.
  Future<String?> promptForPath({String? defaultFileName});
}
