
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/post.dart';
import '../models/comment.dart';
import '../models/user.dart';

part 'post_api.g.dart';

@RestApi(baseUrl: 'https://jsonplaceholder.typicode.com')
abstract class PostApi {
  factory PostApi(Dio dio, {String? baseUrl}) = _PostApi;

  @GET('/posts')
  Future<List<Post>> getPosts(
    @Query('_page') int page,
    @Query('_limit') int limit,
  );

  @GET('/posts/{id}')
  Future<Post> getPostById(@Path('id') int id);

  @GET('/posts')
  Future<List<Post>> getPostsByUser(
    @Query('userId') int userId,
  @Query('_page') int page,
  @Query('_limit') int limit,
  );

  @GET('/posts/{id}/comments')
  Future<List<Comment>> getComments(@Path('id') int postId);

  @POST('/posts')
  Future<Post> createPost(@Body() Post post);

  @GET('/users')
  Future<List<User>> getUsers();

  @GET('/users/{id}')
  Future<User> getUserById(@Path('id') int id);
}
