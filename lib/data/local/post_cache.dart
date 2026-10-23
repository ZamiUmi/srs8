
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/post.dart';

class PostCache {
  static const String _boxName = 'posts_cache';
  static const String _postsKey = 'posts';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  Future<void> savePosts(List<Post> posts) async {
    final jsonList = posts.map((post) => post.toJson()).toList();

    await _box.put(_postsKey, jsonEncode(jsonList));
  }

  List<Post> getPosts() {
    final cachedJson = _box.get(_postsKey);

    if (cachedJson == null) {
      return [];
    }

    try {
      final decoded = jsonDecode(cachedJson) as List<dynamic>;

      return decoded
          .map(
            (item) => Post.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  bool get hasPosts => getPosts().isNotEmpty;
}
