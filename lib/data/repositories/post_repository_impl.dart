
import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/post_repository.dart';
import '../local/post_cache.dart';
import '../mappers/post_mapper.dart';
import '../mappers/comment_mapper.dart';
import '../mappers/user_mapper.dart';
import '../remote/post_api.dart';

class PostRepositoryImpl implements PostRepository {
  final PostApi api;
  final PostCache cache;

  PostRepositoryImpl(this.api, this.cache);

 @override
  Future<List<PostEntity>> getPosts({
    required int page,
    int limit = 10,
    int? userId,
  }) async {
    try {
      if (userId != null) {
        final posts = await api.getPostsByUser(userId, page, limit);
        return posts.map(PostMapper.toEntity).toList();
      }

      final posts = await api.getPosts(page, limit);

      if (page == 1) {
        await cache.savePosts(posts);
      }

      return posts.map(PostMapper.toEntity).toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } on FormatException {
      throw const AppException(
        'Не удалось прочитать данные сервера.',
      );
    }
  }

  @override
  Future<List<PostEntity>> getCachedPosts() async {
    final posts = cache.getPosts();

    return posts.map(PostMapper.toEntity).toList();
  }
  @override
  Future<PostEntity> getPostById(int id) async {
    try {
      final post = await api.getPostById(id);
      return PostMapper.toEntity(post);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } on FormatException {
      throw const AppException(
        'Не удалось прочитать данные сервера.',
      );
    }
  }

  @override
  Future<List<CommentEntity>> getComments(int postId) async {
    try {
      final comments = await api.getComments(postId);
      return comments.map(CommentMapper.toEntity).toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } on FormatException {
      throw const AppException(
        'Не удалось прочитать данные сервера.',
      );
    }
  }

  @override
  Future<List<UserEntity>> getUsers() async {
    try {
      final users = await api.getUsers();
      return users.map((user) => UserMapper.toEntity(user)).toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } on FormatException {
      throw const AppException(
        'Не удалось прочитать данные сервера.',
      );
    }
  }

  @override
  Future<PostEntity> createPost(PostEntity post) async {
    try {
      final model = PostMapper.toModel(post);
      final createdPost = await api.createPost(model);
      return PostMapper.toEntity(createdPost);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } on FormatException {
      throw const AppException(
        'Не удалось прочитать данные сервера.',
      );
    }
  }
}
