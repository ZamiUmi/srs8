import '../entities/user_entity.dart';
import '../repositories/post_repository.dart';

class GetUsersUseCase {
  final PostRepository repository;

  GetUsersUseCase(this.repository);

  Future<List<UserEntity>> call() {
    return repository.getUsers();
  }
}