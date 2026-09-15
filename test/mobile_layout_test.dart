import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/data/datasources/mock_courses_data_source.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/enrolled_courses_catalogue_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/course_info/course_info_screen.dart';

void main() {
  group('Mobile (< 700px) layouts render without overflow', () {
    testWidgets('EnrolledCoursesCatalogueScreen mobile layout',
        (WidgetTester tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: EnrolledCoursesCatalogueScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
        expect(find.text('STUDENT'), findsOneWidget);
        expect(find.text('My Enrolled Courses'), findsOneWidget);
        expect(find.text('ACTIVE TERM'), findsOneWidget);
        expect(find.text('My Courses'), findsOneWidget);
        expect(find.text('Certifications & Badges'), findsOneWidget);

        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }, createHttpClient: (context) => _FakeHttpClient());
    });

    testWidgets('CourseInfoScreen mobile layout', (WidgetTester tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final course = MockCoursesDataSource.courses.firstWhere((c) => c.id == 'c1-python');

        await tester.pumpWidget(
          MaterialApp(home: CourseInfoScreen(course: course)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
        expect(find.text('Course Details'), findsOneWidget);
        expect(find.text('Back to Courses'), findsOneWidget);
        expect(find.textContaining('Curriculum Syllabus'), findsOneWidget);

        await tester.ensureVisible(find.text('External Links & Repos'));
        await tester.pump();
        await tester.tap(find.text('External Links & Repos'), warnIfMissed: false);
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Ask a Question'));
        await tester.pump();
        await tester.tap(find.text('Ask a Question'), warnIfMissed: false);
        await tester.pump();
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
