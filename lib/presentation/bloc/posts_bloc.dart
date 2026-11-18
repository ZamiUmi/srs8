import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../domain/usecases/get_posts_usecase.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/create_post_usecase.dart';
import 'posts_event.dart';
import 'posts_state.dart';
import '../../domain/usecases/get_cached_posts_usecase.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final GetPostsUseCase getPostsUseCase;
  final GetUsersUseCase getUsersUseCase;
  final CreatePostUseCase createPostUseCase;
  final GetCachedPostsUseCase getCachedPostsUseCase;

  PostsBloc({
  required this.getPostsUseCase,
  required this.getUsersUseCase,
  required this.createPostUseCase,
  required this.getCachedPostsUseCase,
}) : super(const PostsState()) {
    on<PostsStarted>(_onStarted);
    on<PostsNextPageRequested>(_onNextPageRequested);
    on<PostsAuthorChanged>(_onAuthorChanged);
    on<PostCreateRequested>(_onPostCreateRequested);
  }

  
  Future<void> _onStarted(
    PostsStarted event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    // Сначала пробуем показать сохранённые публикации.
    try {
      final cachedPosts = await getCachedPostsUseCase();

      if (cachedPosts.isNotEmpty) {
        emit(state.copyWith(
          posts: cachedPosts,
          isCached: true,
          isLoading: false,
        ));
      }
    } catch (_) {
      // Если кэш недоступен, продолжаем загрузку с сервера.
    }

    // Затем загружаем свежие публикации.
    try {
      final posts = await getPostsUseCase(page: 1);

      emit(state.copyWith(
        posts: posts,
        currentPage: 1,
        hasMore: posts.length == 10,
        isCached: false,
        isLoading: false,
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        isLoading: false,
        error: state.posts.isEmpty ? _errorMessage(error) : null,
        clearError: state.posts.isNotEmpty,
      ));
    }

    // Загружаем список авторов.
    try {
      final users = await getUsersUseCase();

      emit(state.copyWith(users: users));
    } catch (_) {
      // Публикации доступны и без списка авторов.
    }
  }


  
  Future<void> _onNextPageRequested(
    PostsNextPageRequested event,
    Emitter<PostsState> emit,
  ) async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    emit(state.copyWith(
      isLoadingMore: true,
      clearPageError: true,
    ));

    try {
      final nextPage = state.currentPage + 1;

      final newPosts = await getPostsUseCase(
        page: nextPage,
        userId: state.selectedUserId,
      );

      final existingIds = state.posts.map((post) => post.id).toSet();

      final uniquePosts = newPosts
          .where((post) => !existingIds.contains(post.id))
          .toList();

      emit(state.copyWith(
        posts: [...state.posts, ...uniquePosts],
        currentPage: nextPage,
        hasMore: newPosts.length == 10,
        isLoadingMore: false,
        clearPageError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        isLoadingMore: false,
        pageError: _errorMessage(error),
      ));
    }
  }


  
  Future<void> _onAuthorChanged(
    PostsAuthorChanged event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      posts: [],
      currentPage: 1,
      hasMore: true,
      selectedUserId: event.userId,
      clearSelectedUserId: event.userId == null,
      clearError: true,
      clearPageError: true,
      isCached: false,
    ));

    try {
      final posts = await getPostsUseCase(
        page: 1,
        userId: event.userId,
      );

      emit(state.copyWith(
        posts: posts,
        currentPage: 1,
        hasMore: posts.length == 10,
        isLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        isLoading: false,
        error: _errorMessage(error),
      ));
    }
  }


  
  Future<void> _onPostCreateRequested(
    PostCreateRequested event,
    Emitter<PostsState> emit,
  ) async {
    try {
      final createdPost = await createPostUseCase(event.post);

      final updatedLocalPosts = [
        createdPost,
        ...state.localPosts.where(
          (post) => post.id != createdPost.id,
        ),
      ];

      final updatedPosts = [
        createdPost,
        ...state.posts.where(
          (post) => post.id != createdPost.id,
        ),
      ];

      emit(state.copyWith(
        posts: updatedPosts,
        localPosts: updatedLocalPosts,
        isCached: false,
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: _errorMessage(error),
      ));
    }
  }


  String _errorMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }

    return 'Произошла ошибка. Попробуйте ещё раз.';
  }
}