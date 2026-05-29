import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/features/articles/widgets/article_embed_view.dart';
import 'package:lift/shared/icons/mynaui_glyphs.dart';
import 'package:lift/shared/icons/mynaui_icon.dart';
import 'package:lift/features/articles/widgets/article_image_view.dart';

class ArticleBodyView extends StatelessWidget {
  const ArticleBodyView({
    super.key,
    required this.content,
    this.emptyLabel = 'Nothing to preview yet.',
  });

  final String content;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseArticleBlocks(content);
    if (blocks.isEmpty) {
      return Text(
        emptyLabel,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.grey.shade500,
        ),
      );
    }

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            _ArticleBlockView(block: blocks[i]),
            if (i < blocks.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

enum _ArticleBlockType {
  heading1,
  heading2,
  paragraph,
  bulletList,
  numberedList,
  quote,
  divider,
  embed,
  image,
}

class _ArticleBlock {
  const _ArticleBlock({
    required this.type,
    required this.value,
    this.items = const <String>[],
    this.embed,
  });

  final _ArticleBlockType type;
  final String value;
  final List<String> items;
  final ArticleEmbedData? embed;
}

List<_ArticleBlock> _parseArticleBlocks(String raw) {
  final normalized = raw.replaceAll('\r\n', '\n').trim();
  if (normalized.isEmpty) return const <_ArticleBlock>[];

  final blocks = normalized
      .split(RegExp(r'\n\s*\n'))
      .map((block) => block.trim())
      .where((block) => block.isNotEmpty);

  return blocks.map(_parseBlock).toList(growable: false);
}

_ArticleBlock _parseBlock(String block) {
  final lines = block
      .split('\n')
      .map((line) => line.trimRight())
      .where((line) => line.trim().isNotEmpty)
      .toList(growable: false);

  if (lines.isEmpty) {
    return const _ArticleBlock(type: _ArticleBlockType.paragraph, value: '');
  }

  if (lines.length == 1 && RegExp(r'^-{3,}$').hasMatch(lines.first.trim())) {
    return const _ArticleBlock(type: _ArticleBlockType.divider, value: '');
  }

  final first = lines.first.trim();
  if (lines.length == 1) {
    final imageUrl = _tryParseImageDirective(first);
    if (imageUrl != null) {
      return _ArticleBlock(type: _ArticleBlockType.image, value: imageUrl);
    }
  }
  if (first.startsWith('!embed ')) {
    final embed = ArticleEmbedData.tryParse(first.substring(7).trim());
    if (embed != null) {
      return _ArticleBlock(
        type: _ArticleBlockType.embed,
        value: embed.sourceUrl,
        embed: embed,
      );
    }
  }
  if (lines.length == 1) {
    final embed = ArticleEmbedData.tryParse(first);
    if (embed != null) {
      return _ArticleBlock(
        type: _ArticleBlockType.embed,
        value: embed.sourceUrl,
        embed: embed,
      );
    }
  }
  if (first.startsWith('# ')) {
    return _ArticleBlock(
      type: _ArticleBlockType.heading1,
      value: first.substring(2).trim(),
    );
  }
  if (first.startsWith('## ')) {
    return _ArticleBlock(
      type: _ArticleBlockType.heading2,
      value: first.substring(3).trim(),
    );
  }
  if (lines.every((line) => line.trim().startsWith('> '))) {
    return _ArticleBlock(
      type: _ArticleBlockType.quote,
      value: lines.map((line) => line.trim().substring(2).trim()).join(' '),
    );
  }
  if (lines.every((line) => line.trim().startsWith('- '))) {
    return _ArticleBlock(
      type: _ArticleBlockType.bulletList,
      value: '',
      items: lines.map((line) => line.trim().substring(2).trim()).toList(),
    );
  }
  if (lines.every((line) => RegExp(r'^\d+\.\s+').hasMatch(line.trim()))) {
    return _ArticleBlock(
      type: _ArticleBlockType.numberedList,
      value: '',
      items:
          lines
              .map((line) => line.trim().replaceFirst(RegExp(r'^\d+\.\s+'), ''))
              .toList(),
    );
  }

  return _ArticleBlock(
    type: _ArticleBlockType.paragraph,
    value: lines.join('\n'),
  );
}

/// `!image <url-or-local-path>` or markdown `![alt](...)` on a single line.
String? _tryParseImageDirective(String line) {
  final t = line.trim();
  if (t.startsWith('!image ')) {
    final url = t.substring(7).trim();
    return url.isEmpty ? null : url;
  }
  final md = RegExp(r'^!\[([^\]]*)\]\(([^)]+)\)\s*$').firstMatch(t);
  if (md != null) {
    final url = md.group(2)?.trim() ?? '';
    return url.isEmpty ? null : url;
  }
  return null;
}

class _ArticleBlockView extends StatelessWidget {
  const _ArticleBlockView({required this.block});

  final _ArticleBlock block;

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case _ArticleBlockType.heading1:
        return Text(
          block.value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.16,
            color: Color(0xFF151515),
          ),
        );
      case _ArticleBlockType.heading2:
        return Text(
          block.value,
          style: const TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w700,
            height: 1.22,
            color: Color(0xFF1A1A1A),
          ),
        );
      case _ArticleBlockType.quote:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: kAccentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(kIosCornerRadius),
            border: Border.all(color: kAccentColor.withValues(alpha: 0.18)),
          ),
          child: Text(
            block.value,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: Color(0xFF3F2A1E),
            ),
          ),
        );
      case _ArticleBlockType.bulletList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              block.items
                  .map(
                    (item) => _ArticleListItem(text: item, isNumbered: false),
                  )
                  .toList(),
        );
      case _ArticleBlockType.numberedList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            block.items.length,
            (index) => _ArticleListItem(
              text: block.items[index],
              isNumbered: true,
              index: index + 1,
            ),
          ),
        );
      case _ArticleBlockType.divider:
        return Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).dividerTheme.color,
        );
      case _ArticleBlockType.embed:
        return ArticleEmbedView(embed: block.embed!);
      case _ArticleBlockType.image:
        return _ArticleBodyImage(url: block.value);
      case _ArticleBlockType.paragraph:
        return Text(
          block.value,
          style: const TextStyle(
            fontSize: 14,
            height: 1.62,
            color: Color(0xFF1F2937),
          ),
        );
    }
  }
}

class _ArticleBodyImage extends StatelessWidget {
  const _ArticleBodyImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kIosCornerRadius),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ArticleImageView(
          imageRef: url,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return ColoredBox(
              color: Colors.grey.shade100,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kAccentColor.withValues(alpha: 0.7),
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MynauiIcon(
                    MynauiGlyphs.galleryMinimalistic,
                    size: 36,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Could not load image',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    url,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ArticleListItem extends StatelessWidget {
  const _ArticleListItem({
    required this.text,
    required this.isNumbered,
    this.index = 0,
  });

  final String text;
  final bool isNumbered;
  final int index;

  @override
  Widget build(BuildContext context) {
    final marker = isNumbered ? '$index.' : '•';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              marker,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.58,
                color: isNumbered ? kAccentColor : const Color(0xFF374151),
                fontWeight: isNumbered ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.58,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
