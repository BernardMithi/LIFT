import 'package:lift/features/articles/firebase_articles_api.dart';
import 'package:lift/features/articles/in_memory_articles_api.dart';
import 'package:lift/features/articles/local_persistent_articles_api.dart';
import 'package:lift/shared/models/article.dart';
import 'package:lift/shared/services/articles_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticlesRepository {
  ArticlesRepository({
    ArticlesApi? api,
    this.currentUserId = 'coach_nia',
    this.currentRole = AppUserRole.coach,
  }) : _api =
           api ??
           FirebaseArticlesApi.tryCreate() ??
           LocalPersistentArticlesApi(memoryApi: InMemoryArticlesApi());

  static final ArticlesRepository instance = ArticlesRepository();
  static const String _savedArticlesStorageKey = 'lift_saved_article_ids_v1';

  final ArticlesApi _api;
  final Map<String, ArticlesPage> _pageCache = <String, ArticlesPage>{};
  final Map<String, Future<ArticlesPage>> _pageRequests =
      <String, Future<ArticlesPage>>{};
  final Map<String, Article> _articleCache = <String, Article>{};
  final Map<String, Future<Article?>> _articleRequests =
      <String, Future<Article?>>{};

  List<ArticleAuthor>? _authorsCache;
  Future<List<ArticleAuthor>>? _authorsRequest;
  ArticleFilterOptions? _filterOptionsCache;
  Future<ArticleFilterOptions>? _filterOptionsRequest;
  final Set<String> _savedArticleIds = <String>{};
  bool _savedArticlesLoaded = false;
  Future<Set<String>>? _savedArticlesRequest;

  String currentUserId;
  AppUserRole currentRole;

  bool get canCreate =>
      currentRole == AppUserRole.admin || currentRole == AppUserRole.coach;

  bool canEdit(Article article) {
    if (currentRole == AppUserRole.admin) return true;
    if (currentRole == AppUserRole.coach && article.authorId == currentUserId) {
      return true;
    }
    return false;
  }

  bool canDelete(Article article) => canEdit(article);

  /// Archive: admin can archive any; coach can archive their own.
  bool canArchive(Article article) {
    if (currentRole == AppUserRole.admin) return true;
    if (currentRole == AppUserRole.coach && article.authorId == currentUserId) {
      return true;
    }
    return false;
  }

  List<ArticleAuthor>? peekAuthors() => _authorsCache;

  ArticleFilterOptions? peekFilterOptions() => _filterOptionsCache;

  ArticlesPage? peekArticles(ArticlesQuery query) =>
      _pageCache[_pageCacheKey(_scopedQuery(query))];

  Article? peekArticleById(String articleId) => _articleCache[articleId];

  Set<String> peekSavedArticleIds() =>
      Set<String>.unmodifiable(_savedArticleIds);

  bool isArticleSavedSync(String articleId) =>
      _savedArticleIds.contains(articleId);

  Iterable<String> get cachedImageUrls sync* {
    final seen = <String>{};
    for (final article in _articleCache.values) {
      final imageUrl = article.imageUrl?.trim();
      final uri = imageUrl == null ? null : Uri.tryParse(imageUrl);
      final isHttp =
          uri != null &&
          uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
      if (!isHttp || !seen.add(imageUrl!)) {
        continue;
      }
      yield imageUrl;
    }
  }

  Future<void> prewarm() async {
    final futures = <Future<dynamic>>[
      getAuthors(),
      getFilterOptions(),
      getSavedArticleIds(),
      getArticles(
        const ArticlesQuery(page: 1, limit: 3, sort: ArticleSort.latest),
      ),
      getArticles(
        const ArticlesQuery(page: 1, limit: 5, sort: ArticleSort.latest),
      ),
    ];

    if (canCreate) {
      futures.add(
        getArticles(
          ArticlesQuery(
            page: 1,
            limit: 5,
            sort: ArticleSort.latest,
            authorFilters: {currentUserId},
          ),
        ),
      );
    }

    await Future.wait(futures);
  }

  Future<ArticlesPage> getArticles(ArticlesQuery query) {
    final scoped = _scopedQuery(query);
    final key = _pageCacheKey(scoped);
    final cached = _pageCache[key];
    if (cached != null) return Future<ArticlesPage>.value(cached);

    final inFlight = _pageRequests[key];
    if (inFlight != null) return inFlight;

    final request = _api
        .getArticles(scoped)
        .then(
          (page) {
            _pageCache[key] = page;
            _pageRequests.remove(key);
            _seedArticleCache(page.data);
            return page;
          },
          onError: (Object error, StackTrace stackTrace) {
            _pageRequests.remove(key);
            throw error;
          },
        );

    _pageRequests[key] = request;
    return request;
  }

  Future<Article?> getArticleById(String articleId) {
    final cached = _articleCache[articleId];
    if (cached != null) return Future<Article?>.value(cached);

    final inFlight = _articleRequests[articleId];
    if (inFlight != null) return inFlight;

    final request = _api
        .getArticleById(articleId)
        .then(
          (article) {
            _articleRequests.remove(articleId);
            if (article != null) {
              _articleCache[article.id] = article;
            }
            return article;
          },
          onError: (Object error, StackTrace stackTrace) {
            _articleRequests.remove(articleId);
            throw error;
          },
        );

    _articleRequests[articleId] = request;
    return request;
  }

  Future<List<ArticleAuthor>> getAuthors() {
    final cached = _authorsCache;
    if (cached != null) return Future<List<ArticleAuthor>>.value(cached);
    final inFlight = _authorsRequest;
    if (inFlight != null) return inFlight;

    final request = _api.getAuthors().then(
      (authors) {
        _authorsRequest = null;
        _authorsCache = authors;
        return authors;
      },
      onError: (Object error, StackTrace stackTrace) {
        _authorsRequest = null;
        throw error;
      },
    );
    _authorsRequest = request;
    return request;
  }

  Future<ArticleFilterOptions> getFilterOptions() {
    final cached = _filterOptionsCache;
    if (cached != null) {
      return Future<ArticleFilterOptions>.value(cached);
    }
    final inFlight = _filterOptionsRequest;
    if (inFlight != null) return inFlight;

    final request = _api.getFilterOptions().then(
      (options) {
        _filterOptionsRequest = null;
        _filterOptionsCache = options;
        return options;
      },
      onError: (Object error, StackTrace stackTrace) {
        _filterOptionsRequest = null;
        throw error;
      },
    );
    _filterOptionsRequest = request;
    return request;
  }

  Future<Set<String>> getSavedArticleIds() {
    if (_savedArticlesLoaded) {
      return Future<Set<String>>.value(
        Set<String>.unmodifiable(_savedArticleIds),
      );
    }
    final inFlight = _savedArticlesRequest;
    if (inFlight != null) return inFlight;

    final request = _loadSavedArticleIds().then(
      (value) {
        _savedArticlesRequest = null;
        return Set<String>.unmodifiable(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        _savedArticlesRequest = null;
        throw error;
      },
    );
    _savedArticlesRequest = request;
    return request;
  }

  Future<bool> isArticleSaved(String articleId) async {
    await getSavedArticleIds();
    return _savedArticleIds.contains(articleId);
  }

  Future<bool> setArticleSaved(String articleId, bool saved) async {
    await getSavedArticleIds();
    final changed =
        saved
            ? _savedArticleIds.add(articleId)
            : _savedArticleIds.remove(articleId);
    if (!changed) return saved;
    await _persistSavedArticleIds();
    return saved;
  }

  Future<bool> toggleArticleSaved(String articleId) async {
    final currentlySaved = await isArticleSaved(articleId);
    return setArticleSaved(articleId, !currentlySaved);
  }

  Future<Article> createArticle(ArticleInput input) async {
    if (!canCreate) {
      throw StateError('Current role is not allowed to create articles.');
    }
    final article = await _api.createArticle(
      input: input,
      authorId: currentUserId,
    );
    _articleCache[article.id] = article;
    _invalidateDerivedCaches();
    return article;
  }

  Future<Article> updateArticle({
    required Article existing,
    required ArticleInput input,
  }) async {
    if (!canEdit(existing)) {
      throw StateError('Current role is not allowed to edit this article.');
    }
    final article = await _api.updateArticle(
      articleId: existing.id,
      input: input,
    );
    _articleCache[article.id] = article;
    _invalidateDerivedCaches();
    return article;
  }

  Future<void> deleteArticle(Article article) async {
    await archiveArticle(article);
  }

  Future<void> archiveArticle(Article article) async {
    if (!canArchive(article)) {
      throw StateError('Current role is not allowed to archive this article.');
    }
    await _api.deleteArticle(article.id);
    _articleCache.remove(article.id);
    if (_savedArticleIds.remove(article.id)) {
      await _persistSavedArticleIds();
    }
    _invalidateDerivedCaches();
  }

  Future<Set<String>> _loadSavedArticleIds() async {
    _savedArticlesLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final values =
          prefs.getStringList(_savedArticlesStorageKey) ?? const <String>[];
      _savedArticleIds
        ..clear()
        ..addAll(
          values
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty),
        );
    } catch (_) {
      _savedArticleIds.clear();
    }
    return _savedArticleIds;
  }

  Future<void> _persistSavedArticleIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = _savedArticleIds.toList(growable: false)..sort();
      await prefs.setStringList(_savedArticlesStorageKey, values);
    } catch (_) {
      // Non-fatal persistence failure.
    }
  }

  ArticlesQuery _scopedQuery(ArticlesQuery query) {
    return query.copyWith(
      includeDrafts:
          currentRole == AppUserRole.admin || currentRole == AppUserRole.coach,
    );
  }

  String _pageCacheKey(ArticlesQuery query) {
    String encodeSet(Set<String> values) {
      final normalized = values.toList()..sort();
      return normalized.join('|');
    }

    return <String>[
      '${query.page}',
      '${query.limit}',
      query.searchTerm.trim().toLowerCase(),
      query.sort.name,
      encodeSet(query.tagFilters),
      encodeSet(query.authorFilters),
      encodeSet(query.machineFilters),
      encodeSet(query.muscleFilters),
      encodeSet(query.categoryFilters),
      '${query.includeDrafts}',
    ].join('::');
  }

  void _seedArticleCache(List<Article> articles) {
    for (final article in articles) {
      _articleCache[article.id] = article;
    }
  }

  void _invalidateDerivedCaches() {
    _pageCache.clear();
    _pageRequests.clear();
    _filterOptionsCache = null;
    _filterOptionsRequest = null;
  }
}
