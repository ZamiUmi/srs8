import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:srs8/data/local/post_cache.dart';
import 'package:srs8/data/models/post.dart';
import 'package:srs8/data/repositories/post_repository.dart';
import 'package:srs8/domain/entities/post_entity.dart';
import 'package:srs8/domain/entities/user_entity.dart';
import 'package:srs8/domain/repositories/post_repository.dart' as domain;
import 'package:srs8/domain/usecases/get_posts_usecase.dart';
import 'package:srs8/domain/usecases/get_users_usecase.dart';
import 'package:srs8/domain/usecases/create_post_usecase.dart';
import 'package:srs8/domain/usecases/get_cached_posts_usecase.dart';
import 'package:srs8/presentation/bloc/posts_bloc.dart';
import 'package:srs8/presentation/bloc/posts_event.dart';
import 'package:srs8/presentation/screens/home_screen.dart';

class MockPostRepository extends Mock implements domain.PostRepository {}

class MockLegacyPostRepository extends Mock implements PostRepository {}

class MockPostCache extends Mock implements PostCache {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const PostEntity(userId: 1, id: 1, title: 'Test', body: 'Test body'),
    );
  });
  late MockPostRepository domainRepository;
  late MockLegacyPostRepository legacyRepository;
  late MockPostCache cache;
  late PostsBloc postsBloc;

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

  final testPostEntities = testPosts
      .map(
        (post) => PostEntity(
          userId: post.userId,
          id: post.id,
          title: post.title,
          body: post.body,
        ),
      )
      .toList();

  const testUsers = [
    UserEntity(
      id: 1,
      name: 'User One',
      username: 'userone',
      email: 'one@example.com',
    ),
  ];

  setUp(() {
    domainRepository = MockPostRepository();
    legacyRepository = MockLegacyPostRepository();
    cache = MockPostCache();

    when(() => domainRepository.getCachedPosts()).thenAnswer((_) async => []);

    when(() => domainRepository.getPosts(page: 1, limit: 10, userId: null))
        .thenAnswer((_) async => testPostEntities);

    when(() => domainRepository.getUsers()).thenAnswer((_) async => testUsers);

    when(() => domainRepository.createPost(any()))
        .thenAnswer((invocation) async {
          return invocation.positionalArguments.first as PostEntity;
        });

    when(() => legacyRepository.getPostById(1))
        .thenAnswer((_) async => testPosts[0]);

    when(() => legacyRepository.getComments(1)).thenAnswer((_) async => []);

    postsBloc = PostsBloc(
      getPostsUseCase: GetPostsUseCase(domainRepository),
      getUsersUseCase: GetUsersUseCase(domainRepository),
      createPostUseCase: CreatePostUseCase(domainRepository),
      getCachedPostsUseCase: GetCachedPostsUseCase(domainRepository),
    );
  });

  tearDown(() async {
    await postsBloc.close();
  });

  Future<void> openHomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: postsBloc,
          child: HomeScreen(repository: legacyRepository, cache: cache),
        ),
      ),
    );

    postsBloc.add(const PostsStarted());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    print('Posts count: ${postsBloc.state.posts.length}');
    print('Is loading: ${postsBloc.state.isLoading}');
    print('Error: ${postsBloc.state.error}');
  }

  testWidgets('1. Home screen displays title and posts', (tester) async {
    await openHomeScreen(tester);

    expect(find.text('Post Explorer'), findsOneWidget);
    expect(find.text('Flutter basics'), findsOneWidget);
    expect(find.text('Dart language'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('2. Search filters posts by title', (tester) async {
    await openHomeScreen(tester);

    await tester.enterText(find.byType(TextField), 'Flutter');

    await tester.pumpAndSettle();

    expect(find.text('Flutter basics'), findsOneWidget);
    expect(find.text('Dart language'), findsNothing);
  });

  testWidgets('3. Tapping a post opens its details screen', (tester) async {
    await openHomeScreen(tester);

    await tester.tap(find.text('Flutter basics'));
    await tester.pump();

    expect(find.text('Post Details'), findsOneWidget);
    expect(find.text('Flutter basics'), findsOneWidget);
  });
}
