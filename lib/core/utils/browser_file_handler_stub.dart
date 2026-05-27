import 'dart:typed_data';

Future<void> openBytesImpl({
  required Uint8List bytes,
  required String fileName,
  required String contentType,
}) async {
  throw UnsupportedError('Abertura de ficheiros só está disponível no ambiente web.');
}

Future<void> downloadBytesImpl({
  required Uint8List bytes,
  required String fileName,
  required String contentType,
}) async {
  throw UnsupportedError('Download de ficheiros só está disponível no ambiente web.');
}
