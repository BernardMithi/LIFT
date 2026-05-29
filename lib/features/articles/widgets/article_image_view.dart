import 'dart:io';

import 'package:flutter/material.dart';

bool isArticleNetworkImageReference(String? raw) {
  if (raw == null) return false;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !uri.hasScheme) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  return uri.host.isNotEmpty;
}

String? normalizeArticleImageReference(
  String? raw, {
  bool requireExistingLocalFile = true,
}) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  if (isArticleNetworkImageReference(trimmed)) {
    return trimmed;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    if (uri.scheme != 'file') return null;
    final filePath = uri.toFilePath();
    final file = File(filePath);
    if (requireExistingLocalFile && !file.existsSync()) {
      return null;
    }
    return file.path;
  }

  final file = File(trimmed);
  if (!file.isAbsolute) return null;
  if (requireExistingLocalFile && !file.existsSync()) {
    return null;
  }
  return file.path;
}

File? articleImageFileFromReference(String? raw) {
  final filePath = normalizeArticleImageReference(raw);
  if (filePath == null || isArticleNetworkImageReference(filePath)) {
    return null;
  }
  return File(filePath);
}

class ArticleImageView extends StatelessWidget {
  const ArticleImageView({
    super.key,
    required this.imageRef,
    this.placeholderUrl,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.medium,
    this.loadingBuilder,
    this.errorBuilder,
    this.alignment = Alignment.center,
  });

  final String? imageRef;
  final String? placeholderUrl;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final localFile = articleImageFileFromReference(imageRef);
    if (localFile != null) {
      return Image.file(
        localFile,
        fit: fit,
        alignment: alignment,
        filterQuality: filterQuality,
        errorBuilder: errorBuilder,
      );
    }

    final remoteUrl =
        isArticleNetworkImageReference(imageRef) ? imageRef!.trim() : null;
    final placeholder =
        isArticleNetworkImageReference(placeholderUrl)
            ? placeholderUrl!.trim()
            : null;
    final resolvedUrl = remoteUrl ?? placeholder;

    if (resolvedUrl == null) {
      return const SizedBox.shrink();
    }

    return Image.network(
      resolvedUrl,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
