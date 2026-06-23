import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/presentation/cart_controller.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/product_card.dart';
import '../../products/presentation/product_detail_screen.dart';
import 'search_controller.dart';

const _examples = [
  'Cotton kurtis under ₹300',
  'Packaging covers & bags',
  'Hangers for display',
  'Silk sarees',
  'Tags and labels',
];

class AiSearchScreen extends ConsumerStatefulWidget {
  const AiSearchScreen({super.key});

  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search(String q) {
    _controller.text = q;
    _focus.unfocus();
    ref.read(searchControllerProvider.notifier).run(q);
  }

  Future<void> _addToCart(Product product) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(cartControllerProvider.notifier).add(product.id, product.moqQty);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Added ${product.name} to cart'), duration: const Duration(seconds: 1)));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(searchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (q) => ref.read(searchControllerProvider.notifier).run(q),
          decoration: InputDecoration(
            hintText: 'Search anything for your store…',
            prefixIcon: const Icon(Icons.auto_awesome, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                ref.read(searchControllerProvider.notifier).clear();
              },
            ),
          ),
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(e.toString()))),
        data: (result) {
          if (result == null) return _Suggestions(onTap: _search);
          if (result.items.isEmpty) {
            return _Empty(reply: result.reply);
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(result.aiPowered ? Icons.auto_awesome : Icons.search,
                          size: 16, color: theme.hintColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(result.reply, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = result.items[i];
                      return ProductCard(
                        product: p,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                        ),
                        onAdd: () => _addToCart(p),
                      );
                    },
                    childCount: result.items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onTap});
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Try asking for…', style: theme.textTheme.titleSmall?.copyWith(color: theme.hintColor)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _examples
              .map((e) => ActionChip(
                    label: Text(e),
                    onPressed: () => onTap(e),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.reply});
  final String reply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No products matched', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(reply, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          ],
        ),
      ),
    );
  }
}
