import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lift/shared/icons/mynaui_glyphs.dart';
import 'package:lift/shared/icons/mynaui_icon.dart';

bool workoutTemplateImageIsNetworkUrl(String raw) {
  final t = raw.trim().toLowerCase();
  return t.startsWith('http://') || t.startsWith('https://');
}

/// Renders a workout template [imageUrl]: HTTPS images via [Image.network],
/// otherwise treats the value as a local file path (including `file://` URIs).
class WorkoutTemplateHeroImage extends StatelessWidget {
  const WorkoutTemplateHeroImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.gaplessPlayback = true,
    this.filterQuality = FilterQuality.medium,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final String imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;
  final double? width;
  final double? height;

  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  Widget _defaultError(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: MynauiIcon(
        MynauiGlyphs.galleryMinimalistic,
        color: Colors.grey.shade500,
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = imageUrl.trim();
    if (t.isEmpty) {
      return errorBuilder?.call(context, '', null) ?? _defaultError(context);
    }

    if (workoutTemplateImageIsNetworkUrl(t)) {
      return Image.network(
        t,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: gaplessPlayback,
        filterQuality: filterQuality,
        loadingBuilder: loadingBuilder,
        errorBuilder:
            errorBuilder ??
            (context, error, stackTrace) => _defaultError(context),
      );
    }

    final path =
        t.toLowerCase().startsWith('file://') ? Uri.parse(t).toFilePath() : t;
    final file = File(path);
    if (!file.existsSync()) {
      return errorBuilder?.call(context, '', null) ?? _defaultError(context);
    }

    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      gaplessPlayback: gaplessPlayback,
      filterQuality: filterQuality,
      errorBuilder: errorBuilder,
    );
  }
}
