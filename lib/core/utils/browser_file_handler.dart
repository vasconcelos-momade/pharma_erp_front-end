import 'dart:typed_data';

import 'browser_file_handler_stub.dart'
    if (dart.library.io) 'browser_file_handler_io.dart'
    if (dart.library.html) 'browser_file_handler_web.dart' as impl;

abstract final class BrowserFileHandler {
  BrowserFileHandler._();

  static Future<void> openBytes({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) {
    return impl.openBytesImpl(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  static Future<void> downloadBytes({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) {
    return impl.downloadBytesImpl(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }
}
