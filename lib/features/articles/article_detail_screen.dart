import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/features/articles/article_editor_screen.dart';
import 'package:lift/features/articles/articles_repository.dart';
import 'package:lift/features/articles/widgets/article_body_view.dart';
import 'package:lift/shared/models/article.dart';
import 'package:lift/shared/widgets/lift_dialogs.dart';
import 'package:lift/shared/widgets/lift_island_header.dart';
import 'package:lift/shared/widgets/lift_menu_sheet.dart';
import 'package:lift/shared/widgets/surfaces.dart';

const String _kArticlePlaceholderImage =
    'https://blocks.astratic.com/img/general-img-landscape.png';

enum _ArticleHeaderMenuAction { edit, archive }

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({
    super.key,
    required this.articleId,
    required this.repository,
    required this.machineSuggestions,
  });

  final String articleId;
  final ArticlesRepository repository;
  final List<String> machineSuggestions;

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  Article? _article;
  Map<String, ArticleAuthor> _authors = const {};
  bool _isLoading = true;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final article = await widget.repository.getArticleById(widget.articleId);
    final authors = await widget.repository.getAuthors();
    if (!mounted) return;
    setState(() {
      _article = article;
      _authors = {for (final author in authors) author.id: author};
      _isLoading = false;
    });
  }

  Future<void> _edit() async {
    final article = _article;
    if (article == null) return;
    final input = await Navigator.of(context).push<ArticleInput>(
      MaterialPageRoute(
        builder:
            (_) => ArticleEditorScreen(
              initialArticle: article,
              machineSuggestions: widget.machineSuggestions,
            ),
      ),
    );
    if (input == null) return;
    await widget.repository.updateArticle(existing: article, input: input);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Article updated')));
  }

  Future<void> _delete() async {
    final article = _article;
    if (article == null) return;
    final confirmed = await showLiftConfirmDialog(
      context: context,
      title: 'Delete article?',
      message: 'This will archive the article and hide it from members.',
      confirmLabel: 'Archive',
      confirmColor: Colors.red.shade600,
    );
    if (confirmed != true) return;
    await widget.repository.deleteArticle(article);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _showHeaderActions() async {
    final action = await showModalBottomSheet<_ArticleHeaderMenuAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              10 + MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: LiftMenuSheet(
              title: 'Article options',
              subtitle: _article?.title,
              children: [
                LiftMenuActionTile(
                  icon: const Icon(Icons.edit_outlined),
                  title: 'Edit article',
                  onTap:
                      () => Navigator.of(
                        sheetContext,
                      ).pop(_ArticleHeaderMenuAction.edit),
                ),
                const SizedBox(height: 8),
                LiftMenuActionTile(
                  icon: const Icon(Icons.delete_outline),
                  title: 'Archive article',
                  accent: Colors.red.shade600,
                  onTap:
                      () => Navigator.of(
                        sheetContext,
                      ).pop(_ArticleHeaderMenuAction.archive),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _ArticleHeaderMenuAction.edit:
        await _edit();
        break;
      case _ArticleHeaderMenuAction.archive:
        await _delete();
        break;
    }
  }

  Widget _chip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kAccentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kAccentColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: kAccentColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = _article;
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kAccentColor)),
      );
    }
    if (article == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F8),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                LiftIslandHeader(
                  title: 'ARTICLE',
                  leading: LiftIslandHeaderAction(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const Expanded(child: Center(child: Text('Article not found'))),
              ],
            ),
          ),
        ),
      );
    }
    final author = _authors[article.authorId];
    final canEdit = widget.repository.canEdit(article);
    final publishedLabel = _dateLabel(article.publishedAt);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: LiftIslandHeader(
                title: 'ARTICLE',
                leading: LiftIslandHeaderAction(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                trailing:
                    canEdit
                        ? LiftIslandHeaderAction(
                          onTap: _showHeaderActions,
                          child: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        )
                        : null,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          article.imageUrl ?? _kArticlePlaceholderImage,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_outlined),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.summary,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.35,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionBoundary(
                      borderRadius: 14,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: kAccentColor.withValues(
                              alpha: 0.14,
                            ),
                            child: Text(
                              (author?.name ?? 'Lift')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: kAccentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  author?.name ?? 'LIFT',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${author?.roleLabel ?? 'Coach'} • $publishedLabel',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _bookmarked = !_bookmarked);
                            },
                            icon: Icon(
                              _bookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_outline,
                              color: kAccentColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Share coming soon'),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.share_outlined,
                              color: kAccentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...article.tags.map(_chip),
                        ...article.categories.map(_chip),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SectionBoundary(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(14),
                      child: ArticleBodyView(content: article.content),
                    ),
                    if (article.machineIds.isNotEmpty ||
                        article.muscleGroups.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SectionBoundary(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Related',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (article.machineIds.isNotEmpty)
                                Text(
                                  'Machines: ${article.machineIds.join(', ')}',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              if (article.muscleGroups.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Muscles: ${article.muscleGroups.join(', ')}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final month =
        <String>[
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ][date.month - 1];
    return '${date.day} $month ${date.year}';
  }
}
