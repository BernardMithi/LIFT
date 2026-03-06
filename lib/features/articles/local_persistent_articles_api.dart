import 'dart:convert';

import 'package:lift/features/articles/in_memory_articles_api.dart';
import 'package:lift/shared/models/article.dart';
import 'package:lift/shared/services/articles_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPersistentArticlesApi extends ArticlesApi {
  LocalPersistentArticlesApi({InMemoryArticlesApi? memoryApi})
    : _memoryApi = memoryApi ?? InMemoryArticlesApi();

  static const String _storageKey = 'lift_local_articles_v1';

  InMemoryArticlesApi _memoryApi;
  bool _loadedFromDisk = false;

  @override
  Future<ArticlesPage> getArticles(ArticlesQuery query) async {
    await _ensureLoaded();
    return _memoryApi.getArticles(query);
  }

  @override
  Future<Article?> getArticleById(String articleId) async {
    await _ensureLoaded();
    return _memoryApi.getArticleById(articleId);
  }

  @override
  Future<List<ArticleAuthor>> getAuthors() async {
    await _ensureLoaded();
    return _memoryApi.getAuthors();
  }

  @override
  Future<ArticleFilterOptions> getFilterOptions() async {
    await _ensureLoaded();
    return _memoryApi.getFilterOptions();
  }

  @override
  Future<Article> createArticle({
    required ArticleInput input,
    required String authorId,
  }) async {
    await _ensureLoaded();
    final article = await _memoryApi.createArticle(
      input: input,
      authorId: authorId,
    );
    await _persistArticles();
    return article;
  }

  @override
  Future<Article> updateArticle({
    required String articleId,
    required ArticleInput input,
  }) async {
    await _ensureLoaded();
    final article = await _memoryApi.updateArticle(
      articleId: articleId,
      input: input,
    );
    await _persistArticles();
    return article;
  }

  @override
  Future<void> deleteArticle(String articleId) async {
    await _ensureLoaded();
    await _memoryApi.deleteArticle(articleId);
    await _persistArticles();
  }

  Future<void> _ensureLoaded() async {
    if (_loadedFromDisk) return;
    _loadedFromDisk = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final restored = <Article>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final map = entry.map((key, value) => MapEntry(key.toString(), value));
        final article = _articleFromMap(map);
        if (article != null) {
          restored.add(article);
        }
      }
      if (restored.isEmpty) return;
      _memoryApi = InMemoryArticlesApi(seedArticles: restored);
    } catch (_) {
      // Ignore malformed local cache and continue with defaults.
    }
  }

  Future<void> _persistArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allArticles = await _allArticles();
      final encoded = jsonEncode(
        allArticles.map(_articleToMap).toList(growable: false),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Non-fatal persistence failure.
    }
  }

  Future<List<Article>> _allArticles() async {
    final values = <Article>[];
    var page = 1;
    while (true) {
      final response = await _memoryApi.getArticles(
        ArticlesQuery(
          page: page,
          limit: 200,
          includeDrafts: true,
          sort: ArticleSort.latest,
        ),
      );
      values.addAll(response.data);
      if (!response.pagination.hasNextPage) break;
      page += 1;
    }
    return values;
  }

  Map<String, dynamic> _articleToMap(Article article) {
    return <String, dynamic>{
      'id': article.id,
      'title': article.title,
      'summary': article.summary,
      'content': article.content,
      'imageUrl': article.imageUrl,
      'authorId': article.authorId,
      'tags': article.tags,
      'machineIds': article.machineIds,
      'muscleGroups': article.muscleGroups,
      'categories': article.categories,
      'publishedAt': article.publishedAt.toIso8601String(),
      'updatedAt': article.updatedAt.toIso8601String(),
      'status': article.status.wireValue,
    };
  }

  Article? _articleFromMap(Map<String, dynamic> map) {
    try {
      final id = _asString(map['id']);
      final title = _asString(map['title']);
      final summary = _asString(map['summary']);
      final content = _asString(map['content']);
      final authorId = _asString(map['authorId']);
      final publishedAt = _asDateTime(map['publishedAt']);
      final updatedAt = _asDateTime(map['updatedAt']);
      if (id == null ||
          title == null ||
          summary == null ||
          content == null ||
          authorId == null ||
          publishedAt == null ||
          updatedAt == null) {
        return null;
      }
      return Article(
        id: id,
        title: title,
        summary: summary,
        content: content,
        imageUrl: _asString(map['imageUrl']),
        authorId: authorId,
        tags: _asStringList(map['tags']),
        machineIds: _asStringList(map['machineIds']),
        muscleGroups: _asStringList(map['muscleGroups']),
        categories: _asStringList(map['categories']),
        publishedAt: publishedAt,
        updatedAt: updatedAt,
        status: ArticleStatusX.fromWire(
          _asString(map['status']) ?? 'published',
        ),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _asDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String? _asString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  List<String> _asStringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
