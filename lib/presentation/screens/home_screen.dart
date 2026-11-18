import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/post_cache.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/mappers/post_mapper.dart';
import '../../data/mappers/user_mapper.dart';
import '../../domain/entities/post_entity.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_event.dart';
import '../bloc/posts_state.dart';
import 'post_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final PostRepository repository;
  final PostCache cache;

  const HomeScreen({super.key, required this.repository, required this.cache});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _ascending = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final bloc = context.read<PostsBloc>();
    final state = bloc.state;

    if (_scrollController.position.extentAfter < 300 &&
        !state.isLoading &&
        !state.isLoadingMore &&
        state.hasMore) {
      bloc.add(const PostsNextPageRequested());
    }
  }

  List<Post> _visiblePosts(PostsState state) {
    final posts = state.posts.map(PostMapper.toModel).where((post) {
      return post.title.toLowerCase().contains(_search.trim().toLowerCase());
    }).toList();

    posts.sort(
      (a, b) => _ascending ? a.id.compareTo(b.id) : b.id.compareTo(a.id),
    );

    return posts;
  }

  void _changeFilter(int? userId) {
    context.read<PostsBloc>().add(PostsAuthorChanged(userId));
  }

  Future<void> _refresh() async {
    context.read<PostsBloc>().add(const PostsStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsBloc, PostsState>(
      builder: (context, state) {
        final posts = _visiblePosts(state);

        final users = state.users.map(UserMapper.toModel).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Post Explorer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'Добавить публикацию',
                onPressed: _showCreatePostDialog,
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: 'Сортировка по ID',
                onPressed: () {
                  setState(() {
                    _ascending = !_ascending;
                  });
                },
                icon: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск по заголовку',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Очистить поиск',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _search = '';
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _search = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: state.selectedUserId,
                      decoration: InputDecoration(
                        labelText: 'Автор',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Все авторы'),
                        ),
                        ...users.map(
                          (user) => DropdownMenuItem<int?>(
                            value: user.id,
                            child: Text(user.name),
                          ),
                        ),
                      ],
                      onChanged: _changeFilter,
                    ),
                    if (state.isCached)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Icon(Icons.offline_pin, size: 18),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Сохранённые данные. '
                                'Обновление не подтверждено.',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: state.isLoading && posts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null && posts.isEmpty
                    ? _errorView(state.error!)
                    : posts.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('Посты не найдены')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount:
                              posts.length +
                              (state.isLoadingMore || state.pageError != null
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index == posts.length) {
                              if (state.pageError != null) {
                                return Column(
                                  children: [
                                    Text(state.pageError!),
                                    TextButton(
                                      onPressed: () {
                                        context.read<PostsBloc>().add(
                                          const PostsNextPageRequested(),
                                        );
                                      },
                                      child: const Text('Повторить загрузку'),
                                    ),
                                  ],
                                );
                              }

                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final post = posts[index];

                            final isLocal = state.localPosts.any(
                              (local) => local.id == post.id,
                            );

                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PostDetailsScreen(
                                        post: post,
                                        repository: widget.repository,
                                      ),
                                    ),
                                  );
                                },
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE2EADF),
                                  child: Text('${post.id}'),
                                ),
                                title: Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.body,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isLocal)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Создано локально',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreatePostDialog() async {
    _titleController.clear();
    _bodyController.clear();

    final authors = context
        .read<PostsBloc>()
        .state
        .users
        .map(UserMapper.toModel)
        .toList();

    int selectedUserId = authors.isNotEmpty ? authors.first.id : 1;

    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Новая публикация'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedUserId,
                      decoration: const InputDecoration(labelText: 'Автор'),
                      items: [
                        if (authors.isEmpty)
                          const DropdownMenuItem<int>(
                            value: 1,
                            child: Text('User 1'),
                          ),
                        ...authors.map(
                          (user) => DropdownMenuItem<int>(
                            value: user.id,
                            child: Text(user.name),
                          ),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedUserId = value;
                                });
                              }
                            },
                    ),
                    TextField(
                      controller: _titleController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Заголовок (5–100 символов)',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    TextField(
                      controller: _bodyController,
                      maxLength: 1000,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Текст (10–1000 символов)',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () {
                          final title = _titleController.text.trim();
                          final body = _bodyController.text.trim();

                          if (title.length < 5 ||
                              title.length > 100 ||
                              body.length < 10 ||
                              body.length > 1000) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Заголовок: 5–100 символов. '
                                  'Текст: 10–1000 символов.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          final post = PostEntity(
                            userId: selectedUserId,
                            id: 0,
                            title: title,
                            body: body,
                          );

                          context.read<PostsBloc>().add(
                            PostCreateRequested(post),
                          );

                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Запрос на создание публикации отправлен.',
                              ),
                            ),
                          );
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _errorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _refresh, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
