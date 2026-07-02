import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders an [AsyncValue]: a spinner while loading, a retry view on error,
/// and [data] when available.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  /// Optional custom loading view (e.g. a skeleton). Defaults to a spinner.
  final Widget Function()? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading?.call() ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(error: error, onRetry: onRetry),
    );
  }
}

/// Friendly, non-alarming error state. `ApiException.toString()` already yields
/// a human message ("Check your network"); anything unexpected falls back to a
/// generic line rather than a stack-y string.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final raw = error.toString();
    // Only show the message if it reads like human copy, not a runtime dump.
    final friendly = (raw.isNotEmpty && !raw.contains('Exception:') && raw.length < 140)
        ? raw
        : 'Something went wrong. Please try again.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 40, color: theme.hintColor),
            ),
            const SizedBox(height: 18),
            Text("Couldn't load this", style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              friendly,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
