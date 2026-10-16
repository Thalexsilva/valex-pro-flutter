import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Demonstration media associated with a catalog or prescribed exercise.
class ExerciseMedia extends StatelessWidget {
  const ExerciseMedia({
    super.key,
    this.images = const [],
    this.animationUrl = '',
    this.videoUrl = '',
    this.attribution = '',
  });

  final List<String> images;
  final String animationUrl;
  final String videoUrl;
  final String attribution;

  static bool _safe(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final photos = images.where(_safe).toList();
    final animation = _safe(animationUrl)
        ? animationUrl
        : videoUrl.toLowerCase().endsWith('.gif') && _safe(videoUrl)
        ? videoUrl
        : '';
    final hasAnimation = animation.isNotEmpty;
    final hasVideo = _safe(videoUrl) && videoUrl != animation;
    if (photos.isEmpty && !hasAnimation && !hasVideo) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAnimation) ...[
          Semantics(
            label: 'Animação da execução do exercício',
            child: _picture(animation, 220),
          ),
          const SizedBox(height: 8),
        ],
        if (photos.isNotEmpty) ...[
          Text(
            'Execução do exercício',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final showPair =
                  photos.length == 2 &&
                  constraints.maxWidth.isFinite &&
                  constraints.maxWidth < 408;
              final photoWidth = showPair
                  ? (constraints.maxWidth - 8) / 2
                  : 200.0;
              final photoHeight = showPair ? photoWidth / 1.25 : 160.0;
              return SizedBox(
                height: photoHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => Semantics(
                    label: 'Posição ${index + 1} do exercício',
                    child: _picture(
                      photos[index],
                      photoHeight,
                      width: photoWidth,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        if (hasVideo)
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(videoUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Assistir ao vídeo de execução'),
          ),
        if (attribution.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              attribution,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _picture(String url, double height, {double? width}) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      url,
      width: width ?? height * 1.25,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => SizedBox(
        width: width ?? height * 1.25,
        height: height,
        child: const Center(child: Text('Imagem indisponível')),
      ),
    ),
  );
}
