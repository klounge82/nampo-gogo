class Recommendation {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String address;
  final String description;
  final List<String> tags;
  final String? imageUrl;

  const Recommendation({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.address,
    required this.description,
    required this.tags,
    this.imageUrl,
  });
}
