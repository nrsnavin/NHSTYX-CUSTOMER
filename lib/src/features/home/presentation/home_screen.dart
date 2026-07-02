import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/presentation/cart_controller.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../products/presentation/products_screen.dart';

/// Selected bottom-nav tab. Shared so other screens (e.g. the shop's
/// "View cart" bar) can jump to a tab. Order: 0 Home · 1 Categories ·
/// 2 Reorder · 3 Cart.
final homeTabProvider = StateProvider<int>((ref) => 0);

/// Bottom-navigation shell. Each tab is a full screen with its own app bar.
/// Profile lives in the Home top bar (avatar), Instamart-style.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final scheme = Theme.of(context).colorScheme;
    final index = ref.watch(homeTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          ProductsScreen(),
          CategoriesScreen(),
          OrdersScreen(),
          CartScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(homeTabProvider.notifier).state = i,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              backgroundColor: scheme.secondary,
              textColor: scheme.onSecondary,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              backgroundColor: scheme.secondary,
              textColor: scheme.onSecondary,
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
