import 'package:lift/shared/models/article.dart';

class ArticleApiEndpoints {
  static const String base = '/api/v1';
  static const String articles = '$base/articles';
  static const String authors = '$base/authors';

  static String articleById(String articleId) => '$articles/$articleId';
}

abstract class ArticlesApi {
  const ArticlesApi();

  Future<ArticlesPage> getArticles(ArticlesQuery query);

  Future<Article?> getArticleById(String articleId);

  Future<List<ArticleAuthor>> getAuthors();

  Future<ArticleFilterOptions> getFilterOptions();

  Future<Article> createArticle({
    required ArticleInput input,
    required String authorId,
  });

  Future<Article> updateArticle({
    required String articleId,
    required ArticleInput input,
  });

  Future<void> deleteArticle(String articleId);
}
