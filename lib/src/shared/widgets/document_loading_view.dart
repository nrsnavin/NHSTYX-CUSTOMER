import 'package:flutter/material.dart';

/// Full-screen "we're preparing your document" state for the in-app PDF
/// viewers (invoice / quotation). A labelled spinner reassures the shopper
/// that generation is underway rather than the screen having stalled.
class DocumentLoadingView extends StatelessWidget {
  const DocumentLoadingView({super.key, this.label = 'Preparing your document…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_outlined, size: 44, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
