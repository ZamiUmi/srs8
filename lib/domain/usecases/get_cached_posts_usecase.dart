import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetCachedPostsUseCase {
  final PostRepository repository;

  GetCachedPostsUseCase(this.repository);

  Future<List<PostEntity>> call() {
    return repository.getCachedPosts();
  }
}