import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/models/article.dart';
import 'package:lift/shared/widgets/surfaces.dart';

class ArticleEditorScreen extends StatefulWidget {
  const ArticleEditorScreen({
    super.key,
    this.initialArticle,
    required this.machineSuggestions,
  });

  final Article? initialArticle;
  final List<String> machineSuggestions;

  bool get isEditing => initialArticle != null;

  @override
  State<ArticleEditorScreen> createState() => _ArticleEditorScreenState();
}

class _ArticleEditorScreenState extends State<ArticleEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _contentController;
  late final TextEditingController _imageController;
  late final TextEditingController _tagsController;
  late final TextEditingController _musclesController;
  late final TextEditingController _categoriesController;
  late final TextEditingController _machinesController;
  late ArticleStatus _status;

  @override
  void initState() {
    super.initState();
    final article = widget.initialArticle;
    _titleController = TextEditingController(text: article?.title ?? '');
    _summaryController = TextEditingController(text: article?.summary ?? '');
    _contentController = TextEditingController(text: article?.content ?? '');
    _imageController = TextEditingController(text: article?.imageUrl ?? '');
    _tagsController = TextEditingController(text: _join(article?.tags));
    _musclesController = TextEditingController(
      text: _join(article?.muscleGroups),
    );
    _categoriesController = TextEditingController(
      text: _join(article?.categories),
    );
    _machinesController = TextEditingController(
      text: _join(article?.machineIds),
    );
    _status = article?.status ?? ArticleStatus.draft;
  }

  String _join(List<String>? items) => items == null ? '' : items.join(', ');

  List<String> _parseCsv(String raw) {
    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final summary = _summaryController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || summary.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title, summary, and content are required.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      ArticleInput(
        title: title,
        summary: summary,
        content: content,
        imageUrl: _imageController.text.trim(),
        tags: _parseCsv(_tagsController.text),
        machineIds: _parseCsv(_machinesController.text),
        muscleGroups: _parseCsv(_musclesController.text),
        categories: _parseCsv(_categoriesController.text),
        status: _status,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _imageController.dispose();
    _tagsController.dispose();
    _musclesController.dispose();
    _categoriesController.dispose();
    _machinesController.dispose();
    super.dispose();
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit article' : 'Create article'),
        actions: [TextButton(onPressed: _submit, child: const Text('Save'))],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SectionBoundary(
            borderRadius: 18,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(label: 'Title', controller: _titleController),
                _field(
                  label: 'Summary',
                  controller: _summaryController,
                  maxLines: 2,
                ),
                _field(
                  label: 'Content',
                  controller: _contentController,
                  maxLines: 8,
                ),
                _field(
                  label: 'Header image URL',
                  controller: _imageController,
                  hint: 'https://example.com/image.jpg (optional)',
                ),
                _field(
                  label: 'Tags',
                  controller: _tagsController,
                  hint: 'form, back, machine',
                ),
                _field(
                  label: 'Muscle groups',
                  controller: _musclesController,
                  hint: 'Back, Biceps',
                ),
                _field(
                  label: 'Categories',
                  controller: _categoriesController,
                  hint: 'Technique, Recovery, Workout Plan',
                ),
                _field(
                  label: 'Machine IDs',
                  controller: _machinesController,
                  hint: widget.machineSuggestions.join(', '),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ArticleStatus>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? Colors.white
                          : kAccentColor;
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? kAccentColor
                          : Colors.white;
                    }),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ArticleStatus.draft,
                      label: Text('Draft'),
                    ),
                    ButtonSegment(
                      value: ArticleStatus.published,
                      label: Text('Published'),
                    ),
                    ButtonSegment(
                      value: ArticleStatus.archived,
                      label: Text('Archived'),
                    ),
                  ],
                  selected: {_status},
                  onSelectionChanged: (next) {
                    if (next.isEmpty) return;
                    setState(() => _status = next.first);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
