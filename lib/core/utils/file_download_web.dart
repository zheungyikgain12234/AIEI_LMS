import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

bool get supportsBrowserDownload => true;

void downloadBytes(String fileName, Uint8List bytes, {String mimeType = 'text/csv'}) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  web.document.body?.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}
