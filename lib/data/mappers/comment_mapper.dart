import '../../domain/entities/comment_entity.dart';
import '../models/comment.dart';

class CommentMapper {
  static CommentEntity toEntity(Comment model) {
    return CommentEntity(
      postId: model.postId,
      id: model.id,
      name: model.name,
      email: model.email,
      body: model.body,
    );
  }

  static Comment toModel(CommentEntity entity) {
    return Comment(
      postId: entity.postId,
      id: entity.id,
      name: entity.name,
      email: entity.email,
      body: entity.body,
    );
  }
}