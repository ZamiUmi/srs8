
import 'package:flutter_test/flutter_test.dart';
import 'package:srs8/data/models/post.dart';

void main() {
  final posts = [
    const Post(
      userId: 1,
      id: 1,
      title: 'Flutter basics',
      body: 'Learn the basics of Flutter.',
    ),
    const Post(
      userId: 2,
      id: 2,
      title: 'Dart language',
      body: 'Learn the Dart language.',
    ),
    const Post(
      userId: 1,
      id: 3,
      title: 'Flutter widgets',
      body: 'Explore Flutter widgets.',
    ),
  ];

  test('Post converts to JSON and back', () {
    const post = Post(
      userId: 1,
      id: 1,
      title: 'My first post',
      body: 'This is a test post body.',
    );

    final json = post.toJson();
    final restoredPost = Post.fromJson(json);

    expect(restoredPost.id, 1);
    expect(restoredPost.userId, 1);
    expect(restoredPost.title, 'My first post');
    expect(restoredPost.body, 'This is a test post body.');
  });

  test('Filtering posts by author returns only matching posts', () {
    final filteredPosts = posts.where((post) => post.userId == 1).toList();

    expect(filteredPosts.length, 2);
    expect(filteredPosts.every((post) => post.userId == 1), isTrue);
  });

  test('Sorting posts by ID in ascending order works', () {
    final sortedPosts = [...posts]..sort((a, b) => a.id.compareTo(b.id));

    expect(sortedPosts.map((post) => post.id).toList(), [1, 2, 3]);
  });

  test('Pagination does not add duplicate post IDs', () {
    final firstPage = [posts[0], posts[1]];
    final secondPage = [posts[1], posts[2]];

    final combinedPosts = [...firstPage];

    for (final post in secondPage) {
      if (!combinedPosts.any((existing) => existing.id == post.id)) {
        combinedPosts.add(post);
      }
    }

    expect(combinedPosts.map((post) => post.id).toList(), [1, 2, 3]);
  });
}
