import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/formatters.dart';
import '../data/quotation_repository.dart';
import '../domain/quotation.dart';
import 'quotations_controller.dart';
import 'quotations_screen.dart';

class QuotationDetailScreen extends ConsumerStatefulWidget {
  const QuotationDetailScreen({super.key, required this.quotationId});

  final String quotationId;

  @override
  ConsumerState<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends ConsumerState<QuotationDetailScreen> {
  bool _busy = false;

  Future<void> _respond(String action) async {
    setState(() => _busy = true);
    try {
      await ref.read(quotationRepositoryProvider).respond(widget.quotationId, action);
      ref.invalidate(quotationDetailProvider(widget.quotationId));
      ref.invalidate(myQuotationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(action == 'ACCEPT' ? 'Quotation accepted' : 'Quotation declined')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(quotationDetailProvider(widget.quotationId));
    return Scaffold(
      appBar: AppBar(
        title: Text(async.valueOrNull?.quoteNumber ?? 'Quotation'),
        actions: [
          if (async.valueOrNull != null)
            IconButton(
              tooltip: 'View PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _QuotationPdfScreen(
                    quotationId: widget.quotationId,
                    quoteNumber: async.valueOrNull!.quoteNumber,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (quote) => _QuoteBody(quote: quote),
      ),
      bottomNavigationBar: async.valueOrNull?.canRespond == true ? _respondBar() : null,
    );
  }

  Widget _respondBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _respond('DECLINE'),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _busy ? null : () => _respond('ACCEPT'),
                child: _busy
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Accept quote'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteBody extends StatelessWidget {
  const _QuoteBody({required this.quote});

  final Quotation quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                quote.title?.isNotEmpty == true ? quote.title! : 'Quotation',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            QuoteStatusChip(status: quote.status),
          ],
        ),
        if (quote.validUntil != null) ...[
          const SizedBox(height: 6),
          Text(
            'Valid until ${DateFormat('dd MMM yyyy').format(quote.validUntil!)}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        if (quote.orderNumber?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade800),
                const SizedBox(width: 8),
                Text('Converted to order ${quote.orderNumber}',
                    style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Items', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...quote.items.map((it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.variantName?.isNotEmpty == true
                            ? '${it.productName} · ${it.variantName}'
                            : it.productName),
                        Text('${it.quantity} × ${formatPaise(it.unitPricePaise)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text(formatPaise(it.lineTotalPaise), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            )),
        const Divider(height: 28),
        _totalRow(context, 'Subtotal', formatPaise(quote.subtotalPaise)),
        if (quote.taxPaise > 0) _totalRow(context, 'GST', formatPaise(quote.taxPaise)),
        if (quote.discountPaise > 0) _totalRow(context, 'Discount', '- ${formatPaise(quote.discountPaise)}'),
        const SizedBox(height: 4),
        _totalRow(context, 'Total', formatPaise(quote.totalPaise), bold: true),
        if (quote.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 24),
          Text('Notes / terms', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(quote.notes!, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _totalRow(BuildContext context, String label, String value, {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

/// In-app PDF viewer for a quotation (print / share / save).
class _QuotationPdfScreen extends ConsumerWidget {
  const _QuotationPdfScreen({required this.quotationId, required this.quoteNumber});

  final String quotationId;
  final String quoteNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Quote · $quoteNumber')),
      body: FutureBuilder<Uint8List>(
        future: ref.read(quotationRepositoryProvider).fetchPdf(quotationId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(snap.error.toString(), textAlign: TextAlign.center),
              ),
            );
          }
          final bytes = snap.data ?? Uint8List(0);
          return PdfPreview(
            build: (_) => bytes,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: 'quote_$quoteNumber.pdf',
          );
        },
      ),
    );
  }
}
