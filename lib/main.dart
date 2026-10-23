
import 'package:flutter/material.dart';

import 'core/network/dio_client.dart';
import 'data/local/post_cache.dart';
import 'data/remote/post_api.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cache = PostCache();
  await cache.init();

  final dio = DioClient.create();
  final api = PostApi(dio);
  final repository = PostRepository(api, cache);

  runApp(
    PostExplorerApp(
      repository: repository,
      cache: cache,
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
    return MaterialApp(
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
    );
  }
}
