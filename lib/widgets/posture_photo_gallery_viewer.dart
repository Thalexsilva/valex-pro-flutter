import 'package:flutter/material.dart';
import '../models/anamnese_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'carbon_card.dart';
import 'private_document_image.dart';

/// PosturePhotoGalleryViewer — Galeria Postural 360° com Comparador Lado a Lado
class PosturePhotoGalleryViewer extends StatefulWidget {
  final List<PosturePhoto> photos;
  final List<PosturePhoto>?
  baselinePhotos; // Fotos da 1ª avaliação para comparar Antes vs Depois
  final Function(PostureAngle angle)? onAddPhoto;

  const PosturePhotoGalleryViewer({
    super.key,
    required this.photos,
    this.baselinePhotos,
    this.onAddPhoto,
  });

  @override
  State<PosturePhotoGalleryViewer> createState() =>
      _PosturePhotoGalleryViewerState();
}

class _PosturePhotoGalleryViewerState extends State<PosturePhotoGalleryViewer> {
  bool _compareMode = false;
  PostureAngle _selectedAngle = PostureAngle.front;

  @override
  Widget build(BuildContext context) {
    final hasBaseline =
        widget.baselinePhotos != null && widget.baselinePhotos!.isNotEmpty;

    return CarbonCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.blueLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AVALIAÇÃO POSTURAL & FOTOS 360°',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.photos.length} fotos posturais anexadas.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasBaseline)
                FilterChip(
                  label: const Text(
                    'Antes vs. Depois',
                    style: TextStyle(fontSize: 11),
                  ),
                  selected: _compareMode,
                  selectedColor: AppColors.blue,
                  onSelected: (val) => setState(() => _compareMode = val),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Angle Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PostureAngle.values.map((angle) {
                final isSelected = _selectedAngle == angle;
                final photoForAngle = widget.photos
                    .cast<PosturePhoto?>()
                    .firstWhere((p) => p?.angle == angle, orElse: () => null);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      photoForAngle != null
                          ? Icons.check_circle_outline
                          : Icons.add_a_photo_outlined,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : (photoForAngle != null
                                ? AppColors.emerald
                                : AppColors.steel),
                    ),
                    label: Text(angle.label),
                    selected: isSelected,
                    selectedColor: AppColors.vibrantBlue,
                    onSelected: (val) {
                      if (val) setState(() => _selectedAngle = angle);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Photo Display Area
          if (_compareMode && hasBaseline)
            _buildComparisonView(_selectedAngle)
          else
            _buildSingleAngleView(_selectedAngle),
        ],
      ),
    );
  }

  Widget _buildSingleAngleView(PostureAngle angle) {
    final photo = widget.photos.cast<PosturePhoto?>().firstWhere(
      (p) => p?.angle == angle,
      orElse: () => null,
    );

    if (photo == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.carbon3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white12,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                size: 40,
                color: AppColors.steel,
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhuma foto anexada para o ângulo: ${angle.label}',
                style: AppTheme.bodyMd(color: AppColors.steel),
              ),
              if (widget.onAddPhoto != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Tirar / Enviar Foto Agora'),
                  onPressed: () => widget.onAddPhoto!(angle),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: AppColors.carbon3,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.person_pin, size: 80, color: Colors.white12),
                  PrivateDocumentImage(reference: photo.url),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ângulo: ${angle.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Registrado em: ${photo.capturedAt.day.toString().padLeft(2, '0')}/${photo.capturedAt.month.toString().padLeft(2, '0')}/${photo.capturedAt.year}',
                  style: const TextStyle(fontSize: 11, color: AppColors.steel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView(PostureAngle angle) {
    final currentPhoto = widget.photos.cast<PosturePhoto?>().firstWhere(
      (p) => p?.angle == angle,
      orElse: () => null,
    );
    final basePhoto = widget.baselinePhotos?.cast<PosturePhoto?>().firstWhere(
      (p) => p?.angle == angle,
      orElse: () => null,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.carbon3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Coluna Antes (Baseline)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ANTES (1ª Avaliação)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: basePhoto != null
                          ? PrivateDocumentImage(reference: basePhoto.url)
                          : const Center(
                              child: Text(
                                'Sem foto inicial',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.steel,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Coluna Depois (Atual)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DEPOIS (Atual)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: currentPhoto != null
                          ? PrivateDocumentImage(reference: currentPhoto.url)
                          : const Center(
                              child: Text(
                                'Sem foto atual',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.steel,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Comparativo postural: Ângulo ${angle.label}',
            style: const TextStyle(fontSize: 12, color: AppColors.steel),
          ),
        ],
      ),
    );
  }
}
