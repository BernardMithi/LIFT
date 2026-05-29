import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/icons/mynaui_glyphs.dart';
import 'package:lift/shared/icons/mynaui_icon.dart';
import 'package:lift/features/articles/article_detail_screen.dart';
import 'package:lift/features/articles/article_editor_screen.dart';
import 'package:lift/features/articles/articles_repository.dart';
import 'package:lift/features/articles/widgets/article_image_view.dart';
import 'package:lift/shared/models/article.dart';
import 'package:lift/shared/widgets/lift_dialogs.dart';
import 'package:lift/shared/widgets/lift_island_header.dart';
import 'package:lift/shared/widgets/lift_menu_sheet.dart';
import 'package:lift/shared/widgets/lift_list_pagination.dart';
import 'package:lift/shared/widgets/surfaces.dart';

const String _kArticlePlaceholderImage =
    'https://blocks.astratic.com/img/general-img-landscape.png';

enum _GuidesTab { featured, recent, saved, yourArticles }

const int _kEmbeddedArticlePageSize = 5;
const int _kSavedArticlesFetchLimit = 30;
const double _kEmbeddedSpotlightThumbnailSize = 82.0;
const double _kEmbeddedSpotlightTileVerticalPadding = 8.0;
const double _kEmbeddedSpotlightRowHeight =
    _kEmbeddedSpotlightThumbnailSize +
    (_kEmbeddedSpotlightTileVerticalPadding * 2);

enum _ArticlePillKind { status, tag }

class _ArticleLabelToken {
  const _ArticleLabelToken({required this.label, required this.kind});

  final String label;
  final _ArticlePillKind kind;
}

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({
    super.key,
    this.extraBottomInset = 0,
    this.repository,
    this.onLeadingTap,
  });

  final double extraBottomInset;
  final ArticlesRepository? repository;
  final VoidCallback? onLeadingTap;

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  late final ArticlesRepository _repository;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;
  List<Article> _articles = const [];
  List<Article> _featuredArticles = const [];
  List<ArticleAuthor> _authors = const [];
  ArticleFilterOptions _filterOptions = const ArticleFilterOptions(
    tags: <String>[],
    machineIds: <String>[],
    muscleGroups: <String>[],
    categories: <String>[],
  );

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isChangingPage = false;
  bool _hasNextPage = true;
  int _nextPage = 1;
  int _currentPage = 1;
  int _totalPages = 1;
  int _savedCurrentPage = 1;
  String _searchTerm = '';
  String? _error;

  _GuidesTab _tab = _GuidesTab.featured;
  final Set<String> _savedArticleIds = <String>{};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ArticlesRepository.instance;
    _scrollController.addListener(_onScroll);
    _seedFromCache();
    _syncSavedArticleIds();
    _loadInitial(silent: !_isLoading);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _seedFromCache() {
    _savedArticleIds
      ..clear()
      ..addAll(_repository.peekSavedArticleIds());
    final cachedAuthors = _repository.peekAuthors();
    final cachedFilters = _repository.peekFilterOptions();
    final cachedFeatured = _repository.peekArticles(
      _buildQuery(page: 1, tab: _GuidesTab.featured),
    );
    final cachedRecent = _repository.peekArticles(
      _buildQuery(page: 1, tab: _GuidesTab.recent),
    );

    if (cachedAuthors != null) {
      _authors = cachedAuthors;
    }
    if (cachedFilters != null) {
      _filterOptions = cachedFilters;
    }
    if (cachedFeatured != null) {
      _featuredArticles = cachedFeatured.data;
      _isLoading = false;
    }
    if (cachedRecent != null && _articles.isEmpty) {
      _articles = cachedRecent.data;
      _currentPage = cachedRecent.pagination.page;
      _totalPages = cachedRecent.pagination.totalPages;
      _nextPage = cachedRecent.pagination.page + 1;
      _hasNextPage = cachedRecent.pagination.hasNextPage;
    }
  }

  Future<void> _loadInitial({bool silent = false}) async {
    await _loadMetadata();
    await _refresh(silent: silent);
  }

  Future<void> _loadMetadata() async {
    final results = await Future.wait<Object>([
      _repository.getAuthors(),
      _repository.getFilterOptions(),
      _repository.getSavedArticleIds(),
    ]);
    final authors = results[0] as List<ArticleAuthor>;
    final options = results[1] as ArticleFilterOptions;
    final savedIds = results[2] as Set<String>;
    if (!mounted) return;
    setState(() {
      _authors = authors;
      _filterOptions = options;
      _savedArticleIds
        ..clear()
        ..addAll(savedIds);
    });
  }

  Future<void> _syncSavedArticleIds() async {
    final savedIds = await _repository.getSavedArticleIds();
    if (!mounted) return;
    setState(() {
      _savedArticleIds
        ..clear()
        ..addAll(savedIds);
    });
  }

  void _onScroll() {
    if (!_supportsInfiniteScrollForActiveTab) return;
    if (!_hasNextPage || _isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 220) {
      _loadMore();
    }
  }

  bool get _supportsInfiniteScrollForActiveTab =>
      _tab == _GuidesTab.yourArticles;

  List<Article> get _visibleArticles =>
      _tab == _GuidesTab.featured ? _featuredArticles : _articles;

  int _queryLimitForTab(_GuidesTab tab) {
    switch (tab) {
      case _GuidesTab.featured:
        return _kFeaturedSpotlightCount;
      case _GuidesTab.saved:
        return _kSavedArticlesFetchLimit;
      case _GuidesTab.recent:
      case _GuidesTab.yourArticles:
        return _kEmbeddedArticlePageSize;
    }
  }

  ArticlesQuery _buildQuery({required int page, _GuidesTab? tab}) {
    final activeTab = tab ?? _tab;
    return ArticlesQuery(
      page: page,
      limit: _queryLimitForTab(activeTab),
      searchTerm: _searchTerm,
      sort: ArticleSort.latest,
      authorFilters:
          activeTab == _GuidesTab.yourArticles
              ? {_repository.currentUserId}
              : const {},
    );
  }

  Future<void> _refresh({bool silent = false}) async {
    setState(() {
      if (!silent) _isLoading = true;
      _error = null;
      _isChangingPage = false;
      _savedCurrentPage = 1;
      if (_tab == _GuidesTab.recent) {
        _currentPage = 1;
        _totalPages = 1;
      }
      if (_tab == _GuidesTab.yourArticles) {
        _nextPage = 1;
        _hasNextPage = true;
      }
    });
    try {
      final page = await _repository.getArticles(_buildQuery(page: 1));
      if (!mounted) return;
      setState(() {
        if (_tab == _GuidesTab.featured) {
          _featuredArticles = page.data;
        } else {
          _articles = page.data;
        }
        _currentPage = page.pagination.page;
        _totalPages = page.pagination.totalPages;
        _nextPage = page.pagination.page + 1;
        _hasNextPage = page.pagination.hasNextPage;
        _isLoadingMore = false;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_supportsInfiniteScrollForActiveTab ||
        _isLoadingMore ||
        !_hasNextPage) {
      return;
    }
    setState(() => _isLoadingMore = true);
    try {
      final page = await _repository.getArticles(_buildQuery(page: _nextPage));
      if (!mounted) return;
      setState(() {
        _articles = <Article>[..._articles, ...page.data];
        _nextPage = page.pagination.page + 1;
        _hasNextPage = page.pagination.hasNextPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _goToPage(int page) async {
    if ((_tab != _GuidesTab.recent && _tab != _GuidesTab.yourArticles) ||
        _isChangingPage ||
        _isLoading ||
        page < 1 ||
        page > _totalPages ||
        page == _currentPage) {
      return;
    }
    setState(() => _isChangingPage = true);
    try {
      final response = await _repository.getArticles(
        _buildQuery(page: page, tab: _tab),
      );
      if (!mounted) return;
      setState(() {
        _articles = response.data;
        _currentPage = response.pagination.page;
        _totalPages = response.pagination.totalPages;
        _nextPage = response.pagination.page + 1;
        _hasNextPage = response.pagination.hasNextPage;
        _isChangingPage = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isChangingPage = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      final normalized = value.trim();
      if (normalized == _searchTerm) return;
      setState(() => _searchTerm = normalized);
      _refresh();
    });
  }

  Future<void> _editFromList(Article article) async {
    final input = await Navigator.of(context).push<ArticleInput>(
      MaterialPageRoute(
        builder:
            (_) => ArticleEditorScreen(
              initialArticle: article,
              machineSuggestions: _filterOptions.machineIds,
            ),
      ),
    );
    if (input == null) return;
    await _repository.updateArticle(existing: article, input: input);
    await _refresh();
  }

  Future<void> _archiveFromList(Article article) async {
    final confirmed = await showLiftConfirmDialog(
      context: context,
      title: 'Archive article?',
      message: 'This hides the article from member views.',
      confirmLabel: 'Archive',
      confirmColor: Colors.red.shade600,
    );
    if (confirmed != true) return;
    await _repository.archiveArticle(article);
    await _refresh();
  }

  Future<void> _openCreate() async {
    final input = await Navigator.of(context).push<ArticleInput>(
      MaterialPageRoute(
        builder:
            (_) => ArticleEditorScreen(
              machineSuggestions: _filterOptions.machineIds,
            ),
      ),
    );
    if (input == null) return;
    await _repository.createArticle(input);
    await _refresh();
  }

  Future<void> _openArticle(Article article) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (_) => ArticleDetailScreen(
              articleId: article.id,
              repository: _repository,
              machineSuggestions: _filterOptions.machineIds,
              initialArticle: article,
              initialAuthors: {
                for (final author in _authors) author.id: author,
              },
            ),
      ),
    );
    await _syncSavedArticleIds();
    if (!mounted) return;
    if (changed == true) {
      await _refresh();
    }
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

  @override
  Widget build(BuildContext context) {
    const islandTop = 16.0;

    /// Reserved height for search + tabs overlay (keep close to real SectionBoundary height).
    const searchBarBlockHeight = 114.0;

    /// Shared vertical rhythm between the top island, search block, and content island.
    const guidesContainerGap = 12.0;
    final screenBackgroundColor = Colors.grey.shade50;
    final searchAreaTop =
        islandTop + kLiftIslandHeaderHeight + guidesContainerGap;
    final searchBarBottom = searchAreaTop + searchBarBlockHeight;
    final listTopPadding = searchBarBottom + guidesContainerGap;
    final contentBottomPadding = guidesContainerGap + widget.extraBottomInset;
    return ColoredBox(
      color: screenBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  kPagePadding,
                  listTopPadding,
                  kPagePadding,
                  contentBottomPadding,
                ),
                // Tight height (not Align + width-only SizedBox) so embedded
                // Column + Expanded / ListView get bounded constraints — avoids
                // Explore/Featured RenderFlex overflows in the shell.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: _buildBody(embedded: true),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: searchAreaTop,
              left: kPagePadding,
              right: kPagePadding,
              child: SizedBox(
                height: searchBarBlockHeight,
                child: SectionBoundary(
                  borderRadius: kIosCornerRadius,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  floating: true,
                  floatingBackgroundOpacity: 0.98,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(kIosCornerRadius),
                          border: Border.all(
                            color: Colors.grey.shade300.withValues(alpha: 0.6),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        child: TextField(
                          controller: _searchController,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(fontSize: 14.5),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: const MynauiIcon(
                              MynauiGlyphs.magnifer,
                              color: kAccentColor,
                              size: 21,
                            ),
                            hintText: 'Search title, summary, tags',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      _GuidesTabSelector(
                        current: _tab,
                        onChanged: (tab) {
                          if (tab == _tab) return;
                          setState(() {
                            _tab = tab;
                            _savedCurrentPage = 1;
                          });
                          _refresh(silent: true);
                        },
                        showYourArticles: _repository.canCreate,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: islandTop,
              left: kPagePadding,
              right: kPagePadding,
              child: LiftIslandHeader(
                scrollController: _scrollController,
                leading:
                    widget.onLeadingTap != null
                        ? LiftIslandHeaderAction(
                          onTap: widget.onLeadingTap,
                          child: const MynauiIcon(
                            MynauiGlyphs.qrCode,
                            size: kLiftIslandHeaderLeadingIconSize,
                            color: kLiftIslandOnFrosted,
                          ),
                        )
                        : null,
                trailing:
                    _repository.canCreate
                        ? LiftIslandHeaderIconAction(
                          iconWidget: MynauiIcon(
                            MynauiGlyphs.addCircle,
                            size: 22,
                            color: kLiftIslandOnFrosted,
                          ),
                          iconSize: 22,
                          onTap: _openCreate,
                        )
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _authorName(Article article) =>
      _authors
          .where((item) => item.id == article.authorId)
          .map((item) => item.name)
          .firstOrNull ??
      'Coach';

  Widget _buildBody({bool embedded = false}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kAccentColor),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load articles:\n$_error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kAccentColor),
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_visibleArticles.isEmpty) {
      final emptyMessage =
          _tab == _GuidesTab.yourArticles
              ? 'No guides in Studio yet.'
              : 'No guides yet.';
      if (embedded) {
        return _ContentIsland(
          fill: false,
          padding: const EdgeInsets.all(kPagePadding),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
            child: Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return Center(
        child: SectionBoundary(
          padding: const EdgeInsets.all(18),
          floating: true,
          child: Text(
            emptyMessage,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: KeyedSubtree(
        key: ValueKey(_tab),
        child: _buildTabContent(_tab, embedded: embedded),
      ),
    );
  }

  Widget _buildTabContent(_GuidesTab tab, {bool embedded = false}) {
    switch (tab) {
      case _GuidesTab.featured:
        return _buildFeaturedTab(embedded: embedded);
      case _GuidesTab.recent:
        return _buildArticleList(
          _articles,
          embedded: embedded,
          showPageControls: true,
          currentPage: _currentPage,
          totalPages: _totalPages,
          isChangingPage: _isChangingPage,
          onPreviousPage:
              _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
          onNextPage:
              _currentPage < _totalPages
                  ? () => _goToPage(_currentPage + 1)
                  : null,
          onSelectPage: (page) => _goToPage(page),
        );
      case _GuidesTab.saved:
        final saved = _articles
            .where((a) => _savedArticleIds.contains(a.id))
            .toList(growable: false);
        if (saved.isEmpty) {
          return _buildSavedEmptyState(embedded: embedded);
        }
        final savedTotalPages = math.max(
          1,
          (saved.length / _kEmbeddedArticlePageSize).ceil(),
        );
        final savedCurrentPage = _savedCurrentPage.clamp(1, savedTotalPages);
        final savedPageItems =
            embedded
                ? saved
                    .skip((savedCurrentPage - 1) * _kEmbeddedArticlePageSize)
                    .take(_kEmbeddedArticlePageSize)
                    .toList(growable: false)
                : saved;
        return _buildArticleList(
          savedPageItems,
          embedded: embedded,
          showPageControls: embedded && savedTotalPages > 1,
          currentPage: savedCurrentPage,
          totalPages: savedTotalPages,
          onPreviousPage:
              savedCurrentPage > 1
                  ? () =>
                      setState(() => _savedCurrentPage = savedCurrentPage - 1)
                  : null,
          onNextPage:
              savedCurrentPage < savedTotalPages
                  ? () =>
                      setState(() => _savedCurrentPage = savedCurrentPage + 1)
                  : null,
          onSelectPage:
              savedTotalPages > 1
                  ? (page) => setState(() => _savedCurrentPage = page)
                  : null,
        );
      case _GuidesTab.yourArticles:
        return _buildArticleList(
          _articles,
          embedded: embedded,
          showPageControls: true,
          currentPage: _currentPage,
          totalPages: _totalPages,
          isChangingPage: _isChangingPage,
          onPreviousPage:
              _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
          onNextPage:
              _currentPage < _totalPages
                  ? () => _goToPage(_currentPage + 1)
                  : null,
          onSelectPage: (page) => _goToPage(page),
        );
    }
  }

  Widget _buildSavedEmptyState({required bool embedded}) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MynauiIcon(
                MynauiGlyphs.bookmark,
                size: 42,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 14),
              Text(
                'Nothing saved just yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Save the guides you want to come back to and they will live here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (embedded) {
      return _ContentIsland(
        fill: true,
        padding: const EdgeInsets.all(kPagePadding),
        child: content,
      );
    }

    return content;
  }

  static const int _kFeaturedSpotlightCount = 3;

  Widget _buildFeaturedTab({bool embedded = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const featuredIslandPadding = EdgeInsets.all(8);
        final leadArticle = _featuredArticles.firstOrNull;
        final spotlightArticles = _featuredArticles
            .skip(1)
            .take(_kFeaturedSpotlightCount - 1)
            .toList(growable: false);
        final featuredAspectRatio = _featuredAspectRatio(
          constraints: constraints,
          spotlightCount: spotlightArticles.length,
          islandPadding: featuredIslandPadding.vertical,
          horizontalPadding: featuredIslandPadding.horizontal,
        );

        final content = <Widget>[
          if (leadArticle != null)
            _ArticleCard(
              article: leadArticle,
              authorName: _authorName(leadArticle),
              dateLabel: _dateLabel(leadArticle.publishedAt),
              canEdit: _repository.canEdit(leadArticle),
              canArchive: _repository.canArchive(leadArticle),
              featured: true,
              featuredAspectRatio: featuredAspectRatio,
              onOpen: () => _openArticle(leadArticle),
              onEdit:
                  _repository.canEdit(leadArticle)
                      ? () => _editFromList(leadArticle)
                      : null,
              onDelete:
                  _repository.canArchive(leadArticle)
                      ? () => _archiveFromList(leadArticle)
                      : null,
            ),
          if (spotlightArticles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              children: [
                for (
                  var index = 0;
                  index < spotlightArticles.length;
                  index++
                ) ...[
                  if (index > 0) const _EmbeddedArticleRowDivider(),
                  SizedBox(
                    height: _kEmbeddedSpotlightRowHeight,
                    child: _FeaturedSpotlightTile(
                      article: spotlightArticles[index],
                      authorName: _authorName(spotlightArticles[index]),
                      dateLabel: _dateLabel(
                        spotlightArticles[index].publishedAt,
                      ),
                      canEdit: _repository.canEdit(spotlightArticles[index]),
                      canArchive: _repository.canArchive(
                        spotlightArticles[index],
                      ),
                      onOpen: () => _openArticle(spotlightArticles[index]),
                      onEdit:
                          _repository.canEdit(spotlightArticles[index])
                              ? () => _editFromList(spotlightArticles[index])
                              : null,
                      onDelete:
                          _repository.canArchive(spotlightArticles[index])
                              ? () => _archiveFromList(spotlightArticles[index])
                              : null,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ];

        if (embedded) {
          return RefreshIndicator(
            color: kAccentColor,
            onRefresh: _refresh,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: _ContentIsland(
                    fill: true,
                    padding: featuredIslandPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: content,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: kAccentColor,
          onRefresh: _refresh,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 8),
            children: content,
          ),
        );
      },
    );
  }

  double _featuredAspectRatio({
    required BoxConstraints constraints,
    required int spotlightCount,
    double islandPadding = 0,
    double horizontalPadding = 0,
  }) {
    const fallbackAspectRatio = 1.42;
    const featuredLayoutSafetyBuffer = 1.0;
    if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) {
      return fallbackAspectRatio;
    }

    final width = math.max(0.0, constraints.maxWidth - horizontalPadding);
    const spotlightGapHeight = 10.0;
    const spotlightDividerHeight = 1.0;
    final reservedSpotlightHeight =
        spotlightCount == 0
            ? 0.0
            : spotlightGapHeight +
                (spotlightCount * _kEmbeddedSpotlightRowHeight) +
                ((spotlightCount - 1) * spotlightDividerHeight);
    final maxHeroHeight = math.max(
      0.0,
      constraints.maxHeight -
          islandPadding -
          reservedSpotlightHeight -
          featuredLayoutSafetyBuffer,
    );
    if (maxHeroHeight <= 0) return fallbackAspectRatio;

    return width / maxHeroHeight;
  }

  Widget _buildArticleList(
    List<Article> articles, {
    bool embedded = false,
    bool paginate = false,
    bool showPageControls = false,
    int currentPage = 1,
    int totalPages = 1,
    bool isChangingPage = false,
    VoidCallback? onPreviousPage,
    VoidCallback? onNextPage,
    ValueChanged<int>? onSelectPage,
  }) {
    final separator =
        embedded
            ? const _EmbeddedArticleRowDivider()
            : const SizedBox(height: 12);
    final listView = ListView.separated(
      controller: _scrollController,
      primary: false,
      physics:
          embedded
              ? const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              )
              : const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
      shrinkWrap: false,
      padding: embedded ? EdgeInsets.zero : const EdgeInsets.only(bottom: 8),
      itemCount:
          articles.length +
          (paginate && (_hasNextPage || _isLoadingMore) ? 1 : 0),
      separatorBuilder: (_, __) => separator,
      itemBuilder: (context, index) {
        if (index >= articles.length) {
          if (_isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: CircularProgressIndicator(color: kAccentColor),
              ),
            );
          }
          _loadMore();
          return const SizedBox(height: 12);
        }
        final article = articles[index];
        final canEdit = _repository.canEdit(article);
        final canArchive = _repository.canArchive(article);
        if (embedded) {
          return _FeaturedSpotlightTile(
            article: article,
            authorName: _authorName(article),
            dateLabel: _dateLabel(article.publishedAt),
            canEdit: canEdit,
            canArchive: canArchive,
            onOpen: () => _openArticle(article),
            onEdit: canEdit ? () => _editFromList(article) : null,
            onDelete: canArchive ? () => _archiveFromList(article) : null,
            padding: EdgeInsets.fromLTRB(
              6,
              index == 0 ? 4 : 5,
              6,
              index == articles.length - 1 ? 4 : 5,
            ),
          );
        }
        return _ArticleCard(
          article: article,
          authorName: _authorName(article),
          dateLabel: _dateLabel(article.publishedAt),
          canEdit: canEdit,
          canArchive: canArchive,
          onOpen: () => _openArticle(article),
          onEdit: canEdit ? () => _editFromList(article) : null,
          onDelete: canArchive ? () => _archiveFromList(article) : null,
        );
      },
    );

    if (embedded) {
      const islandPadding = EdgeInsets.all(kPagePadding);
      final showPagination =
          showPageControls && (totalPages > 1 || isChangingPage);

      return _ContentIsland(
        fill: true,
        padding: islandPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final shouldFitFullPage =
                      articles.length == _kEmbeddedArticlePageSize;
                  if (shouldFitFullPage) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var index = 0;
                          index < articles.length;
                          index++
                        ) ...[
                          if (index > 0) separator,
                          Expanded(
                            child: _FeaturedSpotlightTile(
                              article: articles[index],
                              authorName: _authorName(articles[index]),
                              dateLabel: _dateLabel(
                                articles[index].publishedAt,
                              ),
                              canEdit: _repository.canEdit(articles[index]),
                              canArchive: _repository.canArchive(
                                articles[index],
                              ),
                              onOpen: () => _openArticle(articles[index]),
                              onEdit:
                                  _repository.canEdit(articles[index])
                                      ? () => _editFromList(articles[index])
                                      : null,
                              onDelete:
                                  _repository.canArchive(articles[index])
                                      ? () => _archiveFromList(articles[index])
                                      : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              expandVertical: true,
                            ),
                          ),
                        ],
                      ],
                    );
                  }

                  final rows = <Widget>[
                    for (var index = 0; index < articles.length; index++) ...[
                      _FeaturedSpotlightTile(
                        article: articles[index],
                        authorName: _authorName(articles[index]),
                        dateLabel: _dateLabel(articles[index].publishedAt),
                        canEdit: _repository.canEdit(articles[index]),
                        canArchive: _repository.canArchive(articles[index]),
                        onOpen: () => _openArticle(articles[index]),
                        onEdit:
                            _repository.canEdit(articles[index])
                                ? () => _editFromList(articles[index])
                                : null,
                        onDelete:
                            _repository.canArchive(articles[index])
                                ? () => _archiveFromList(articles[index])
                                : null,
                        padding: EdgeInsets.fromLTRB(
                          6,
                          index == 0 ? 4.0 : 5.0,
                          6,
                          index == articles.length - 1 ? 4.0 : 5.0,
                        ),
                      ),
                      if (index < articles.length - 1) separator,
                    ],
                  ];

                  return Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: rows,
                    ),
                  );
                },
              ),
            ),
            if (showPagination) ...[
              // Match island / SectionBoundary vertical inset (same as workouts list).
              const SizedBox(height: kPagePadding),
              Center(
                child: LiftListPagination(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  isChangingPage: isChangingPage,
                  onPrevious: onPreviousPage,
                  onNext: onNextPage,
                  onSelectPage: onSelectPage,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: kAccentColor,
      onRefresh: _refresh,
      child: listView,
    );
  }
}

class _ContentIsland extends StatelessWidget {
  const _ContentIsland({
    required this.child,
    this.fill = false,
    this.padding = const EdgeInsets.all(kPagePadding),
  });

  final Widget child;
  final bool fill;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final island = SectionBoundary(
      borderRadius: kIosCornerRadius,
      padding: padding,
      clipBehavior: fill ? Clip.antiAlias : Clip.none,
      floating: true,
      floatingBackgroundOpacity: 0.98,
      child: child,
    );

    if (fill) {
      return SizedBox.expand(child: island);
    }

    return island;
  }
}

class _GuidesTabSelector extends StatelessWidget {
  const _GuidesTabSelector({
    required this.current,
    required this.onChanged,
    this.showYourArticles = false,
  });

  final _GuidesTab current;
  final ValueChanged<_GuidesTab> onChanged;
  final bool showYourArticles;

  static const _labels = {
    _GuidesTab.featured: 'Featured',
    _GuidesTab.recent: 'Explore',
    _GuidesTab.saved: 'Saved',
    _GuidesTab.yourArticles: 'Studio',
  };

  List<_GuidesTab> get _visibleTabs {
    final base = [_GuidesTab.featured, _GuidesTab.recent, _GuidesTab.saved];
    if (showYourArticles) base.add(_GuidesTab.yourArticles);
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(kIosCornerRadius),
        border: Border.all(color: Colors.grey.shade300.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children:
            _visibleTabs.map((tab) {
              final selected = tab == current;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? const Color(0xFFFCFCFD)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(kIosCornerRadius),
                      border: Border.all(
                        color:
                            selected
                                ? Colors.grey.shade200
                                : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _labels[tab]!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color:
                              selected
                                  ? const Color(0xFF171717)
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.authorName,
    required this.dateLabel,
    required this.canEdit,
    required this.canArchive,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
    this.featured = false,
    this.featuredAspectRatio = 1.42,
  });

  final Article article;
  final String authorName;
  final String dateLabel;
  final bool canEdit;
  final bool canArchive;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool featured;
  final double featuredAspectRatio;

  bool get _hasActions => canEdit || canArchive;

  _ArticleLabelToken get _primaryLabelToken {
    final topicLabel =
        article.tags.firstOrNull ?? article.categories.firstOrNull;
    if (topicLabel != null && topicLabel.isNotEmpty) {
      return _ArticleLabelToken(label: topicLabel, kind: _ArticlePillKind.tag);
    }
    return _ArticleLabelToken(
      label: article.status.label,
      kind: _ArticlePillKind.status,
    );
  }

  List<_ArticleLabelToken> get _topLabels {
    final labels = <_ArticleLabelToken>[];
    if (article.status == ArticleStatus.draft) {
      labels.add(
        _ArticleLabelToken(
          label: article.status.label,
          kind: _ArticlePillKind.status,
        ),
      );
    }
    final primaryLabel = _primaryLabelToken;
    if (primaryLabel.label.isNotEmpty &&
        labels.every((item) => item.label != primaryLabel.label)) {
      labels.add(primaryLabel);
    }
    return labels.take(2).toList(growable: false);
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.30),
      builder: (sheetContext) {
        final tiles = <Widget>[];
        if (canEdit) {
          tiles.add(
            LiftMenuActionTile(
              icon: MynauiIcon(
                MynauiGlyphs.editOne,
                size: 22,
                color: kAccentColor,
              ),
              title: 'Edit article',
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
          );
          if (canArchive) tiles.add(const SizedBox(height: 8));
        }
        if (canArchive) {
          tiles.add(
            LiftMenuActionTile(
              icon: MynauiIcon(
                MynauiGlyphs.trashBin,
                size: 22,
                color: Colors.red.shade600,
              ),
              title: 'Archive article',
              accent: Colors.red.shade600,
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          );
        }
        return SafeArea(
          top: false,
          bottom: false,
          child: LiftMenuSheet(
            title: 'Article options',
            subtitle: article.title,
            children: tiles,
          ),
        );
      },
    );
    if (action == 'edit') onEdit?.call();
    if (action == 'delete') onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (featured) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          onLongPress: _hasActions ? () => _showActions(context) : null,
          borderRadius: BorderRadius.circular(kIosCornerRadius),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kIosMediaRadius),
            child: AspectRatio(
              aspectRatio: featuredAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(kIosMediaRadius),
                      child: _ArticleImage(imageUrl: article.imageUrl),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.04),
                            Colors.black.withValues(alpha: 0.14),
                            Colors.black.withValues(alpha: 0.68),
                          ],
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _topLabels
                                .map(
                                  (label) => _ArticleTopPill(
                                    label: label.label,
                                    dark: true,
                                    kind: label.kind,
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    top: 42,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            height: 1.04,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          article.summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$authorName • $dateLabel',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        onLongPress: _hasActions ? () => _showActions(context) : null,
        borderRadius: BorderRadius.circular(kIosCornerRadius),
        child: SectionBoundary(
          borderRadius: kIosCornerRadius,
          padding: const EdgeInsets.all(12),
          floating: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(kIosMediaRadius),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _ArticleImage(imageUrl: article.imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            '$authorName • $dateLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        if (_topLabels.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: _topLabels
                                .map(
                                  (label) => _ArticleTopPill(
                                    label: label.label,
                                    compact: true,
                                    filled: true,
                                    kind: label.kind,
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal rule between embedded list rows: half the padded content width, centered.
class _EmbeddedArticleRowDivider extends StatelessWidget {
  const _EmbeddedArticleRowDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final paddedW = math.max(0.0, constraints.maxWidth - 16);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: SizedBox(
              width: paddedW * 0.5,
              child: Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerTheme.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeaturedSpotlightTile extends StatelessWidget {
  const _FeaturedSpotlightTile({
    required this.article,
    required this.authorName,
    required this.dateLabel,
    required this.canEdit,
    required this.canArchive,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    this.expandVertical = false,
  });

  final Article article;
  final String authorName;
  final String dateLabel;
  final bool canEdit;
  final bool canArchive;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final EdgeInsets padding;
  final bool expandVertical;

  bool get _hasActions => canEdit || canArchive;

  _ArticleLabelToken get _primaryLabelToken {
    final topicLabel =
        article.tags.firstOrNull ?? article.categories.firstOrNull;
    if (topicLabel != null && topicLabel.isNotEmpty) {
      return _ArticleLabelToken(label: topicLabel, kind: _ArticlePillKind.tag);
    }
    return _ArticleLabelToken(
      label: article.status.label,
      kind: _ArticlePillKind.status,
    );
  }

  List<_ArticleLabelToken> get _topLabels {
    final labels = <_ArticleLabelToken>[];
    if (article.status == ArticleStatus.draft) {
      labels.add(
        _ArticleLabelToken(
          label: article.status.label,
          kind: _ArticlePillKind.status,
        ),
      );
    }
    final primaryLabel = _primaryLabelToken;
    if (primaryLabel.label.isNotEmpty &&
        labels.every((item) => item.label != primaryLabel.label)) {
      labels.add(primaryLabel);
    }
    return labels.take(2).toList(growable: false);
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.30),
      builder: (sheetContext) {
        final tiles = <Widget>[];
        if (canEdit) {
          tiles.add(
            LiftMenuActionTile(
              icon: MynauiIcon(
                MynauiGlyphs.editOne,
                size: 22,
                color: kAccentColor,
              ),
              title: 'Edit article',
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
          );
          if (canArchive) tiles.add(const SizedBox(height: 8));
        }
        if (canArchive) {
          tiles.add(
            LiftMenuActionTile(
              icon: MynauiIcon(
                MynauiGlyphs.trashBin,
                size: 22,
                color: Colors.red.shade600,
              ),
              title: 'Archive article',
              accent: Colors.red.shade600,
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          );
        }
        return SafeArea(
          top: false,
          bottom: false,
          child: LiftMenuSheet(
            title: 'Article options',
            subtitle: article.title,
            children: tiles,
          ),
        );
      },
    );
    if (action == 'edit') onEdit?.call();
    if (action == 'delete') onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final inlineLabel = _topLabels.firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleT =
            expandVertical
                ? ((constraints.maxHeight - 92.0) / 24.0).clamp(0.0, 1.0)
                : 0.0;
        final resolvedThumbnailSize =
            expandVertical
                ? lerpDouble(80.0, 96.0, scaleT)!
                : _kEmbeddedSpotlightThumbnailSize;
        final titleSize =
            expandVertical ? lerpDouble(14.1, 15.1, scaleT)! : 14.4;
        final metaSize =
            expandVertical ? lerpDouble(10.4, 11.0, scaleT)! : 10.6;
        final titleGap = expandVertical ? lerpDouble(4.0, 5.0, scaleT)! : 4.0;
        final leadingGap =
            expandVertical ? lerpDouble(12.0, 14.0, scaleT)! : 12.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpen,
            onLongPress: _hasActions ? () => _showActions(context) : null,
            borderRadius: BorderRadius.circular(kIosCornerRadius),
            child: Padding(
              padding: padding,
              child:
                  expandVertical
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTileRow(
                            resolvedThumbnailSize: resolvedThumbnailSize,
                            leadingGap: leadingGap,
                            titleSize: titleSize,
                            titleGap: titleGap,
                            metaSize: metaSize,
                            inlineLabel: inlineLabel,
                          ),
                        ],
                      )
                      : _buildTileRow(
                        resolvedThumbnailSize: resolvedThumbnailSize,
                        leadingGap: leadingGap,
                        titleSize: titleSize,
                        titleGap: titleGap,
                        metaSize: metaSize,
                        inlineLabel: inlineLabel,
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTileRow({
    required double resolvedThumbnailSize,
    required double leadingGap,
    required double titleSize,
    required double titleGap,
    required double metaSize,
    required _ArticleLabelToken? inlineLabel,
  }) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(kIosMediaRadius),
          child: SizedBox(
            width: resolvedThumbnailSize,
            height: resolvedThumbnailSize,
            child: _ArticleImage(imageUrl: article.imageUrl),
          ),
        ),
        SizedBox(width: leadingGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w500,
                  height: 1.16,
                  color: const Color(0xFF171717),
                ),
              ),
              SizedBox(height: titleGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '$authorName • $dateLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: metaSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  if (inlineLabel != null) ...[
                    const SizedBox(width: 6),
                    _ArticleTopPill(
                      label: inlineLabel.label,
                      compact: true,
                      filled: true,
                      kind: inlineLabel.kind,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArticleImage extends StatelessWidget {
  const _ArticleImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ArticleImageView(
      imageRef: imageUrl,
      placeholderUrl: _kArticlePlaceholderImage,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kAccentDark, kAccentMid, kAccentLight],
              ),
            ),
            alignment: Alignment.center,
            child: MynauiIcon(
              MynauiGlyphs.galleryMinimalistic,
              color: Colors.white.withValues(alpha: 0.90),
              size: 40,
            ),
          ),
    );
  }
}

class _ArticleTopPill extends StatelessWidget {
  const _ArticleTopPill({
    required this.label,
    this.dark = false,
    this.compact = false,
    this.filled = false,
    this.kind = _ArticlePillKind.tag,
  });

  final String label;
  final bool dark;
  final bool compact;
  final bool filled;
  final _ArticlePillKind kind;

  bool get _isTag => kind == _ArticlePillKind.tag;

  /// Both article tags and article status pills render in all caps.
  String get _displayLabel => label.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? 6 : 8,
      vertical: compact ? 3 : 5,
    );

    if (dark) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color:
              _isTag
                  ? const Color(0xFF58616B).withValues(alpha: 0.34)
                  : Colors.black.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(kIosCornerRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: _isTag ? 0.18 : 0.14),
          ),
        ),
        child: Text(
          _displayLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.96),
            fontSize: compact ? 8.75 : 10,
            fontWeight: FontWeight.w500,
            letterSpacing: _isTag ? 0.48 : 0.04,
          ),
        ),
      );
    }

    final backgroundColor =
        _isTag
            ? const Color(0xFFF1F3F5).withValues(alpha: filled ? 0.92 : 0.86)
            : Colors.white.withValues(alpha: filled ? 0.84 : 0.76);
    final borderAlpha = _isTag ? 0.08 : (filled ? 0.08 : 0.06);

    return FrostedControlSurface(
      padding: padding,
      borderRadius: kIosChipRadius,
      blur: 10,
      backgroundColor: backgroundColor,
      borderColor: Colors.black.withValues(alpha: borderAlpha),
      boxShadow: const [],
      child: Text(
        _displayLabel,
        style: TextStyle(
          color: _isTag ? Colors.grey.shade800 : kLiftIslandOnFrosted,
          fontSize: compact ? 8.75 : 10,
          fontWeight: FontWeight.w500,
          letterSpacing: _isTag ? 0.48 : 0.04,
        ),
      ),
    );
  }
}
