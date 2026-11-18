
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../../data/local/post_cache.dart';
import '../../data/remote/post_api.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/repositories/post_repository.dart'
    as domain;
import '../../domain/usecases/get_posts_usecase.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/create_post_usecase.dart';
import '../../presentation/bloc/posts_bloc.dart';
import '../../domain/usecases/get_cached_posts_usecase.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final cache = PostCache();
  await cache.init();

  final dio = DioClient.create();
  final api = PostApi(dio);

  getIt.registerSingleton<PostCache>(cache);
  getIt.registerSingleton<PostApi>(api);


  // Старый репозиторий временно нужен HomeScreen.
  getIt.registerSingleton<PostRepository>(
    PostRepository(api, cache),
  );

    getIt.registerFactory(
    () => GetCachedPostsUseCase(getIt<domain.PostRepository>()),
  );

  // Новый репозиторий реализует Domain-контракт.
  getIt.registerSingleton<domain.PostRepository>(
    PostRepositoryImpl(api, cache),
  );

  // Регистрируем UseCase.
  getIt.registerFactory(
    () => GetPostsUseCase(getIt<domain.PostRepository>()),
  );

  getIt.registerFactory(
    () => GetUsersUseCase(getIt<domain.PostRepository>()),
  );

  getIt.registerFactory(
    () => CreatePostUseCase(getIt<domain.PostRepository>()),
  );

  // Регистрируем PostsBloc.
 getIt.registerFactory(
  () => PostsBloc(
    getPostsUseCase: getIt<GetPostsUseCase>(),
    getUsersUseCase: getIt<GetUsersUseCase>(),
    createPostUseCase: getIt<CreatePostUseCase>(),
    getCachedPostsUseCase: getIt<GetCachedPostsUseCase>(),
  ),
);
}
