
import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/user.dart';
import '../remote/post_api.dart';
import '../local/post_cache.dart';

class PostRepository {
  final PostApi api;
  final PostCache cache;

  PostRepository(this.api, this.cache); 

  Future<List<Post>> getPosts({
    required int page,
    int limit = 10,
    int? userId,
  }) async {
    try {
      if (userId != null) {
       return await api.getPostsByUser(userId, page, limit);
      }

      final posts = await api.getPosts(page, limit);

      if (page == 1 && userId == null) {
        await cache.savePosts(posts);
      }

      return posts;
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } on FormatException {
      throw const AppException(
        'Не удалось прочитать данные сервера.',
      );
    }
  }

  Future<Post> getPostById(int id) async {
    try {
      return await api.getPostById(id);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } on FormatException {
      throw const AppException(
        'Не удалось прочитать данные сервера.',
      );
    }
  }

  Future<List<Comment>> getComments(int postId) async {
    try {
      return await api.getComments(postId);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } on FormatException {
      throw const AppException(
        'Не удалось прочитать данные сервера.',
      );
    }
  }

  Future<List<User>> getUsers() async {
    try {
      return await api.getUsers();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } on FormatException {
      throw const AppException(
        'Не удалось прочитать данные сервера.',
      );
    }
  }

  Future<Post> createPost(Post post) async {
    try {
      return await api.createPost(post);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } on FormatException {
      throw const AppException(
        'Не удалось прочитать данные сервера.',
      );
    }
  }
}
