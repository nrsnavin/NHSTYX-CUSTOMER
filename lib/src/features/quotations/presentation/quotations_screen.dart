import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/skeleton.dart';
import '../domain/quotation.dart';
import 'quotation_detail_screen.dart';
import 'quotations_controller.dart';

/// Status → (label colour) for quote chips. Kept here so the list + detail
/// screens stay visually consistent.
({Color bg, Color fg}) quoteStatusColors(BuildContext context, String status) {
  final scheme = Theme.of(context).colorScheme;
  switch (status) {
    case 'ACCEPTED':
    case 'CONVERTED':
      return (bg: Colors.green.shade50, fg: Colors.green.shade800);
    case 'DECLINED':
    case 'EXPIRED':
      return (bg: scheme.errorContainer, fg: scheme.onErrorContainer);
    case 'SENT':
      return (bg: scheme.primaryContainer, fg: scheme.onPrimaryContainer);
    default:
      return (bg: scheme.surfaceContainerHighest, fg: scheme.onSurfaceVariant);
  }
}

class QuoteStatusChip extends StatelessWidget {
  const QuoteStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final c = quoteStatusColors(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(color: c.fg, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

class QuotationsScreen extends ConsumerWidget {
  const QuotationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(myQuotationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Quotations')),
      body: quotes.when(
        loading: () => const ListCardSkeleton(itemCount: 4, height: 108),
        error: (e, _) => _ErrorState(message: e.toString(), onRetry: () => ref.invalidate(myQuotationsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myQuotationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _QuoteCard(quote: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final Quotation quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lapsing = quote.validUntil != null && quote.status == 'SENT';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuotationDetailScreen(quotationId: quote.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(quote.quoteNumber, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                QuoteStatusChip(status: quote.status),
              ],
            ),
            if (quote.title?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(quote.title!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Text(formatPaise(quote.totalPaise), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${quote.items.length} item${quote.items.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            if (quote.validUntil != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: lapsing ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Valid until ${DateFormat('dd MMM yyyy').format(quote.validUntil!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: lapsing ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.request_quote_outlined, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No quotations yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'When our team sends you a price quote, it will show up here for you to review and accept.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
