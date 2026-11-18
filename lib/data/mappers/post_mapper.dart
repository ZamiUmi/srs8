
import '../../domain/entities/post_entity.dart';
import '../models/post.dart';

class PostMapper {
  static PostEntity toEntity(Post model) {
    return PostEntity(
      userId: model.userId,
      id: model.id,
      title: model.title,
      body: model.body,
    );
  }

  static Post toModel(PostEntity entity) {
    return Post(
      userId: entity.userId,
      id: entity.id,
      title: entity.title,
      body: entity.body,
    );
  }
}
