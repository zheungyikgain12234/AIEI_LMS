import 'dart:typed_data';

bool get supportsBrowserDownload => false;

void downloadBytes(String fileName, Uint8List bytes, {String mimeType = 'text/csv'}) {
  throw UnsupportedError('Browser download is only available on web.');
}
