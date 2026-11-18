import 'package:equatable/equatable.dart';

import '../../domain/entities/post_entity.dart';

abstract class PostsEvent extends Equatable {
  const PostsEvent();

  @override
  List<Object?> get props => [];
}

class PostsStarted extends PostsEvent {
  const PostsStarted();
}

class PostsNextPageRequested extends PostsEvent {
  const PostsNextPageRequested();
}

class PostsAuthorChanged extends PostsEvent {
  final int? userId;

  const PostsAuthorChanged(this.userId);

  @override
  List<Object?> get props => [userId];
}

class PostCreateRequested extends PostsEvent {
  final PostEntity post;

  const PostCreateRequested(this.post);

  @override
  List<Object?> get props => [post];
}