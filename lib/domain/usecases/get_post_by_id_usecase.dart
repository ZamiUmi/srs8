import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetPostByIdUseCase {
  final PostRepository repository;

  GetPostByIdUseCase(this.repository);

  Future<PostEntity> call(int id) {
    return repository.getPostById(id);
  }
}