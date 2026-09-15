import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_aiei_lms/presentation/screens/login/login_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/enrolled_courses_catalogue_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/my_assigned_courses_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/admin_portal/manage_lecturers_screen.dart';

void main() {
  group('LoginScreen renders without overflow', () {
    testWidgets('desktop width', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LoginScreen())));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
        expect(find.text('Sign in to your account'), findsOneWidget);
      }, createHttpClient: (context) => _FakeHttpClient());
    });

    testWidgets('mobile width', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LoginScreen())));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -800));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }, createHttpClient: (context) => _FakeHttpClient());
    });

    testWidgets('role tabs and Sign In navigate to the matching portal', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LoginScreen())));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Default role is Student — Sign In should open the student portal.
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();
        expect(find.byType(EnrolledCoursesCatalogueScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, createHttpClient: (context) => _FakeHttpClient());
    });

    testWidgets('faculty profile avatar returns to Login', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: MyAssignedCoursesScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.text('Dr. Sarah Lin'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, createHttpClient: (context) => _FakeHttpClient());
    });

    testWidgets('admin profile avatar returns to Login', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: ManageLecturersScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.text('Marcus Vance'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, createHttpClient: (context) => _FakeHttpClient());
    });
  });
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(
      Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}
  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _FakeHttpClientRequest();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final List<int> _bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );

  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => _bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
