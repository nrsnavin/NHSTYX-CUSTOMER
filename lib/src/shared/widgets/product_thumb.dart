import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

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

  /// Makes a stored image URL loadable from this device:
  /// - relative paths (e.g. `/uploads/x.jpg`) are resolved against the API host;
  /// - dev loopback hosts (localhost / 127.0.0.1) — e.g. an image uploaded from
  ///   the web console — are rewritten to the configured API host so an emulator
  ///   or phone can actually reach them;
  /// - any other absolute URL (a CDN photo) is used as-is.
  static String? _resolve(String? url) {
    if (url == null || url.isEmpty) return null;
    final api = Uri.parse(AppConfig.apiBaseUrl);
    if (url.startsWith('/')) {
      return '${api.scheme}://${api.host}:${api.port}$url';
    }
    final u = Uri.tryParse(url);
    if (u != null && (u.host == 'localhost' || u.host == '127.0.0.1')) {
      return u.replace(scheme: api.scheme, host: api.host, port: api.port).toString();
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Center(
      child: Icon(icon, size: 40, color: scheme.outline),
    );
    final resolved = _resolve(imageUrl);

    return Container(
      color: scheme.surfaceContainerHighest,
      width: double.infinity,
      height: double.infinity,
      child: resolved == null
          ? placeholder
          : Image.network(
              resolved,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
            ),
    );
  }
}
