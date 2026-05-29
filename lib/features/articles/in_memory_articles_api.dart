import 'dart:math' as math;

import 'package:lift/shared/models/article.dart';
import 'package:lift/shared/services/articles_api.dart';

// Real fitness images for preview.
const String _kImgSquat =
    'https://images.pexels.com/photos/4498606/pexels-photo-4498606.jpeg?auto=compress&cs=tinysrgb&w=800';
const String _kImgBack =
    'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400';
const String _kImgGym =
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400';
const String _kImgRecovery =
    'https://images.pexels.com/photos/4324020/pexels-photo-4324020.jpeg?auto=compress&cs=tinysrgb&w=800';
const String _kImgCardio =
    'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400';
const String _kImgTechnique =
    'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=400';
const String _kImgKettlebell =
    'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=400';

class InMemoryArticlesApi extends ArticlesApi {
  InMemoryArticlesApi({
    List<ArticleAuthor>? seedAuthors,
    List<Article>? seedArticles,
  }) : _authors = seedAuthors ?? _defaultAuthors,
       _articles = seedArticles ?? _defaultArticles;

  final List<ArticleAuthor> _authors;
  final List<Article> _articles;

  @override
  Future<ArticlesPage> getArticles(ArticlesQuery query) async {
    final normalizedSearch = query.searchTerm.trim().toLowerCase();
    final visible = _articles
      .where((article) {
        if (!query.includeDrafts && article.status != ArticleStatus.published) {
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
        final inTitle = article.title.toLowerCase().contains(normalizedSearch);
        final inSummary = article.summary.toLowerCase().contains(
          normalizedSearch,
        );
        final inTags = article.tags.any(
          (tag) => tag.toLowerCase().contains(normalizedSearch),
        );
        return inTitle || inSummary || inTags;
      })
      .toList(growable: false)..sort((a, b) {
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

    final total = visible.length;
    final totalPages = math.max(1, (total / query.limit).ceil());
    final safePage = query.page.clamp(1, totalPages);
    final start = (safePage - 1) * query.limit;
    final end = math.min(total, start + query.limit);
    final data =
        start >= total
            ? const <Article>[]
            : visible.sublist(start, end).toList(growable: false);

    return ArticlesPage(
      data: data,
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

  @override
  Future<Article?> getArticleById(String articleId) async {
    for (final article in _articles) {
      if (article.id == articleId) return article;
    }
    return null;
  }

  @override
  Future<List<ArticleAuthor>> getAuthors() async {
    return List<ArticleAuthor>.from(_authors);
  }

  @override
  Future<ArticleFilterOptions> getFilterOptions() async {
    final tags = <String>{};
    final machineIds = <String>{};
    final muscleGroups = <String>{};
    final categories = <String>{};

    for (final article in _articles) {
      tags.addAll(article.tags);
      machineIds.addAll(article.machineIds);
      muscleGroups.addAll(article.muscleGroups);
      categories.addAll(article.categories);
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
    final id = 'art_${now.microsecondsSinceEpoch}';
    final article = Article(
      id: id,
      title: input.title.trim(),
      summary: input.summary.trim(),
      content: input.content.trim(),
      imageUrl: input.imageUrl?.trim().isEmpty == true ? null : input.imageUrl,
      authorId: authorId,
      tags: _dedupe(input.tags),
      machineIds: _dedupe(input.machineIds),
      muscleGroups: _dedupe(input.muscleGroups),
      categories: _dedupe(input.categories),
      publishedAt: now,
      updatedAt: now,
      status: input.status,
    );
    _articles.insert(0, article);
    return article;
  }

  @override
  Future<Article> updateArticle({
    required String articleId,
    required ArticleInput input,
  }) async {
    final index = _articles.indexWhere((article) => article.id == articleId);
    if (index == -1) {
      throw StateError('Article not found');
    }
    final current = _articles[index];
    final now = DateTime.now();
    final updated = current.copyWith(
      title: input.title.trim(),
      summary: input.summary.trim(),
      content: input.content.trim(),
      imageUrl: input.imageUrl?.trim().isEmpty == true ? null : input.imageUrl,
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
    _articles[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteArticle(String articleId) async {
    final index = _articles.indexWhere((article) => article.id == articleId);
    if (index == -1) return;
    _articles[index] = _articles[index].copyWith(
      status: ArticleStatus.archived,
      updatedAt: DateTime.now(),
    );
  }

  List<String> _dedupe(List<String> values) {
    final normalized =
        values
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return normalized;
  }
}

const List<ArticleAuthor> _defaultAuthors = <ArticleAuthor>[
  ArticleAuthor(id: 'coach_ari', name: 'Ari Mokoena', roleLabel: 'Coach'),
  ArticleAuthor(id: 'coach_nia', name: 'Nia Peters', roleLabel: 'Head Coach'),
  ArticleAuthor(id: 'owner_lift', name: 'LIFT Team', roleLabel: 'Gym Admin'),
];

final List<Article> _defaultArticles = <Article>[
  Article(
    id: 'art_hack_squat_safety',
    title: 'How to Use the Hack Squat Safely',
    summary:
        'Set your stance, brace your trunk, and control depth to maximize quads while protecting your knees.',
    content:
        'Start with your feet shoulder-width apart and keep your full foot planted.\n\nDrive through mid-foot, maintain a neutral spine, and avoid bouncing at the bottom. Tempo matters more than load in early progression.\n\nProgramming tip: pair Hack Squat with hamstring curls for a balanced lower-body block.',
    imageUrl: _kImgSquat,
    authorId: 'coach_nia',
    tags: ['quads', 'machine', 'technique'],
    machineIds: ['hack-squat'],
    muscleGroups: ['Quads', 'Glutes'],
    categories: ['Technique'],
    publishedAt: DateTime(2026, 2, 28, 10),
    updatedAt: DateTime(2026, 2, 28, 10),
    status: ArticleStatus.published,
  ),
  Article(
    id: 'art_lat_pulldown_form',
    title: 'Lat Pulldown Form Checklist',
    summary:
        'A quick checklist to keep your pulldowns in your back and out of your elbows.',
    content:
        'Think elbows toward your back pockets. Keep ribs stacked and avoid over-leaning.\n\nUse full control on the eccentric. If grip fails first, use straps so lats stay the limiting factor.\n\nThis setup maps directly to machine_lat_pulldown_01 in your gym.',
    imageUrl: _kImgBack,
    authorId: 'coach_ari',
    tags: ['back', 'form', 'machine'],
    machineIds: ['machine_lat_pulldown_01'],
    muscleGroups: ['Back', 'Biceps'],
    categories: ['Technique'],
    publishedAt: DateTime(2026, 3, 1, 9, 30),
    updatedAt: DateTime(2026, 3, 1, 9, 30),
    status: ArticleStatus.published,
  ),
  Article(
    id: 'art_pull_day_beginner',
    title: 'Beginner Pull Day (Gym Floor Version)',
    summary:
        'A complete pull day built around your gym machines with realistic rest targets.',
    content:
        '1) Lat Pulldown\n2) Seated Row\n3) Dumbbell Rear Delt Fly\n\nKeep rest between 75-120 seconds. Track reps first, then progress weight in 2.5kg jumps.',
    imageUrl: _kImgGym,
    authorId: 'owner_lift',
    tags: ['pull day', 'beginner', 'programming'],
    machineIds: ['machine_lat_pulldown_01'],
    muscleGroups: ['Back', 'Biceps', 'Rear Delts'],
    categories: ['Workout Plan'],
    publishedAt: DateTime(2026, 3, 2, 8),
    updatedAt: DateTime(2026, 3, 2, 8),
    status: ArticleStatus.published,
  ),
  Article(
    id: 'art_recovery_signals',
    title: 'Recovery Signals to Watch This Week',
    summary: 'How to adjust load based on sleep, soreness, and readiness data.',
    content:
        'If resting heart rate trends up and sleep drops below baseline, reduce session density for 48 hours.\n\nUse lighter warmups and lower RPE work until recovery metrics normalize.',
    imageUrl: _kImgRecovery,
    authorId: 'coach_nia',
    tags: ['recovery', 'sleep', 'readiness'],
    machineIds: const <String>[],
    muscleGroups: ['Full Body'],
    categories: ['Recovery'],
    publishedAt: DateTime(2026, 3, 3, 6, 45),
    updatedAt: DateTime(2026, 3, 3, 6, 45),
    status: ArticleStatus.published,
  ),
  Article(
    id: 'art_core_cardio_density',
    title: 'Core + Conditioning Density Progression',
    summary: 'Raise work density safely while keeping movement quality high.',
    content:
        'Use blocks of 8-12 minutes and keep transitions short.\n\nTrack total rounds completed, then increase round quality before adding more time.',
    imageUrl: _kImgCardio,
    authorId: 'coach_ari',
    tags: ['conditioning', 'core', 'progression'],
    machineIds: const <String>[],
    muscleGroups: ['Core'],
    categories: ['Conditioning'],
    publishedAt: DateTime(2026, 3, 4, 7, 20),
    updatedAt: DateTime(2026, 3, 4, 7, 20),
    status: ArticleStatus.published,
  ),
  Article(
    id: 'art_coach_note_week',
    title: 'Coach Notes: Technique Focus This Week',
    summary: 'Three technical standards we are enforcing on the gym floor.',
    content:
        '1) Controlled eccentrics on machine presses.\n2) Full lockout and scapular movement on pulls.\n3) Bracing before every heavy rep.',
    imageUrl: _kImgTechnique,
    authorId: 'owner_lift',
    tags: ['coach tips', 'technique'],
    machineIds: const <String>[],
    muscleGroups: ['Full Body'],
    categories: ['Coach Notes'],
    publishedAt: DateTime(2026, 3, 4, 16),
    updatedAt: DateTime(2026, 3, 4, 16),
    status: ArticleStatus.published,
  ),
  Article(
    id: 'art_draft_private',
    title: 'Draft: New Shoulder Prep Sequence',
    summary: 'Internal coach draft for warmup sequencing.',
    content:
        'This draft is intentionally unpublished and should only appear to non-member roles.',
    imageUrl: _kImgKettlebell,
    authorId: 'coach_nia',
    tags: ['shoulders', 'warmup'],
    machineIds: const <String>[],
    muscleGroups: ['Shoulders'],
    categories: ['Draft'],
    publishedAt: DateTime(2026, 3, 5, 11),
    updatedAt: DateTime(2026, 3, 5, 11),
    status: ArticleStatus.draft,
  ),
];
