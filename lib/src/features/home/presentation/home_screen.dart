import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/presentation/cart_controller.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../products/presentation/products_screen.dart';
import '../../profile/presentation/profile_screen.dart';

/// Selected bottom-nav tab. Shared so other screens (e.g. the shop's
/// "View cart" bar) can jump straight to the Cart tab.
final homeTabProvider = StateProvider<int>((ref) => 0);

/// Bottom-navigation shell. Each tab is a full screen with its own app bar.
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
          CartScreen(),
          OrdersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(homeTabProvider.notifier).state = i,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
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
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
