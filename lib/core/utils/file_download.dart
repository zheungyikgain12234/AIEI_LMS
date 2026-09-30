// Saves bytes as a file: a browser download on Flutter Web, unsupported
// elsewhere (callers fall back to the native save dialog).
export 'file_download_stub.dart' if (dart.library.html) 'file_download_web.dart';
