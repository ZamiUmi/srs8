import 'package:flutter/material.dart';

import '../../data/models/post.dart';
import '../../data/models/comment.dart';
import '../../data/repositories/post_repository.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;
  final PostRepository repository;

  const PostDetailsScreen({
    super.key,
    required this.post,
    required this.repository,
  });

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late Future<List<Comment>> _commentsFuture;

  late Post _post;
  bool _isLocalPost = false;

  @override
  void initState() {
    super.initState();

    _post = widget.post;
    _isLocalPost = widget.post.id >= 101;

    _commentsFuture = widget.repository.getComments(widget.post.id);
    _loadPost();
  }

  Future<void> _loadPost() async {
    // Если пост создан через POST, оставляем его локальные данные.
    if (_isLocalPost) return;

    try {
      final loadedPost =
          await widget.repository.getPostById(widget.post.id);

      if (!mounted) return;

      setState(() {
        _post = loadedPost;
      });
    } catch (_) {
      // При ошибке оставляем пост, который уже передан экрану.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isLocalPost)
            const Chip(
              avatar: Icon(Icons.info_outline),
              label: Text('Создан локально'),
            ),
          Text(
            _post.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text('Post ID: ${_post.id}'),
          Text('Author ID: ${_post.userId}'),
          const Divider(height: 32),
          Text(
            _post.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          Text(
            'Comments',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Comment>>(
            future: _commentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  'Не удалось загрузить комментарии.',
                );
              }

              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
                return const Text('Комментариев пока нет.');
              }

              return Column(
                children: comments.map((comment) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.email,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(comment.body),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}