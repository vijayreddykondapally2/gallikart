// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loader.dart';
import '../../routes/app_routes.dart';
import '../cart/cart_controller.dart';
import 'catalog_controller.dart';
import 'models/product.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  int _selectedIndex = 0;
  late final TextEditingController _searchController;
  String? _selectedCategory;

  static const Map<String, String> categoryImages = {
    'Vegetables':
        'https://images.pexels.com/photos/2329440/pexels-photo-2329440.jpeg',
    'Fruits':
        'https://images.pexels.com/photos/1132047/pexels-photo-1132047.jpeg',
    'Groceries':
        'https://images.pexels.com/photos/264636/pexels-photo-264636.jpeg',
    'Milk & Daily Needs':
        'https://images.pexels.com/photos/236010/pexels-photo-236010.jpeg',
  };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, AppRoutes.cart);
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.orders);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.recursive);
        break;
    }
  }

  void _addToCart(Product product, WidgetRef ref) {
    ref.read(cartControllerProvider.notifier).add(product);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(catalogControllerProvider);
        final cartItems = ref.watch(cartControllerProvider);
        final cartQty = cartItems.fold(0, (sum, item) => sum + item.quantity);
        return Scaffold(
          backgroundColor: Colors.green.shade100,
          appBar: AppBar(
            leading: _selectedCategory != null &&
                    _searchController.text.trim().isEmpty
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _selectedCategory = null),
                  )
                : null,
            title: Row(
              children: [
                Image.asset('assets/logo.png', height: 32, width: 32),
                const SizedBox(width: 8),
                Text(
                  _selectedCategory != null &&
                          _searchController.text.trim().isEmpty
                      ? _selectedCategory!
                      : AppStrings.catalogTitle,
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
                icon: const Icon(Icons.person_outline),
              ),
              IconButton(
                onPressed: () =>
                    ref.read(catalogControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: state.when(
            data: (products) {
              if (products.isEmpty) {
                return const Center(
                  child: Text('No active products available.'),
                );
              }
              final lowerSearch = _searchController.text.trim().toLowerCase();
              final isSearching = lowerSearch.isNotEmpty;
              final List<Product> searchResults = isSearching
                  ? products.where((product) {
                      final productName = product.name.toLowerCase();
                      final productCategory = product.category.toLowerCase();
                      return productName.contains(lowerSearch) ||
                          productCategory.contains(lowerSearch);
                    }).toList()
                  : const <Product>[];
              final List<Product> categoryProducts =
                  !isSearching && _selectedCategory != null
                      ? products
                          .where(
                            (product) => _primaryCategory(product.category) ==
                                _selectedCategory,
                          )
                          .toList()
                      : const [];
              final categorySummaries = _buildCategorySummaries(products);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search groceries',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: isSearching
                        ? _buildProductListView(
                            title: 'Search results',
                            products: searchResults,
                            emptyMessage:
                                'No results for "${_searchController.text.trim()}"',
                            ref: ref,
                          )
                        : _selectedCategory != null
                            ? _buildProductListView(
                                title: '$_selectedCategory items',
                                products: categoryProducts,
                                emptyMessage: 'No items in $_selectedCategory',
                                ref: ref,
                              )
                            : _buildCategoryGridView(categorySummaries),
                  ),
                ],
              );
            },
            loading: () => const Loader(),
            error: (error, _) => ErrorView(message: error.toString()),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cartQty > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartQty > 99 ? '99+' : '$cartQty',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Cart',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Orders',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.repeat),
                label: 'Recursive',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey.shade600,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }

  Widget _buildProductListView({
    required String title,
    required List<Product> products,
    required String emptyMessage,
    required WidgetRef ref,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: products.isEmpty
              ? Center(
                  child: Text(
                    emptyMessage,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildProductCard(products[index], ref),
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, WidgetRef ref) {
    final cartItems = ref.watch(cartControllerProvider);
    final quantity = cartItems
        .where((item) => item.product.id == product.id)
        .fold(0, (sum, item) => sum + item.quantity);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print(
                            'Image load failed for ${product.name}: $error',
                          );
                          return Center(
                            child: Text(
                              product.name.isNotEmpty
                                  ? product.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          product.name.isNotEmpty
                              ? product.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(product.price),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Stock: ${product.stock}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (quantity > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => ref
                            .read(cartControllerProvider.notifier)
                            .decrement(product.id),
                        icon: const Icon(
                          Icons.remove,
                          size: 18,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: product.stock > quantity
                            ? () => _addToCart(product, ref)
                            : null,
                        icon: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: product.stock > 0
                        ? () => _addToCart(product, ref)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(96, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGridView(List<_CategoryTileData> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories available.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          onTap: () => setState(() => _selectedCategory = category.name),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: categoryImages[category.name] != null
                        ? Image.network(
                            categoryImages[category.name]!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.category,
                              size: 48,
                              color: Colors.grey,
                            ),
                          )
                        : Icon(Icons.category, size: 48, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${category.count} items',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_CategoryTileData> _buildCategorySummaries(List<Product> products) {
    final Map<String, int> counts = {};
    for (final product in products) {
      final key = _primaryCategory(product.category);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries = counts.entries
        .map((entry) => _CategoryTileData(name: entry.key, count: entry.value))
        .toList();
    entries.sort((a, b) => a.name.compareTo(b.name));
    return entries;
  }

  String _primaryCategory(String category) {
    const delimiter = ' – ';
    final index = category.indexOf(delimiter);
    return index == -1 ? category : category.substring(0, index);
  }
}

class _CategoryTileData {
  const _CategoryTileData({required this.name, required this.count});

  final String name;
  final int count;
}
