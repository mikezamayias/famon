/// Interface for clipboard operations.
///
/// Implementations provide cross-platform clipboard access for copying
/// text content.
abstract class ClipboardInterface {
  /// Copy text to the system clipboard.
  ///
  /// [text] - The text content to copy.
  ///
  /// Returns true if the copy operation succeeded.
  Future<bool> copy(String text);

  /// Read text from the system clipboard.
  ///
  /// Returns the clipboard content, or null if the clipboard is empty
  /// or the operation failed.
  Future<String?> paste();

  /// Whether clipboard operations are supported on this platform.
  bool get isSupported;
}
