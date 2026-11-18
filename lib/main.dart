
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'data/local/post_cache.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/bloc/posts_bloc.dart';
import 'presentation/bloc/posts_event.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupDependencies();

  runApp(
    PostExplorerApp(
      repository: getIt<PostRepository>(),
      cache: getIt<PostCache>(),
    ),
  );
}

class PostExplorerApp extends StatelessWidget {
  final PostRepository repository;
  final PostCache cache;

  const PostExplorerApp({
    super.key,
    required this.repository,
    required this.cache,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PostsBloc>()..add(const PostsStarted()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Post Explorer',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF496B58),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F7F2),
        ),
        home: HomeScreen(
          repository: repository,
          cache: cache,
        ),
      ),
    );
  }
}
