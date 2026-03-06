enum ArticleStatus { draft, published, archived }

extension ArticleStatusX on ArticleStatus {
  String get wireValue {
    switch (this) {
      case ArticleStatus.draft:
        return 'draft';
      case ArticleStatus.published:
        return 'published';
      case ArticleStatus.archived:
        return 'archived';
    }
  }

  String get label {
    switch (this) {
      case ArticleStatus.draft:
        return 'Draft';
      case ArticleStatus.published:
        return 'Published';
      case ArticleStatus.archived:
        return 'Archived';
    }
  }

  static ArticleStatus fromWire(String value) {
    switch (value.trim().toLowerCase()) {
      case 'draft':
        return ArticleStatus.draft;
      case 'archived':
        return ArticleStatus.archived;
      case 'published':
      default:
        return ArticleStatus.published;
    }
  }
}

enum ArticleSort { latest, recommended }

extension ArticleSortX on ArticleSort {
  String get label {
    switch (this) {
      case ArticleSort.latest:
        return 'Latest';
      case ArticleSort.recommended:
        return 'Recommended';
    }
  }
}

enum AppUserRole { member, coach, admin }

class ArticleAuthor {
  const ArticleAuthor({
    required this.id,
    required this.name,
    required this.roleLabel,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String roleLabel;
  final String? imageUrl;
}

class Article {
  const Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.authorId,
    required this.tags,
    required this.machineIds,
    required this.muscleGroups,
    required this.categories,
    required this.publishedAt,
    required this.updatedAt,
    required this.status,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String summary;
  final String content;
  final String? imageUrl;
  final String authorId;
  final List<String> tags;
  final List<String> machineIds;
  final List<String> muscleGroups;
  final List<String> categories;
  final DateTime publishedAt;
  final DateTime updatedAt;
  final ArticleStatus status;

  Article copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? imageUrl,
    String? authorId,
    List<String>? tags,
    List<String>? machineIds,
    List<String>? muscleGroups,
    List<String>? categories,
    DateTime? publishedAt,
    DateTime? updatedAt,
    ArticleStatus? status,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      tags: tags ?? this.tags,
      machineIds: machineIds ?? this.machineIds,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      categories: categories ?? this.categories,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}

class ArticleInput {
  const ArticleInput({
    required this.title,
    required this.summary,
    required this.content,
    required this.tags,
    required this.machineIds,
    required this.muscleGroups,
    required this.categories,
    required this.status,
    this.imageUrl,
  });

  final String title;
  final String summary;
  final String content;
  final String? imageUrl;
  final List<String> tags;
  final List<String> machineIds;
  final List<String> muscleGroups;
  final List<String> categories;
  final ArticleStatus status;
}

class ArticlesQuery {
  const ArticlesQuery({
    this.page = 1,
    this.limit = 10,
    this.searchTerm = '',
    this.sort = ArticleSort.latest,
    this.tagFilters = const <String>{},
    this.authorFilters = const <String>{},
    this.machineFilters = const <String>{},
    this.muscleFilters = const <String>{},
    this.categoryFilters = const <String>{},
    this.includeDrafts = false,
  });

  final int page;
  final int limit;
  final String searchTerm;
  final ArticleSort sort;
  final Set<String> tagFilters;
  final Set<String> authorFilters;
  final Set<String> machineFilters;
  final Set<String> muscleFilters;
  final Set<String> categoryFilters;
  final bool includeDrafts;

  ArticlesQuery copyWith({
    int? page,
    int? limit,
    String? searchTerm,
    ArticleSort? sort,
    Set<String>? tagFilters,
    Set<String>? authorFilters,
    Set<String>? machineFilters,
    Set<String>? muscleFilters,
    Set<String>? categoryFilters,
    bool? includeDrafts,
  }) {
    return ArticlesQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      searchTerm: searchTerm ?? this.searchTerm,
      sort: sort ?? this.sort,
      tagFilters: tagFilters ?? this.tagFilters,
      authorFilters: authorFilters ?? this.authorFilters,
      machineFilters: machineFilters ?? this.machineFilters,
      muscleFilters: muscleFilters ?? this.muscleFilters,
      categoryFilters: categoryFilters ?? this.categoryFilters,
      includeDrafts: includeDrafts ?? this.includeDrafts,
    );
  }
}

class ArticlesPagination {
  const ArticlesPagination({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.total,
  });

  final int page;
  final int limit;
  final int totalPages;
  final int total;

  bool get hasNextPage => page < totalPages;
}

class ArticlesPage {
  const ArticlesPage({required this.data, required this.pagination});

  final List<Article> data;
  final ArticlesPagination pagination;
}

class ArticleFilterOptions {
  const ArticleFilterOptions({
    required this.tags,
    required this.machineIds,
    required this.muscleGroups,
    required this.categories,
  });

  final List<String> tags;
  final List<String> machineIds;
  final List<String> muscleGroups;
  final List<String> categories;
}
