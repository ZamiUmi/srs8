
import 'package:flutter/material.dart';

import '../../core/error/app_exception.dart';
import '../../data/local/post_cache.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import 'post_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final PostRepository repository;
  final PostCache cache;

  const HomeScreen({
    super.key,
    required this.repository,
    required this.cache,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Post> _posts = [];
  final List<Post> _localPosts = [];
  List<User> _users = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _cached = false;
  bool _ascending = true;

  String? _error;
  String? _pageError;

  int _page = 1;
  int? _selectedUserId;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final savedPosts = widget.cache.getPosts();

    if (savedPosts.isNotEmpty && mounted) {
      setState(() {
        _posts = savedPosts;
        _cached = true;
        _loading = false;
      });
    }

    await _loadPosts(reset: true);
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await widget.repository.getUsers();

      if (mounted) {
        setState(() => _users = users);
      }
    } catch (_) {
      // Посты работают и без списка авторов.
    }
  }

  Future<void> _loadPosts({
    bool reset = false,
    bool refresh = false,
  }) async {
    if (_loadingMore || (_loading && !reset)) return;
    if (!reset && !_hasMore) return;

    final requestedPage = reset ? 1 : _page + 1;
    final requestedUserId = _selectedUserId;

    setState(() {
      if (reset) {
        _loading = _posts.isEmpty;
        _error = null;
        _pageError = null;
      } else {
        _loadingMore = true;
        _pageError = null;
      }
    });

    try {
      final result = await widget.repository.getPosts(
        page: requestedPage,
        limit: 10,
        userId: requestedUserId,
      );

      if (!mounted) return;

      // Не позволяем старому запросу перезаписать новый фильтр.
      if (requestedUserId != _selectedUserId) return;

      setState(() {
        if (reset) {
          // Сохраняем созданные пользователем публикации
          // при обновлении списка с сервера.
          final localPosts = _localPosts.where((post) {
            return _selectedUserId == null ||
                post.userId == _selectedUserId;
          }).toList();

          final localIds = localPosts.map((post) => post.id).toSet();

          _posts = [
            ...localPosts,
            ...result.where((post) => !localIds.contains(post.id)),
          ];

          _page = 1;
        } else {
          final existingIds = _posts.map((post) => post.id).toSet();

          _posts.addAll(
            result.where((post) => !existingIds.contains(post.id)),
          );

          _page = requestedPage;
        }

        _hasMore = result.length == 10;
        _loading = false;
        _loadingMore = false;
        _cached = false;
        _error = null;
        _pageError = null;
      });
    } catch (error) {
      if (!mounted) return;

      final message = error is AppException
          ? error.message
          : 'Не удалось загрузить посты. Попробуйте ещё раз.';

      setState(() {
        _loading = false;
        _loadingMore = false;

        if (reset) {
          _error = message;
        } else {
          _pageError = message;
        }
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.extentAfter < 300 &&
        !_loading &&
        !_loadingMore &&
        _hasMore) {
      _loadPosts();
    }
  }

  void _changeFilter(int? userId) {
    setState(() {
      _selectedUserId = userId;
      _posts = [];
      _page = 1;
      _hasMore = true;
      _cached = false;
      _error = null;
    });

    _loadPosts(reset: true);
  }

  List<Post> get _visiblePosts {
    final query = _search.trim().toLowerCase();

    final result = _posts.where((post) {
      return post.title.toLowerCase().contains(query);
    }).toList();

    result.sort(
      (a, b) => _ascending
          ? a.id.compareTo(b.id)
          : b.id.compareTo(a.id),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final posts = _visiblePosts;

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
              setState(() => _ascending = !_ascending);
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
                        setState(() => _search = '');
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
                    setState(() => _search = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedUserId,
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
                    ..._users.map(
                      (user) => DropdownMenuItem<int?>(
                        value: user.id,
                        child: Text(user.name),
                      ),
                    ),
                  ],
                  onChanged: _changeFilter,
                ),
                if (_cached)
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
            child: _loading && _posts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _posts.isEmpty
                    ? _errorView()
                    : posts.isEmpty
                        ? RefreshIndicator(
                            onRefresh: () => _loadPosts(
                              reset: true,
                              refresh: true,
                            ),
                            child: ListView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 100),
                                Center(child: Text('Посты не найдены')),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadPosts(
                              reset: true,
                              refresh: true,
                            ),
                            child: ListView.builder(
                              controller: _scrollController,
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: posts.length +
                                  (_loadingMore || _pageError != null
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                if (index == posts.length) {
                                  if (_pageError != null) {
                                    return Column(
                                      children: [
                                        Text(_pageError!),
                                        TextButton(
                                          onPressed: () => _loadPosts(),
                                          child: const Text(
                                            'Повторить загрузку',
                                          ),
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
                                final isLocal = _localPosts.any(
                                  (local) => local.id == post.id,
                                );

                                return Card(
                                  color: Colors.white,
                                  margin:
                                      const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PostDetailsScreen(
                                            post: post,
                                            repository: widget.repository,
                                          ),
                                        ),
                                      );
                                    },
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          const Color(0xFFE2EADF),
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
  }

  Future<void> _showCreatePostDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final authors = _users;
    int selectedUserId = authors.isNotEmpty ? authors.first.id : 1;
    bool saving = false;

    try {
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
                        decoration:
                            const InputDecoration(labelText: 'Автор'),
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
                        controller: titleController,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Заголовок (5–100 символов)',
                        ),
                        textCapitalization:
                            TextCapitalization.sentences,
                      ),
                      TextField(
                        controller: bodyController,
                        maxLength: 1000,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Текст (10–1000 символов)',
                        ),
                        textCapitalization:
                            TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Отмена'),
                  ),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final body = bodyController.text.trim();

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

                            setDialogState(() => saving = true);

                            try {
                              final createdPost =
                                  await widget.repository.createPost(
                                Post(
                                  userId: selectedUserId,
                                  id: 0,
                                  title: title,
                                  body: body,
                                ),
                              );

                              if (!mounted) return;

                              setState(() {
                                // Запоминаем публикацию отдельно,
                                // чтобы обновление с сервера её не удалило.
                                _localPosts.removeWhere(
                                  (post) => post.id == createdPost.id,
                                );
                                _localPosts.insert(0, createdPost);

                                _selectedUserId = null;
                                _search = '';
                                _searchController.clear();

                                final existingIndex = _posts.indexWhere(
                                  (post) => post.id == createdPost.id,
                                );

                                if (existingIndex >= 0) {
                                  _posts[existingIndex] = createdPost;
                                } else {
                                  _posts.insert(0, createdPost);
                                }

                                _cached = false;
                                _loading = false;
                                _loadingMore = false;
                                _error = null;
                                _pageError = null;
                              });

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Публикация создана! '
                                    'Она отмечена как локальная.',
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (!dialogContext.mounted) return;

                              setDialogState(() => saving = false);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Не удалось создать публикацию: $error',
                                  ),
                                ),
                              );
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Создать'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
      bodyController.dispose();
    }
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadPosts(reset: true),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
