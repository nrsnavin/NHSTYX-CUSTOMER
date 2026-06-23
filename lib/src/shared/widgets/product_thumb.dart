import 'package:flutter/material.dart';

/// Square-ish product image area with a tinted placeholder + icon fallback.
/// Fills its parent; wrap in AspectRatio / SizedBox to size it.
class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    this.imageUrl,
    this.icon = Icons.checkroom_outlined,
  });

  final String? imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Center(
      child: Icon(icon, size: 40, color: scheme.outline),
    );

    return Container(
      color: scheme.surfaceContainerHighest,
      width: double.infinity,
      height: double.infinity,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? placeholder
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
            ),
    );
  }
}
