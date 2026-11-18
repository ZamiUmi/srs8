
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetPostsUseCase {
  final PostRepository repository;

  GetPostsUseCase(this.repository);

  Future<List<PostEntity>> call({
    required int page,
    int limit = 10,
    int? userId,
  }) {
    return repository.getPosts(
      page: page,
      limit: limit,
      userId: userId,
    );
  }
}
