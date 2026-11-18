import 'package:equatable/equatable.dart';

import '../../domain/entities/post_entity.dart';
import '../../domain/entities/user_entity.dart';

class PostsState extends Equatable {
  final List<PostEntity> posts;
  final List<PostEntity> localPosts;
  final List<UserEntity> users;

  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isCached;

  final String? error;
  final String? pageError;

  final int currentPage;
  final int? selectedUserId;

  const PostsState({
    this.posts = const [],
    this.localPosts = const [],
    this.users = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.isCached = false,
    this.error,
    this.pageError,
    this.currentPage = 1,
    this.selectedUserId,
  });

  PostsState copyWith({
    List<PostEntity>? posts,
    List<PostEntity>? localPosts,
    List<UserEntity>? users,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isCached,
    String? error,
    String? pageError,
    int? currentPage,
    int? selectedUserId,
    bool clearError = false,
    bool clearPageError = false,
    bool clearSelectedUserId = false,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      localPosts: localPosts ?? this.localPosts,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isCached: isCached ?? this.isCached,
      error: clearError ? null : error ?? this.error,
      pageError:
          clearPageError ? null : pageError ?? this.pageError,
      currentPage: currentPage ?? this.currentPage,
      selectedUserId: clearSelectedUserId
    ? null
    : selectedUserId ?? this.selectedUserId,
    );
  }

  @override
  List<Object?> get props => [
        posts,
        localPosts,
        users,
        isLoading,
        isLoadingMore,
        hasMore,
        isCached,
        error,
        pageError,
        currentPage,
        selectedUserId,
      ];
}