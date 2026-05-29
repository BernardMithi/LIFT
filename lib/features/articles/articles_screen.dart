import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/features/articles/article_detail_screen.dart';
import 'package:lift/features/articles/article_editor_screen.dart';
import 'package:lift/features/articles/articles_repository.dart';
import 'package:lift/shared/models/article.dart';
import 'package:lift/shared/widgets/lift_action_button.dart';
import 'package:lift/shared/widgets/lift_dialogs.dart';
import 'package:lift/shared/widgets/lift_island_header.dart';
import 'package:lift/shared/widgets/lift_menu_sheet.dart';
import 'package:lift/shared/widgets/surfaces.dart';

const String _kArticlePlaceholderImage =
    'https://blocks.astratic.com/img/general-img-landscape.png';

enum _FilterScope { all, coach, machines, muscleGroups, categories }

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key, this.extraBottomInset = 0, this.repository});

  final double extraBottomInset;
  final ArticlesRepository? repository;

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  late final ArticlesRepository _repository;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;
  List<Article> _articles = const [];
  List<ArticleAuthor> _authors = const [];
  ArticleFilterOptions _filterOptions = const ArticleFilterOptions(
    tags: <String>[],
    machineIds: <String>[],
    muscleGroups: <String>[],
    categories: <String>[],
  );

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  int _nextPage = 1;
  int _totalArticles = 0;
  String _searchTerm = '';
  String? _error;

  _FilterScope _scope = _FilterScope.all;
  ArticleSort _sort = ArticleSort.latest;
  Set<String> _authorFilters = <String>{};
  Set<String> _machineFilters = <String>{};
  Set<String> _muscleFilters = <String>{};
  Set<String> _categoryFilters = <String>{};
  Set<String> _tagFilters = <String>{};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ArticlesRepository.instance;
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await _loadMetadata();
    await _refresh();
  }

  Future<void> _loadMetadata() async {
    final authors = await _repository.getAuthors();
    final options = await _repository.getFilterOptions();
    if (!mounted) return;
    setState(() {
      _authors = authors;
      _filterOptions = options;
    });
  }

  void _onScroll() {
    if (!_hasNextPage || _isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 220) {
      _loadMore();
    }
  }

  ArticlesQuery _buildQuery({required int page}) {
    return ArticlesQuery(
      page: page,
      limit: 8,
      searchTerm: _searchTerm,
      sort: _sort,
      tagFilters: _tagFilters,
      authorFilters: _authorFilters,
      machineFilters: _machineFilters,
      muscleFilters: _muscleFilters,
      categoryFilters: _categoryFilters,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _nextPage = 1;
      _hasNextPage = true;
    });
    try {
      final page = await _repository.getArticles(_buildQuery(page: 1));
      if (!mounted) return;
      setState(() {
        _articles = page.data;
        _nextPage = page.pagination.page + 1;
        _hasNextPage = page.pagination.hasNextPage;
        _totalArticles = page.pagination.total;
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
    if (_isLoadingMore || !_hasNextPage) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _repository.getArticles(_buildQuery(page: _nextPage));
      if (!mounted) return;
      setState(() {
        _articles = <Article>[..._articles, ...page.data];
        _nextPage = page.pagination.page + 1;
        _hasNextPage = page.pagination.hasNextPage;
        _totalArticles = page.pagination.total;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
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

  void _clearAllFilters() {
    setState(() {
      _scope = _FilterScope.all;
      _authorFilters.clear();
      _machineFilters.clear();
      _muscleFilters.clear();
      _categoryFilters.clear();
      _tagFilters.clear();
    });
    _refresh();
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

  Future<void> _deleteFromList(Article article) async {
    final confirmed = await showLiftConfirmDialog(
      context: context,
      title: 'Archive article?',
      message: 'This removes the article from member views.',
      confirmLabel: 'Archive',
      confirmColor: Colors.red.shade600,
    );
    if (confirmed != true) return;
    await _repository.deleteArticle(article);
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
            ),
      ),
    );
    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _openFilterPicker(_FilterScope scope) async {
    String title = '';
    List<String> options = const <String>[];
    Set<String> selected = <String>{};
    switch (scope) {
      case _FilterScope.all:
        _clearAllFilters();
        return;
      case _FilterScope.coach:
        title = 'Filter by coach';
        options = _authors.map((author) => author.id).toList(growable: false);
        selected = _authorFilters;
      case _FilterScope.machines:
        title = 'Filter by machine';
        options = _filterOptions.machineIds;
        selected = _machineFilters;
      case _FilterScope.muscleGroups:
        title = 'Filter by muscle group';
        options = _filterOptions.muscleGroups;
        selected = _muscleFilters;
      case _FilterScope.categories:
        title = 'Filter by category';
        options = _filterOptions.categories;
        selected = _categoryFilters;
    }
    final picked = await _showMultiSelectSheet(
      title: title,
      options: options,
      initialSelected: selected,
      displayLabel: (option) {
        if (scope == _FilterScope.coach) {
          return _authors
                  .where((author) => author.id == option)
                  .map((author) => author.name)
                  .firstOrNull ??
              option;
        }
        return option;
      },
    );
    if (picked == null) return;
    setState(() {
      _scope = scope;
      switch (scope) {
        case _FilterScope.all:
          break;
        case _FilterScope.coach:
          _authorFilters = picked;
        case _FilterScope.machines:
          _machineFilters = picked;
        case _FilterScope.muscleGroups:
          _muscleFilters = picked;
        case _FilterScope.categories:
          _categoryFilters = picked;
      }
    });
    _refresh();
  }

  Future<void> _openAdvancedFilters() async {
    final result = await showModalBottomSheet<_AdvancedFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (context) {
        var tempTags = Set<String>.from(_tagFilters);
        var tempAuthors = Set<String>.from(_authorFilters);
        var tempMachines = Set<String>.from(_machineFilters);
        var tempMuscles = Set<String>.from(_muscleFilters);
        var tempCategories = Set<String>.from(_categoryFilters);

        Widget chipGroup({
          required String title,
          required List<String> options,
          required Set<String> selected,
          required ValueChanged<Set<String>> onChanged,
          String Function(String value)? labelBuilder,
        }) {
          return _SheetFilterSection(
            title: title,
            children:
                options.map((option) {
                  final label = labelBuilder?.call(option) ?? option;
                  final isSelected = selected.contains(option);
                  return _SheetChoiceChip(
                    label: label,
                    selected: isSelected,
                    onTap: () {
                      final next = Set<String>.from(selected);
                      if (isSelected) {
                        next.remove(option);
                      } else {
                        next.add(option);
                      }
                      onChanged(next);
                    },
                  );
                }).toList(growable: false),
          );
        }

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  10 +
                      MediaQuery.of(context).padding.bottom +
                      MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: LiftMenuSheet(
                    title: 'Article filters',
                    subtitle:
                        'Refine tags, coaches, machines, muscle groups, and categories.',
                    children: [
                      chipGroup(
                        title: 'Tags',
                        options: _filterOptions.tags,
                        selected: tempTags,
                        onChanged:
                            (next) => setStateModal(() => tempTags = next),
                      ),
                      chipGroup(
                        title: 'Coaches',
                        options: _authors.map((author) => author.id).toList(),
                        selected: tempAuthors,
                        onChanged:
                            (next) => setStateModal(() => tempAuthors = next),
                        labelBuilder:
                            (value) =>
                                _authors
                                    .where((author) => author.id == value)
                                    .map((author) => author.name)
                                    .firstOrNull ??
                                value,
                      ),
                      chipGroup(
                        title: 'Machines',
                        options: _filterOptions.machineIds,
                        selected: tempMachines,
                        onChanged:
                            (next) => setStateModal(() => tempMachines = next),
                      ),
                      chipGroup(
                        title: 'Muscle groups',
                        options: _filterOptions.muscleGroups,
                        selected: tempMuscles,
                        onChanged:
                            (next) => setStateModal(() => tempMuscles = next),
                      ),
                      chipGroup(
                        title: 'Categories',
                        options: _filterOptions.categories,
                        selected: tempCategories,
                        onChanged:
                            (next) =>
                                setStateModal(() => tempCategories = next),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: LiftActionButton(
                              label: 'Clear',
                              onTap: () {
                                Navigator.pop(
                                  context,
                                  const _AdvancedFilterResult(
                                    tags: <String>{},
                                    authors: <String>{},
                                    machines: <String>{},
                                    muscles: <String>{},
                                    categories: <String>{},
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LiftActionButton(
                              label: 'Apply',
                              onTap: () {
                                Navigator.pop(
                                  context,
                                  _AdvancedFilterResult(
                                    tags: tempTags,
                                    authors: tempAuthors,
                                    machines: tempMachines,
                                    muscles: tempMuscles,
                                    categories: tempCategories,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (result == null) return;
    setState(() {
      _tagFilters = result.tags;
      _authorFilters = result.authors;
      _machineFilters = result.machines;
      _muscleFilters = result.muscles;
      _categoryFilters = result.categories;
    });
    _refresh();
  }

  Future<Set<String>?> _showMultiSelectSheet({
    required String title,
    required List<String> options,
    required Set<String> initialSelected,
    String Function(String option)? displayLabel,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (context) {
        var selected = Set<String>.from(initialSelected);
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  10 + MediaQuery.of(context).padding.bottom,
                ),
                child: LiftMenuSheet(
                  title: title,
                  subtitle: 'Select one or more options.',
                  children: [
                    SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: options
                            .map((option) {
                              final label = displayLabel?.call(option) ?? option;
                              return _SheetChoiceChip(
                                label: label,
                                selected: selected.contains(option),
                                onTap: () {
                                  setStateModal(() {
                                    if (selected.contains(option)) {
                                      selected.remove(option);
                                    } else {
                                      selected.add(option);
                                    }
                                  });
                                },
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LiftActionButton(
                            label: 'Clear',
                            onTap: () => Navigator.pop(context, <String>{}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LiftActionButton(
                            label: 'Apply',
                            onTap: () => Navigator.pop(context, selected),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  String _scopeLabel(_FilterScope scope) {
    switch (scope) {
      case _FilterScope.all:
        return 'All';
      case _FilterScope.coach:
        return 'By coach';
      case _FilterScope.machines:
        return 'Machines';
      case _FilterScope.muscleGroups:
        return 'Muscle groups';
      case _FilterScope.categories:
        return 'Categories';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = 24.0 + widget.extraBottomInset;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LiftIslandHeader(
              title: 'Learn',
              trailing:
                  _repository.canCreate
                      ? LiftIslandHeaderIconAction(
                        icon: Icons.add_rounded,
                        iconSize: 24,
                        onTap: _openCreate,
                      )
                      : null,
            ),
            const SizedBox(height: 10),
            SectionBoundary(
              borderRadius: 16,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassContainer(
                    borderRadius: 14,
                    blur: 10,
                    showSheen: false,
                    showBorder: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: const Icon(
                          Icons.search_rounded,
                          color: kAccentColor,
                          size: 22,
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
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final scope in _FilterScope.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                _scopeLabel(scope),
                                style: const TextStyle(fontSize: 12.5),
                              ),
                              selected: _scope == scope,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(
                                horizontal: -3,
                                vertical: -3,
                              ),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              onSelected: (_) => _openFilterPicker(scope),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: _openAdvancedFilters,
                          icon: const Icon(Icons.tune_rounded, size: 14),
                          label: const Text(
                            'Filters',
                            style: TextStyle(fontSize: 12.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            visualDensity: const VisualDensity(
                              horizontal: -3,
                              vertical: -3,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _SortChip(
                        label: 'Latest',
                        selected: _sort == ArticleSort.latest,
                        onTap: () {
                          if (_sort == ArticleSort.latest) return;
                          setState(() => _sort = ArticleSort.latest);
                          _refresh();
                        },
                      ),
                      const SizedBox(width: 6),
                      _SortChip(
                        label: 'Recommended',
                        selected: _sort == ArticleSort.recommended,
                        onTap: () {
                          if (_sort == ArticleSort.recommended) return;
                          setState(() => _sort = ArticleSort.recommended);
                          _refresh();
                        },
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '$_totalArticles',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
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
    if (_articles.isEmpty) {
      return Center(
        child: Text(
          'No articles match your filters.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }
    return RefreshIndicator(
      color: kAccentColor,
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        itemCount: _articles.length + (_hasNextPage || _isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _articles.length) {
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
          final article = _articles[index];
          final author =
              _authors
                  .where((item) => item.id == article.authorId)
                  .map((item) => item.name)
                  .firstOrNull ??
              'Coach';
          final canEdit = _repository.canEdit(article);
          return _ArticleCard(
            article: article,
            authorName: author,
            dateLabel: _dateLabel(article.publishedAt),
            canEdit: canEdit,
            onOpen: () => _openArticle(article),
            onEdit: canEdit ? () => _editFromList(article) : null,
            onDelete: canEdit ? () => _deleteFromList(article) : null,
          );
        },
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color:
                selected ? kAccentColor : kAccentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected
                      ? kAccentColor
                      : kAccentColor.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : kAccentColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetFilterSection extends StatelessWidget {
  const _SheetFilterSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children,
          ),
        ],
      ),
    );
  }
}

class _SheetChoiceChip extends StatelessWidget {
  const _SheetChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        selected
            ? kAccentColor.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.78);
    final borderColor =
        selected
            ? kAccentColor.withValues(alpha: 0.38)
            : kAccentColor.withValues(alpha: 0.18);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? kAccentColor : const Color(0xFF5B4B42),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
    required this.onOpen,
    this.onEdit,
    this.onDelete,
  });

  final Article article;
  final String authorName;
  final String dateLabel;
  final bool canEdit;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
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
              subtitle: article.title,
              children: [
                LiftMenuActionTile(
                  icon: const Icon(Icons.edit_outlined),
                  title: 'Edit article',
                  onTap: () => Navigator.pop(sheetContext, 'edit'),
                ),
                const SizedBox(height: 8),
                LiftMenuActionTile(
                  icon: const Icon(Icons.delete_outline),
                  title: 'Archive article',
                  accent: Colors.red.shade600,
                  onTap: () => Navigator.pop(sheetContext, 'archive'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == 'edit') onEdit?.call();
    if (action == 'archive') onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: SectionBoundary(
          borderRadius: 18,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    article.imageUrl ?? _kArticlePlaceholderImage,
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
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 42,
                          ),
                        ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            article.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (canEdit)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showActions(context),
                              borderRadius: BorderRadius.circular(14),
                              child: Ink(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: kAccentColor.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: kAccentColor.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.more_horiz_rounded,
                                  color: kAccentColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          ' • $dateLabel',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: article.tags
                          .take(3)
                          .map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: kAccentColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: kAccentColor.withValues(alpha: 0.20),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: kAccentColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
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

class _AdvancedFilterResult {
  const _AdvancedFilterResult({
    required this.tags,
    required this.authors,
    required this.machines,
    required this.muscles,
    required this.categories,
  });

  final Set<String> tags;
  final Set<String> authors;
  final Set<String> machines;
  final Set<String> muscles;
  final Set<String> categories;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
