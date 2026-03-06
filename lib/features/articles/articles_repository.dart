import 'package:lift/features/articles/firebase_articles_api.dart';
import 'package:lift/features/articles/in_memory_articles_api.dart';
import 'package:lift/features/articles/local_persistent_articles_api.dart';
import 'package:lift/shared/models/article.dart';
import 'package:lift/shared/services/articles_api.dart';

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

  final ArticlesApi _api;

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

  Future<ArticlesPage> getArticles(ArticlesQuery query) {
    final scoped = query.copyWith(
      includeDrafts:
          currentRole == AppUserRole.admin || currentRole == AppUserRole.coach,
    );
    return _api.getArticles(scoped);
  }

  Future<Article?> getArticleById(String articleId) {
    return _api.getArticleById(articleId);
  }

  Future<List<ArticleAuthor>> getAuthors() => _api.getAuthors();

  Future<ArticleFilterOptions> getFilterOptions() => _api.getFilterOptions();

  Future<Article> createArticle(ArticleInput input) async {
    if (!canCreate) {
      throw StateError('Current role is not allowed to create articles.');
    }
    return _api.createArticle(input: input, authorId: currentUserId);
  }

  Future<Article> updateArticle({
    required Article existing,
    required ArticleInput input,
  }) async {
    if (!canEdit(existing)) {
      throw StateError('Current role is not allowed to edit this article.');
    }
    return _api.updateArticle(articleId: existing.id, input: input);
  }

  Future<void> deleteArticle(Article article) async {
    if (!canDelete(article)) {
      throw StateError('Current role is not allowed to delete this article.');
    }
    await _api.deleteArticle(article.id);
  }
}
