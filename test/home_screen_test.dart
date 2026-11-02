
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:srs8/data/local/post_cache.dart';
import 'package:srs8/data/models/post.dart';
import 'package:srs8/data/repositories/post_repository.dart';
import 'package:srs8/presentation/screens/home_screen.dart';

class MockPostRepository extends Mock implements PostRepository {}

class MockPostCache extends Mock implements PostCache {}

void main() {
  late MockPostRepository repository;
  late MockPostCache cache;

  const testPosts = [
    Post(
      userId: 1,
      id: 1,
      title: 'Flutter basics',
      body: 'Learn the basics of Flutter.',
    ),
    Post(
      userId: 2,
      id: 2,
      title: 'Dart language',
      body: 'Learn the Dart language.',
    ),
  ];

  setUp(() {
    repository = MockPostRepository();
    cache = MockPostCache();

    when(() => cache.getPosts()).thenReturn([]);

    when(
      () => repository.getPosts(
        page: 1,
        limit: 10,
        userId: null,
      ),
    ).thenAnswer((_) async => testPosts);

    when(() => repository.getUsers())
        .thenAnswer((_) async => []);
  });

  Future<void> openHomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          cache: cache,
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('1. Home screen displays title and posts',
      (tester) async {
    await openHomeScreen(tester);

    expect(find.text('Post Explorer'), findsOneWidget);
    expect(find.text('Flutter basics'), findsOneWidget);
    expect(find.text('Dart language'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('2. Search filters posts by title',
      (tester) async {
    await openHomeScreen(tester);

    await tester.enterText(
      find.byType(TextField),
      'Flutter',
    );

    await tester.pumpAndSettle();

    expect(find.text('Flutter basics'), findsOneWidget);
    expect(find.text('Dart language'), findsNothing);
  });

  testWidgets('3. Tapping a post opens its details screen',
      (tester) async {
    when(() => repository.getPostById(1))
        .thenAnswer((_) async => testPosts[0]);

    when(() => repository.getComments(1))
        .thenAnswer((_) async => []);

    await openHomeScreen(tester);

    await tester.tap(find.text('Flutter basics'));
    await tester.pumpAndSettle();

    expect(find.text('Post Details'), findsOneWidget);
    expect(find.text('Flutter basics'), findsOneWidget);
  });
}
