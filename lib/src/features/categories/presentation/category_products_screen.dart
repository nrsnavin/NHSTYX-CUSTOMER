import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/product_card.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../products/presentation/products_controller.dart';
import '../domain/category.dart';

const _sortOptions = <(String, String)>[
  ('NEWEST', 'Newest'),
  ('PRICE_ASC', 'Price: Low to High'),
  ('PRICE_DESC', 'Price: High to Low'),
  ('NAME', 'Name: A to Z'),
];

// (label, minPaise, maxPaise)
const _pricePresets = <(String, int?, int?)>[
  ('Under ₹200', null, 20000),
  ('₹200 – ₹500', 20000, 50000),
  ('₹500 – ₹1,000', 50000, 100000),
  ('Over ₹1,000', 100000, null),
];

String _sortLabel(String code) =>
    _sortOptions.firstWhere((o) => o.$1 == code, orElse: () => _sortOptions.first).$2;

/// A dedicated page listing the products of one category, with sub-category
/// chips plus filter + sort controls.
class CategoryProductsScreen extends ConsumerStatefulWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final Category category;

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  String? _subId; // null = whole category (parent includes children server-side)
  String _sort = 'NEWEST';
  String? _brand;
  int? _priceIdx;
  bool _inStock = false;

  bool get _hasFilters => _brand != null || _priceIdx != null || _inStock;

  Future<void> _openSortSheet() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort by', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            for (final (code, label) in _sortOptions)
              ListTile(
                title: Text(label),
                trailing: _sort == code
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, code),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen != null) setState(() => _sort = chosen);
  }

  Future<void> _openFilterSheet() async {
    String? tempBrand = _brand;
    int? tempPrice = _priceIdx;
    bool tempInStock = _inStock;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetHandle(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filters', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      TextButton(
                        onPressed: () => setSheet(() {
                          tempBrand = null;
                          tempPrice = null;
                          tempInStock = false;
                        }),
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('In stock only'),
                    value: tempInStock,
                    onChanged: (v) => setSheet(() => tempInStock = v),
                  ),
                  const SizedBox(height: 4),
                  const Text('Price', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _pricePresets.length; i++)
                        ChoiceChip(
                          label: Text(_pricePresets[i].$1),
                          selected: tempPrice == i,
                          showCheckmark: false,
                          onSelected: (s) => setSheet(() => tempPrice = s ? i : null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Brand', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (ctx, ref2, _) {
                      final brands = ref2.watch(storeBrandsProvider);
                      return brands.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (list) => list.isEmpty
                            ? Text('No brands available',
                                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant))
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final b in list)
                                    ChoiceChip(
                                      label: Text(b),
                                      selected: tempBrand == b,
                                      showCheckmark: false,
                                      onSelected: (s) => setSheet(() => tempBrand = s ? b : null),
                                    ),
                                ],
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (applied == true) {
      setState(() {
        _brand = tempBrand;
        _priceIdx = tempPrice;
        _inStock = tempInStock;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final children = category.children;
    final effectiveId = _subId ?? category.id;
    final preset = _priceIdx != null ? _pricePresets[_priceIdx!] : null;
    final ProductQuery query = (
      categoryId: effectiveId,
      sort: _sort,
      brand: _brand,
      minPaise: preset?.$2,
      maxPaise: preset?.$3,
      inStock: _inStock,
    );
    final productsAsync = ref.watch(filteredCategoryProductsProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: Column(
        children: [
          if (children.isNotEmpty)
            _SubCategoryRail(
              parent: category,
              selectedId: _subId,
              onSelect: (id) => setState(() => _subId = id),
            ),
          _FilterSortBar(
            sortLabel: _sortLabel(_sort),
            filtersActive: _hasFilters,
            onSort: _openSortSheet,
            onFilter: _openFilterSheet,
          ),
          Expanded(
            child: AsyncValueView<List<Product>>(
              value: productsAsync,
              onRetry: () => ref.invalidate(filteredCategoryProductsProvider(query)),
              loading: () => const ProductGridSkeleton(),
              data: (products) {
                if (products.isEmpty) return const _EmptyCategory();
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(filteredCategoryProductsProvider(query)),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, i) {
                      final p = products[i];
                      return ProductCard(
                        product: p,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSortBar extends StatelessWidget {
  const _FilterSortBar({
    required this.sortLabel,
    required this.filtersActive,
    required this.onSort,
    required this.onFilter,
  });

  final String sortLabel;
  final bool filtersActive;
  final VoidCallback onSort;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onSort,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.swap_vert, size: 20),
                    const SizedBox(width: 6),
                    Flexible(child: Text(sortLabel, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 24, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: InkWell(
              onTap: onFilter,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tune,
                        size: 20, color: filtersActive ? theme.colorScheme.primary : null),
                    const SizedBox(width: 6),
                    Text('Filter',
                        style: TextStyle(
                            color: filtersActive ? theme.colorScheme.primary : null,
                            fontWeight: filtersActive ? FontWeight.w700 : FontWeight.w500)),
                    if (filtersActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

/// Horizontal "All · sub-category" selector for a parent category.
class _SubCategoryRail extends StatelessWidget {
  const _SubCategoryRail({required this.parent, required this.selectedId, required this.onSelect});

  final Category parent;
  final String? selectedId;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _Chip(label: 'All', selected: selectedId == null, onTap: () => onSelect(null)),
          for (final c in parent.children)
            _Chip(label: c.name, selected: selectedId == c.id, onTap: () => onSelect(c.id)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        selectedColor: scheme.primary,
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('No products match your filters', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
