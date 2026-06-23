import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhstyx_customer/src/features/categories/data/category_repository.dart';
import 'package:nhstyx_customer/src/features/categories/domain/category.dart';
import 'package:nhstyx_customer/src/features/products/data/product_repository.dart';
import 'package:nhstyx_customer/src/features/products/domain/product.dart';
import 'package:nhstyx_customer/src/features/products/presentation/product_card.dart';
import 'package:nhstyx_customer/src/features/products/presentation/products_screen.dart';

class _FakeProductRepo implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts({
    String? search,
    String? categoryId,
    int page = 1,
    int limit = 40,
  }) async {
    return const [
      Product(
        id: 'p1',
        name: 'Test Cotton Kurti',
        unit: 'PIECE',
        pricePaise: 32000,
        gstRatePercent: 5,
        moqQty: 6,
        stockQty: 100,
      ),
    ];
  }
}

class _FakeCategoryRepo implements CategoryRepository {
  @override
  Future<List<Category>> fetchCategories() async {
    return const [Category(id: 'c1', name: 'Apparel', slug: 'apparel')];
  }
}

void main() {
  testWidgets('Shop screen renders search, category rail and product grid',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(_FakeProductRepo()),
          categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepo()),
        ],
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );

    // Let the category + product futures resolve.
    await tester.pumpAndSettle();

    expect(find.text('NH Styx'), findsOneWidget);
    expect(find.text('Search anything for your store…'), findsOneWidget);
    expect(find.text('All'), findsOneWidget); // category rail
    expect(find.text('Apparel'), findsOneWidget);
    expect(find.byType(ProductCard), findsOneWidget);
    expect(find.text('Test Cotton Kurti'), findsOneWidget);
  });
}
