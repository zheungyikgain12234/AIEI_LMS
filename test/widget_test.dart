import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/data/datasources/mock_courses_data_source.dart';
import 'package:stitch_aiei_lms/data/repositories/mock_courses_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/enrolled_courses_catalogue_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/controllers/courses_controller.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/controllers/courses_state.dart';

class _TestCoursesNotifier extends CoursesNotifier {
  @override
  CoursesState build() {
    return const CoursesState(
      allCourses: MockCoursesDataSource.courses,
      stats: MockCoursesDataSource.stats,
      urgentNotice: MockCoursesDataSource.urgentNotice,
      isLoading: false,
    );
  }
}

void main() {
  group('MockCoursesRepository Tests', () {
    final repository = MockCoursesRepositoryImpl();

    test('getEnrolledCourses returns exactly 6 courses', () async {
      final courses = await repository.getEnrolledCourses();
      expect(courses.length, 6);
    });

    test('getCourseStats returns valid telemetry data', () async {
      final stats = await repository.getCourseStats();
      expect(stats.enrolledCourses, 6);
      expect(stats.inProgressCourses, 5);
      expect(stats.completedCourses, 1);
      expect(stats.completedLessons, 19);
      expect(stats.totalLessons, 52);
      expect(stats.badgesEarned, 1);
    });

    test('getUrgentNotice returns valid critical action', () async {
      final notice = await repository.getUrgentNotice();
      expect(notice, isNotNull);
      expect(notice!.title, 'Corporate Cybersecurity & Phishing Defense');
      expect(notice.progressPercentage, 85);
    });
  });

  group('CoursesState Filtering and Sorting Tests', () {
    test('Filter by category returns matching courses', () async {
      final repository = MockCoursesRepositoryImpl();
      final courses = await repository.getEnrolledCourses();

      final stateAll = CoursesState(
        allCourses: courses,
        selectedCategory: CourseCategory.all,
      );
      expect(stateAll.filteredAndSortedCourses.length, 6);

      final stateCompliance = CoursesState(
        allCourses: courses,
        selectedCategory: CourseCategory.compliance,
      );
      expect(stateCompliance.filteredAndSortedCourses.length, 2);

      final stateTech = CoursesState(
        allCourses: courses,
        selectedCategory: CourseCategory.techData,
      );
      expect(stateTech.filteredAndSortedCourses.length, 2);

      final stateAi = CoursesState(
        allCourses: courses,
        selectedCategory: CourseCategory.aiTools,
      );
      expect(stateAi.filteredAndSortedCourses.length, 1);

      final stateProductivity = CoursesState(
        allCourses: courses,
        selectedCategory: CourseCategory.productivity,
      );
      expect(stateProductivity.filteredAndSortedCourses.length, 1);
    });

    test('Search query filters courses by title', () async {
      final repository = MockCoursesRepositoryImpl();
      final courses = await repository.getEnrolledCourses();

      final state = CoursesState(
        allCourses: courses,
        searchQuery: 'python',
      );
      expect(state.filteredAndSortedCourses.length, 1);
      expect(state.filteredAndSortedCourses.first.id, 'c1-python');
    });

    test('Sort by progressDesc orders highest progress first', () async {
      final repository = MockCoursesRepositoryImpl();
      final courses = await repository.getEnrolledCourses();

      final state = CoursesState(
        allCourses: courses,
        sortOption: CourseSortOption.progressDesc,
      );
      final sorted = state.filteredAndSortedCourses;
      expect(sorted.first.progressPercentage, 100);
      expect(sorted.last.progressPercentage, 20);
    });
  });

  group('Widget Smoke Test', () {
    testWidgets('App renders EnrolledCoursesCatalogueScreen without crashing',
        (WidgetTester tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coursesRepositoryProvider.overrideWithValue(MockCoursesRepositoryImpl()),
            ],
            child: const MaterialApp(home: EnrolledCoursesCatalogueScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('STUDENT PORTAL'), findsOneWidget);
        expect(find.text('Alex Chen'), findsOneWidget);
        expect(find.text('Product Analyst • Operations'), findsOneWidget);
        expect(find.text('My Enrolled Courses'), findsWidgets);
        expect(find.text('Q4 Performance Milestone'), findsOneWidget);
        expect(find.text('Enterprise ID: SKL-8842-AC'), findsOneWidget);
        expect(find.text('CRITICAL ACTION'), findsOneWidget);
        expect(find.text('Credential Vault'), findsOneWidget);

        // Scroll down to reveal filters and course cards
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -600),
        );
        await tester.pump();

        expect(find.text('All Courses'), findsOneWidget);
        expect(find.text('Compliance'), findsOneWidget);
        expect(find.text('Technical & Data'), findsOneWidget);
        expect(find.textContaining('Python for Enterprise'), findsOneWidget);
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
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm,
      HttpClientCredentials credentials) {}
  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(
      Future<bool> Function(String host, int port, String scheme, String? realm)?
          f) {}
  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest();
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

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
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
