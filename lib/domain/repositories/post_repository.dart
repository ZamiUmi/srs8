
import '../entities/post_entity.dart';
import '../entities/comment_entity.dart';
import '../entities/user_entity.dart';

abstract class PostRepository {
  Future<List<PostEntity>> getPosts({
    required int page,
    int limit = 10,
    int? userId,
  });

  Future<List<PostEntity>> getCachedPosts();

  Future<PostEntity> getPostById(int id);

  Future<List<CommentEntity>> getComments(int postId);

  Future<List<UserEntity>> getUsers();

  Future<PostEntity> createPost(PostEntity post);
}

