import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class CreatePostUseCase {
  final PostRepository repository;

  CreatePostUseCase(this.repository);

  Future<PostEntity> call(PostEntity post) {
    return repository.createPost(post);
  }
}