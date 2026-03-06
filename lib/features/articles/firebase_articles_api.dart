import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lift/shared/models/article.dart';
import 'package:lift/shared/services/articles_api.dart';

class FirebaseArticlesApi extends ArticlesApi {
  FirebaseArticlesApi._({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static FirebaseArticlesApi? tryCreate() {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseArticlesApi._();
    } catch (_) {
      return null;
    }
  }

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _articlesCollection =>
      _firestore.collection('api').doc('v1').collection('articles');

  CollectionReference<Map<String, dynamic>> get _authorsCollection =>
      _firestore.collection('api').doc('v1').collection('authors');

  @override
  Future<ArticlesPage> getArticles(ArticlesQuery query) async {
    final snapshot =
        await _articlesCollection
            .orderBy('publishedAt', descending: true)
            .limit(500)
            .get();
    final all = snapshot.docs
        .map(_articleFromDocument)
        .whereType<Article>()
        .toList(growable: false);
    final filtered = _filterArticles(all, query);
    final sorted = _sortArticles(filtered, query);
    return _paginate(sorted, query);
  }

  @override
  Future<Article?> getArticleById(String articleId) async {
    final doc = await _articlesCollection.doc(articleId).get();
    return _articleFromDocument(doc);
  }

  @override
  Future<List<ArticleAuthor>> getAuthors() async {
    final snapshot = await _authorsCollection.get();
    return snapshot.docs
      .map((doc) => _authorFromData(doc.id, doc.data()))
      .whereType<ArticleAuthor>()
      .toList(growable: false)..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<ArticleFilterOptions> getFilterOptions() async {
    final snapshot =
        await _articlesCollection
            .where(
              'status',
              whereIn: <String>[
                ArticleStatus.published.wireValue,
                ArticleStatus.draft.wireValue,
              ],
            )
            .limit(500)
            .get();
    final tags = <String>{};
    final machineIds = <String>{};
    final muscleGroups = <String>{};
    final categories = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      tags.addAll(_stringList(data['tags']));
      machineIds.addAll(_stringList(data['machineIds']));
      muscleGroups.addAll(_stringList(data['muscleGroups']));
      categories.addAll(_stringList(data['categories']));
    }
    final sortedTags = tags.toList()..sort();
    final sortedMachines = machineIds.toList()..sort();
    final sortedMuscles = muscleGroups.toList()..sort();
    final sortedCategories = categories.toList()..sort();
    return ArticleFilterOptions(
      tags: sortedTags,
      machineIds: sortedMachines,
      muscleGroups: sortedMuscles,
      categories: sortedCategories,
    );
  }

  @override
  Future<Article> createArticle({
    required ArticleInput input,
    required String authorId,
  }) async {
    final now = DateTime.now();
    final doc = _articlesCollection.doc();
    final article = Article(
      id: doc.id,
      title: input.title.trim(),
      summary: input.summary.trim(),
      content: input.content.trim(),
      imageUrl: _nullableTrim(input.imageUrl),
      authorId: authorId,
      tags: _dedupe(input.tags),
      machineIds: _dedupe(input.machineIds),
      muscleGroups: _dedupe(input.muscleGroups),
      categories: _dedupe(input.categories),
      publishedAt: now,
      updatedAt: now,
      status: input.status,
    );
    await doc.set(_articleToData(article));
    return article;
  }

  @override
  Future<Article> updateArticle({
    required String articleId,
    required ArticleInput input,
  }) async {
    final current = await getArticleById(articleId);
    if (current == null) {
      throw StateError('Article not found');
    }
    final now = DateTime.now();
    final updated = current.copyWith(
      title: input.title.trim(),
      summary: input.summary.trim(),
      content: input.content.trim(),
      imageUrl: _nullableTrim(input.imageUrl),
      tags: _dedupe(input.tags),
      machineIds: _dedupe(input.machineIds),
      muscleGroups: _dedupe(input.muscleGroups),
      categories: _dedupe(input.categories),
      status: input.status,
      updatedAt: now,
      publishedAt:
          current.status != ArticleStatus.published &&
                  input.status == ArticleStatus.published
              ? now
              : current.publishedAt,
    );
    await _articlesCollection
        .doc(articleId)
        .set(_articleToData(updated), SetOptions(merge: true));
    return updated;
  }

  @override
  Future<void> deleteArticle(String articleId) async {
    await _articlesCollection.doc(articleId).set({
      'status': ArticleStatus.archived.wireValue,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Article? _articleFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final title = _asString(data['title']);
    final summary = _asString(data['summary']);
    final content = _asString(data['content']);
    final authorId = _asString(data['authorId']);
    if (title == null ||
        summary == null ||
        content == null ||
        authorId == null) {
      return null;
    }
    return Article(
      id: doc.id,
      title: title,
      summary: summary,
      content: content,
      imageUrl: _asString(data['imageUrl']),
      authorId: authorId,
      tags: _stringList(data['tags']),
      machineIds: _stringList(data['machineIds']),
      muscleGroups: _stringList(data['muscleGroups']),
      categories: _stringList(data['categories']),
      publishedAt: _timestampToDate(
        data['publishedAt'],
        fallback: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      updatedAt: _timestampToDate(data['updatedAt'], fallback: DateTime.now()),
      status: ArticleStatusX.fromWire(_asString(data['status']) ?? 'published'),
    );
  }

  Map<String, dynamic> _articleToData(Article article) {
    return {
      'title': article.title,
      'summary': article.summary,
      'content': article.content,
      'imageUrl': article.imageUrl,
      'authorId': article.authorId,
      'tags': article.tags,
      'machineIds': article.machineIds,
      'muscleGroups': article.muscleGroups,
      'categories': article.categories,
      'publishedAt': Timestamp.fromDate(article.publishedAt),
      'updatedAt': Timestamp.fromDate(article.updatedAt),
      'status': article.status.wireValue,
    };
  }

  ArticleAuthor? _authorFromData(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final name = _asString(data['name']);
    final roleLabel = _asString(data['roleLabel']);
    if (name == null || roleLabel == null) return null;
    return ArticleAuthor(
      id: id,
      name: name,
      roleLabel: roleLabel,
      imageUrl: _asString(data['imageUrl']),
    );
  }

  List<Article> _filterArticles(List<Article> all, ArticlesQuery query) {
    final normalizedSearch = query.searchTerm.trim().toLowerCase();
    return all
        .where((article) {
          if (!query.includeDrafts &&
              article.status != ArticleStatus.published) {
            return false;
          }
          if (query.tagFilters.isNotEmpty &&
              !article.tags.any(query.tagFilters.contains)) {
            return false;
          }
          if (query.authorFilters.isNotEmpty &&
              !query.authorFilters.contains(article.authorId)) {
            return false;
          }
          if (query.machineFilters.isNotEmpty &&
              !article.machineIds.any(query.machineFilters.contains)) {
            return false;
          }
          if (query.muscleFilters.isNotEmpty &&
              !article.muscleGroups.any(query.muscleFilters.contains)) {
            return false;
          }
          if (query.categoryFilters.isNotEmpty &&
              !article.categories.any(query.categoryFilters.contains)) {
            return false;
          }
          if (normalizedSearch.isEmpty) return true;
          final inTitle = article.title.toLowerCase().contains(
            normalizedSearch,
          );
          final inSummary = article.summary.toLowerCase().contains(
            normalizedSearch,
          );
          final inTags = article.tags.any(
            (tag) => tag.toLowerCase().contains(normalizedSearch),
          );
          return inTitle || inSummary || inTags;
        })
        .toList(growable: false);
  }

  List<Article> _sortArticles(List<Article> values, ArticlesQuery query) {
    final sorted = List<Article>.from(values);
    sorted.sort((a, b) {
      switch (query.sort) {
        case ArticleSort.latest:
          return b.publishedAt.compareTo(a.publishedAt);
        case ArticleSort.recommended:
          final aScore = _recommendationScore(a, query);
          final bScore = _recommendationScore(b, query);
          final byScore = bScore.compareTo(aScore);
          if (byScore != 0) return byScore;
          return b.publishedAt.compareTo(a.publishedAt);
      }
    });
    return sorted;
  }

  ArticlesPage _paginate(List<Article> values, ArticlesQuery query) {
    final total = values.length;
    final totalPages = math.max(1, (total / query.limit).ceil());
    final safePage = query.page.clamp(1, totalPages);
    final start = (safePage - 1) * query.limit;
    final end = math.min(total, start + query.limit);
    final pageData =
        start >= total
            ? const <Article>[]
            : values.sublist(start, end).toList(growable: false);
    return ArticlesPage(
      data: pageData,
      pagination: ArticlesPagination(
        page: safePage,
        limit: query.limit,
        totalPages: totalPages,
        total: total,
      ),
    );
  }

  int _recommendationScore(Article article, ArticlesQuery query) {
    var score = 0;
    score += article.tags.length;
    score += article.machineIds.length * 2;
    score += article.muscleGroups.length;
    score += article.categories.length;
    if (query.tagFilters.isNotEmpty &&
        article.tags.any(query.tagFilters.contains)) {
      score += 7;
    }
    if (query.muscleFilters.isNotEmpty &&
        article.muscleGroups.any(query.muscleFilters.contains)) {
      score += 7;
    }
    if (query.machineFilters.isNotEmpty &&
        article.machineIds.any(query.machineFilters.contains)) {
      score += 7;
    }
    return score;
  }

  List<String> _dedupe(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  String? _nullableTrim(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => _asString(item))
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  DateTime _timestampToDate(dynamic value, {required DateTime fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return fallback;
  }
}
