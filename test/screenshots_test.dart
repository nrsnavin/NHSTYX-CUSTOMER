import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhstyx_customer/src/core/theme/app_theme.dart';
import 'package:nhstyx_customer/src/features/auth/domain/customer.dart';
import 'package:nhstyx_customer/src/features/auth/presentation/auth_controller.dart';
import 'package:nhstyx_customer/src/features/categories/data/category_repository.dart';
import 'package:nhstyx_customer/src/features/categories/domain/category.dart';
import 'package:nhstyx_customer/src/features/products/data/product_repository.dart';
import 'package:nhstyx_customer/src/features/products/domain/product.dart';
import 'package:nhstyx_customer/src/features/products/presentation/products_screen.dart';
import 'package:nhstyx_customer/src/features/orders/domain/order.dart';
import 'package:nhstyx_customer/src/features/orders/presentation/orders_controller.dart';
import 'package:nhstyx_customer/src/features/orders/presentation/orders_screen.dart';
import 'package:nhstyx_customer/src/features/profile/presentation/gst_details_screen.dart';
import 'package:nhstyx_customer/src/features/profile/presentation/profile_screen.dart';
import 'package:nhstyx_customer/src/features/wishlist/data/wishlist_repository.dart';
import 'package:nhstyx_customer/src/features/wishlist/presentation/wishlist_controller.dart';
import 'package:nhstyx_customer/src/features/wishlist/presentation/wishlist_screen.dart';

/// Renders the new/changed screens to PNGs in docs/screenshots/ so the UI can
/// be reviewed without a device. Run with:
///   flutter test test/screenshots_test.dart --update-goldens

const _customer = Customer(
  id: 'c1',
  shopName: 'Trendy Threads Boutique',
  phone: '9876543210',
  ownerName: 'Anita Sharma',
  email: 'anita@trendythreads.in',
  gstin: '27ABCDE1234F1Z5',
  store: CustomerStore(id: 's1', name: 'NH Styx Pune', city: 'Pune', phone: '02041234567'),
);

List<Product> _catalog() => const [
      Product(id: 'p1', name: 'Cotton Kurti — Floral', unit: 'PIECE', pricePaise: 32000, gstRatePercent: 5, moqQty: 6, stockQty: 120),
      Product(id: 'p2', name: 'Silk Saree — Maroon', unit: 'PIECE', pricePaise: 145000, gstRatePercent: 5, moqQty: 2, stockQty: 40),
      Product(id: 'p3', name: 'Denim Jeans — Slim', unit: 'PIECE', pricePaise: 78000, gstRatePercent: 12, moqQty: 4, stockQty: 0),
      Product(id: 'p4', name: 'Kids T-Shirt Pack', unit: 'PACK', pricePaise: 54000, gstRatePercent: 5, moqQty: 5, stockQty: 75),
    ];

class _FakeProductRepo implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts({String? search, String? categoryId, int page = 1, int limit = 40}) async =>
      _catalog();
  @override
  Future<List<Product>> fetchBestSelling() async => _catalog().take(3).toList();
  @override
  Future<List<Product>> fetchRecentlyOrdered() async => const [];
  @override
  Future<Product> fetchProduct(String id) async =>
      _catalog().firstWhere((p) => p.id == id, orElse: () => _catalog().first);
}

class _FakeCategoryRepo implements CategoryRepository {
  @override
  Future<List<Category>> fetchCategories() async => const [
        Category(id: 'c1', name: 'Apparel', slug: 'apparel'),
        Category(id: 'c2', name: 'Sarees', slug: 'sarees'),
        Category(id: 'c3', name: 'Kids', slug: 'kids'),
        Category(id: 'c4', name: 'Footwear', slug: 'footwear'),
      ];
}

class _FakeWishlistRepo implements WishlistRepository {
  @override
  Future<List<Product>> list() async => _catalog().take(2).toList();
  @override
  Future<Set<String>> ids() async => {'p1', 'p2'};
  @override
  Future<void> add(String productId) async {}
  @override
  Future<void> remove(String productId) async {}
}

class _FakeAuth extends AuthController {
  @override
  Future<Customer?> build() async => _customer;
}

Future<void> _loadFonts() async {
  Future<void> load(String family, String path) async {
    final bytes = File(path).readAsBytesSync();
    final loader = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }

  await load('Roboto', '/opt/flutter/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf');
  await load('MaterialIcons', '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
}

ThemeData get _theme {
  final t = AppTheme.light;
  return t.copyWith(
    textTheme: t.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: t.primaryTextTheme.apply(fontFamily: 'Roboto'),
    // The theme's AppBar title and filled-button text styles have no family;
    // force Roboto so they don't render as Ahem boxes under the test runner.
    appBarTheme: t.appBarTheme.copyWith(
      titleTextStyle: t.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'Roboto'),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: (t.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStatePropertyAll(
          (t.filledButtonTheme.style?.textStyle?.resolve({}) ?? const TextStyle())
              .copyWith(fontFamily: 'Roboto'),
        ),
      ),
    ),
  );
}

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget screen, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(1100, 2200);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuth.new),
        ...overrides,
      ],
      child: MaterialApp(theme: _theme, home: screen),
    ),
  );
  // Fixed frames instead of pumpAndSettle (some skeleton shimmers never settle).
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('../docs/screenshots/$name.png'));
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    // The Dio token interceptor reads flutter_secure_storage; without the
    // platform plugin it throws MissingPluginException. Stub it so unrelated
    // background fetches (cart, etc.) fail quietly instead of crashing renders.
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'readAll') return <String, String>{};
      return null;
    });
  });

  testWidgets('home — sticky search + category tabs', (tester) async {
    await _shoot(
      tester,
      'home_sticky',
      const ProductsScreen(),
      overrides: [
        productRepositoryProvider.overrideWithValue(_FakeProductRepo()),
        categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepo()),
        wishlistIdsProvider.overrideWith(() => _FakeWishlistIds({'p1'})),
      ],
    );
  });

  testWidgets('account — profile menu', (tester) async {
    await _shoot(tester, 'account', const ProfileScreen());
  });

  testWidgets('wishlist', (tester) async {
    await _shoot(
      tester,
      'wishlist',
      const WishlistScreen(),
      overrides: [
        wishlistRepositoryProvider.overrideWithValue(_FakeWishlistRepo()),
        wishlistProvider.overrideWith((ref) async => _catalog().take(2).toList()),
        wishlistIdsProvider.overrideWith(() => _FakeWishlistIds({'p1', 'p2'})),
      ],
    );
  });

  testWidgets('gst details', (tester) async {
    await _shoot(tester, 'gst_details', const GstDetailsScreen());
  });

  testWidgets('orders', (tester) async {
    await _shoot(
      tester,
      'orders',
      const OrdersScreen(),
      overrides: [ordersProvider.overrideWith((ref) async => _orders())],
    );
  });
}

List<Order> _orders() => [
      Order(
        id: 'o1',
        orderNumber: 'ORD-2026-00018',
        status: 'DELIVERED',
        paymentStatus: 'PAID',
        paymentMethod: 'BANK_TRANSFER',
        subtotalPaise: 405000,
        cgstPaise: 10125,
        sgstPaise: 10125,
        totalPaise: 427500,
        amountDuePaise: 0,
        createdAt: DateTime(2026, 6, 24, 15, 12),
        items: const [
          OrderItem(productName: 'Cotton Kurti', variantName: 'Red / M', quantity: 3, unitPricePaise: 32000, lineTotalPaise: 100800, productId: 'p1'),
          OrderItem(productName: 'Silk Saree', variantName: 'Blue / L', quantity: 2, unitPricePaise: 34000, lineTotalPaise: 71400, productId: 'p2'),
        ],
      ),
      Order(
        id: 'o2',
        orderNumber: 'ORD-2026-00017',
        status: 'PENDING',
        paymentStatus: 'UNPAID',
        paymentMethod: 'RAZORPAY',
        subtotalPaise: 96000,
        totalPaise: 100800,
        amountDuePaise: 100800,
        createdAt: DateTime(2026, 6, 23, 11, 5),
        items: const [
          OrderItem(productName: 'Denim Jeans', quantity: 4, unitPricePaise: 24000, lineTotalPaise: 100800, productId: 'p3'),
        ],
      ),
    ];

class _FakeWishlistIds extends WishlistIdsController {
  _FakeWishlistIds(this._ids);
  final Set<String> _ids;
  @override
  Future<Set<String>> build() async => _ids;
}
