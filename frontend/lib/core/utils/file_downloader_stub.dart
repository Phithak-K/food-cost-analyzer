import 'dart:typed_data';

/// Stub implementation for non-web environments (unit tests, CLI)
void downloadFileFromBytes(Uint8List bytes, String filename, String mimeType) {
  // No-op in test/CLI environments
}

/// Stub implementation for non-web environments (unit tests, CLI)
void downloadFileFromString(String content, String filename, String mimeType) {
  // No-op in test/CLI environments
}
