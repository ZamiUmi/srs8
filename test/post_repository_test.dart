
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:srs8/core/error/app_exception.dart';
import 'package:srs8/data/local/post_cache.dart';
import 'package:srs8/data/models/post.dart';
import 'package:srs8/data/remote/post_api.dart';
import 'package:srs8/data/repositories/post_repository.dart';

class MockPostApi extends Mock implements PostApi {}

class MockPostCache extends Mock implements PostCache {}

void main() {
  late MockPostApi api;
  late MockPostCache cache;
  late PostRepository repository;

  const testPost = Post(
    userId: 1,
    id: 1,
    title: 'Test post',
    body: 'This is a test post body.',
  );

  setUp(() {
    api = MockPostApi();
    cache = MockPostCache();
    repository = PostRepository(api, cache);
  });

  test('1. getPosts returns posts when API succeeds', () async {
    when(() => api.getPosts(1, 10))
        .thenAnswer((_) async => [testPost]);

    when(() => cache.savePosts([testPost]))
        .thenAnswer((_) async {});

    final result = await repository.getPosts(page: 1);

    expect(result, [testPost]);

    verify(() => api.getPosts(1, 10)).called(1);
    verify(() => cache.savePosts([testPost])).called(1);
  });

  test('2. getPosts filters posts by user ID', () async {
    when(() => api.getPostsByUser(2, 1, 10))
        .thenAnswer((_) async => [testPost]);

    final result = await repository.getPosts(
      page: 1,
      userId: 2,
    );

    expect(result, [testPost]);

    verify(() => api.getPostsByUser(2, 1, 10)).called(1);
    verifyNever(() => cache.savePosts(any()));
  });

  test('3. Second page does not save posts to cache', () async {
    when(() => api.getPosts(2, 10))
        .thenAnswer((_) async => [testPost]);

    final result = await repository.getPosts(page: 2);

    expect(result, [testPost]);

    verify(() => api.getPosts(2, 10)).called(1);
    verifyNever(() => cache.savePosts(any()));
  });

  test('4. getPostById returns a post', () async {
    when(() => api.getPostById(1))
        .thenAnswer((_) async => testPost);

    final result = await repository.getPostById(1);

    expect(result.id, 1);
    expect(result.title, 'Test post');

    verify(() => api.getPostById(1)).called(1);
  });

  test('5. createPost sends and returns a post', () async {
    when(() => api.createPost(testPost))
        .thenAnswer((_) async => testPost);

    final result = await repository.createPost(testPost);

    expect(result, testPost);

    verify(() => api.createPost(testPost)).called(1);
  });

  test('6. getPosts converts DioException into AppException', () async {
    when(() => api.getPosts(1, 10)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(
      () => repository.getPosts(page: 1),
      throwsA(isA<AppException>()),
    );
  });

  test('7. getPosts handles FormatException', () async {
    when(() => api.getPosts(1, 10))
        .thenThrow(const FormatException());

    expect(
      () => repository.getPosts(page: 1),
      throwsA(isA<AppException>()),
    );
  });
}
