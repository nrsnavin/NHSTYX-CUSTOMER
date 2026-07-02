import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../shared/widgets/document_loading_view.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';

/// In-app GST invoice viewer for a paid order. Fetches the PDF from the API
/// and renders it with print / share / save actions.
class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice · ${order.orderNumber}')),
      body: FutureBuilder<Uint8List>(
        future: ref.read(orderRepositoryProvider).fetchInvoice(order.id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const DocumentLoadingView(label: 'Preparing your invoice…');
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 12),
                    Text(snap.error.toString(), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          final bytes = snap.data ?? Uint8List(0);
          return PdfPreview(
            build: (_) => bytes,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: 'invoice_${order.orderNumber}.pdf',
          );
        },
      ),
    );
  }
}
