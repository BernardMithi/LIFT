import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/icons/mynaui_glyphs.dart';
import 'package:lift/shared/icons/mynaui_icon.dart';
import 'package:lift/shared/widgets/surfaces.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum ArticleEmbedProvider { youtube, instagram }

class ArticleEmbedData {
  const ArticleEmbedData({
    required this.provider,
    required this.sourceUrl,
    required this.embedUrl,
    required this.label,
    required this.height,
    this.aspectRatio,
  });

  final ArticleEmbedProvider provider;
  final String sourceUrl;
  final String embedUrl;
  final String label;
  final double height;
  final double? aspectRatio;

  bool get isInstagram => provider == ArticleEmbedProvider.instagram;
  bool get isYoutube => provider == ArticleEmbedProvider.youtube;

  static ArticleEmbedData? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;

    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be') ||
        host.contains('youtube.com') ||
        host.contains('youtube-nocookie.com')) {
      final videoId = _extractYouTubeVideoId(uri);
      if (videoId == null || videoId.isEmpty) return null;
      return ArticleEmbedData(
        provider: ArticleEmbedProvider.youtube,
        sourceUrl: trimmed,
        embedUrl:
            'https://www.youtube-nocookie.com/embed/$videoId'
            '?playsinline=1&rel=0&modestbranding=1',
        label: 'YouTube video',
        height: 220,
        aspectRatio: 16 / 9,
      );
    }

    if (host.contains('instagram.com') || host.contains('instagr.am')) {
      final embedPath = _extractInstagramEmbedPath(uri);
      if (embedPath == null) return null;
      final isReel = embedPath.startsWith('reel/');
      return ArticleEmbedData(
        provider: ArticleEmbedProvider.instagram,
        sourceUrl: trimmed,
        embedUrl: 'https://www.instagram.com/$embedPath/embed/',
        label: isReel ? 'Instagram reel' : 'Instagram post',
        height: isReel ? 620 : 480,
      );
    }

    return null;
  }

  static String? _extractYouTubeVideoId(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      if (uri.pathSegments.isEmpty) return null;
      return uri.pathSegments.first;
    }

    final fromQuery = uri.queryParameters['v']?.trim();
    if (fromQuery != null && fromQuery.isNotEmpty) {
      return fromQuery;
    }

    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments.first == 'embed') {
      return segments[1];
    }
    if (segments.length >= 2 && segments.first == 'shorts') {
      return segments[1];
    }

    return null;
  }

  static String? _extractInstagramEmbedPath(Uri uri) {
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    for (var i = 0; i < segments.length; i++) {
      final segment = segments.elementAt(i).toLowerCase();
      final hasNext = i + 1 < segments.length;
      if (!hasNext) continue;
      final slug = segments.elementAt(i + 1);
      if (slug.isEmpty) continue;
      switch (segment) {
        case 'p':
          return 'p/$slug';
        case 'reel':
        case 'reels':
          return 'reel/$slug';
        case 'tv':
          return 'tv/$slug';
      }
    }
    return null;
  }
}

class ArticleEmbedView extends StatelessWidget {
  const ArticleEmbedView({super.key, required this.embed});

  final ArticleEmbedData embed;

  @override
  Widget build(BuildContext context) {
    final media = ClipRRect(
      borderRadius: BorderRadius.circular(kIosCornerRadius),
      child:
          embed.aspectRatio != null
              ? AspectRatio(
                aspectRatio: embed.aspectRatio!,
                child: _ArticleEmbedPreview(embed: embed),
              )
              : SizedBox(
                height: embed.height,
                child: _ArticleEmbedPreview(embed: embed),
              ),
    );

    return SelectionContainer.disabled(
      child: SectionBoundary(
        borderRadius: kIosCornerRadius,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(kIosControlRadius),
                    ),
                    child: Text(
                      embed.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            media,
          ],
        ),
      ),
    );
  }
}

class _ArticleEmbedPreview extends StatefulWidget {
  const _ArticleEmbedPreview({required this.embed});

  final ArticleEmbedData embed;

  @override
  State<_ArticleEmbedPreview> createState() => _ArticleEmbedPreviewState();
}

class _ArticleEmbedPreviewState extends State<_ArticleEmbedPreview> {
  late final WebViewController _controller;
  var _isLoading = true;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.transparent)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) {
                if (!mounted) return;
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              },
              onPageFinished: (_) {
                if (!mounted) return;
                setState(() {
                  _isLoading = false;
                });
              },
              onWebResourceError: (error) {
                if (error.isForMainFrame == false) return;
                if (!mounted) return;
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              },
            ),
          );
    _loadEmbed();
  }

  @override
  void didUpdateWidget(covariant _ArticleEmbedPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embed.embedUrl != widget.embed.embedUrl) {
      _loadEmbed();
    }
  }

  Future<void> _loadEmbed() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      await _controller.loadRequest(Uri.parse(widget.embed.embedUrl));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ArticleEmbedFallback(embed: widget.embed);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(
          key: ValueKey(widget.embed.embedUrl),
          controller: _controller,
        ),
        if (_isLoading)
          Container(
            color: const Color(0xFFF4F5F7),
            alignment: Alignment.center,
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.black.withValues(alpha: 0.42),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ArticleEmbedFallback extends StatelessWidget {
  const _ArticleEmbedFallback({required this.embed});

  final ArticleEmbedData embed;

  @override
  Widget build(BuildContext context) {
    final iconColor = Colors.black.withValues(alpha: 0.56);
    final iconWidget =
        embed.isYoutube
            ? Icon(
              Icons.play_circle_outline_rounded,
              size: 34,
              color: iconColor,
            )
            : MynauiIcon(
              MynauiGlyphs.galleryMinimalistic,
              size: 34,
              color: iconColor,
            );
    return Container(
      color: const Color(0xFFF4F5F7),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(height: 10),
          Text(
            embed.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unable to load this embed in preview.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.56),
            ),
          ),
        ],
      ),
    );
  }
}
