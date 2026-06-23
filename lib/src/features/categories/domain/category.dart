class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.children = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final List<Category> children;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      imageUrl: json['imageUrl'] as String?,
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
