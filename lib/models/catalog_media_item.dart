class CatalogMediaItem {
  const CatalogMediaItem({
    required this.id,
    required this.name,
    required this.equipment,
    required this.thumbnailUrl,
    required this.animationUrl,
    required this.attribution,
  });

  final String id;
  final String name;
  final String equipment;
  final String thumbnailUrl;
  final String animationUrl;
  final String attribution;

  factory CatalogMediaItem.fromJson(Map<String, dynamic> json) =>
      CatalogMediaItem(
        id: json['id'] as String,
        name: json['name'] as String,
        equipment: json['equipment'] as String,
        thumbnailUrl: json['thumbnail_url'] as String,
        animationUrl: json['animation_url'] as String,
        attribution: json['attribution'] as String,
      );
}
