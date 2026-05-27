import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:web/web.dart' as web;

Future<void> openBytesImpl({
  required Uint8List bytes,
  required String fileName,
  required String contentType,
}) async {
  final url = _createObjectUrl(bytes, contentType);
  web.window.open(url, '_blank');
  _scheduleRevoke(url);
}

Future<void> downloadBytesImpl({
  required Uint8List bytes,
  required String fileName,
  required String contentType,
}) async {
  final url = _createObjectUrl(bytes, contentType);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();

  _scheduleRevoke(url);
}

String _createObjectUrl(Uint8List bytes, String contentType) {
  final base64 = base64Encode(bytes);
  final dataUrl = 'data:$contentType;base64,$base64';
  return dataUrl;
}

void _scheduleRevoke(String url) {
  unawaited(
    Future<void>.delayed(const Duration(seconds: 30), () {
      web.URL.revokeObjectURL(url);
    }),
  );
}
