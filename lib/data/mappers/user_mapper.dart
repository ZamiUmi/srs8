import '../../domain/entities/user_entity.dart';
import '../models/user.dart';

class UserMapper {
  static UserEntity toEntity(User model) {
    return UserEntity(
      id: model.id,
      name: model.name,
      username: model.username,
      email: model.email,
    );
  }

  static User toModel(UserEntity entity) {
    return User(
      id: entity.id,
      name: entity.name,
      username: entity.username,
      email: entity.email,
    );
  }
}