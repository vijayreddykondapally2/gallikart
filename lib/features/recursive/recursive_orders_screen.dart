// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/money_utils.dart';
import '../catalog/catalog_controller.dart';
import '../catalog/models/product.dart';
import '../cart/cart_item.dart';
import '../cart/cart_controller.dart';
import '../orders/models/order.dart';
import '../orders/order_controller.dart';
import '../orders/payment_screen.dart';
import '../profile/profile_controller.dart';
import '../wallet/wallet_controller.dart';
import 'models/recursive_order.dart';
import 'recursive_order_controller.dart';
import 'recursive_orders_list_screen.dart';
import 'recursive_order_repository.dart';
import 'recursive_order_utils.dart';

class RecursiveOrdersScreen extends ConsumerStatefulWidget {
  const RecursiveOrdersScreen({super.key, this.initialOrder});

  final RecursiveOrder? initialOrder;

  @override
  ConsumerState<RecursiveOrdersScreen> createState() => _RecursiveOrdersScreenState();
}

class _RecursiveOrdersScreenState extends ConsumerState<RecursiveOrdersScreen> {
  static const _weekdayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Offsets align with Monday as week start: Mon=0 ... Sun=6.
  static const _weekdayOffsets = {
    'Monday': 0,
    'Tuesday': 1,
    'Wednesday': 2,
    'Thursday': 3,
    'Friday': 4,
    'Saturday': 5,
    'Sunday': 6,
  };

  final List<String> _modes = ['daily', 'weekly', 'monthly'];
  static const List<String> _specialCategories = [
    'Gym / Fitness',
    'Weight Loss',
    'Weight Gain',
    'Healthy Heart',
    'Sugar Control',
    'BP Control',
    'Cholesterol Control',
  ];
  static const Map<String, List<String>> _specialCategoryKeywords = {
    'Gym / Fitness': [
      'boiled egg',
      'paneer',
      'milk',
      'curd',
      'greek yogurt',
      'sprout',
      'peanut chikki',
      'banana',
      'protein ladoo',
      'peanut butter',
      'oats',
      'multigrain bread',
    ],
    'Weight Loss': [
      'cucumber',
      'carrot',
      'tomato',
      'bottle gourd',
      'lauki',
      'ridge gourd',
      'spinach',
      'cabbage',
      'salad',
      'abc juice',
      'lemon water',
      'ragi',
    ],
    'Weight Gain': [
      'banana',
      'sweet potato',
      'potato',
      'avocado',
      'date',
      'full cream milk',
      'peanut butter',
      'dry fruit',
      'energy bar',
      'poha',
    ],
    'Healthy Heart': [
      'apple',
      'pomegranate',
      'guava',
      'tomato',
      'spinach',
      'beetroot',
      'oats',
      'olive oil',
      'flax seed',
      'walnut',
      'low-fat milk',
      'abc juice',
    ],
    'Sugar Control': [
      'bitter gourd',
      'karela',
      'bottle gourd',
      'ridge gourd',
      'cucumber',
      'tomato',
      'spinach',
      'bean',
      'sprout',
      'ragi',
      'millet',
      'unsweetened curd',
      'herbal juice',
    ],
    'BP Control': [
      'banana',
      'spinach',
      'beetroot',
      'tomato',
      'cucumber',
      'carrot',
      'coconut water',
      'oats',
      'low-salt',
      'garlic',
      'lemon water',
    ],
    'Cholesterol Control': [
      'apple',
      'guava',
      'carrot',
      'bean',
      'okra',
      'lady',
      'oats',
      'barley',
      'flax seed',
      'almond',
      'walnut',
      'olive oil',
    ],
  };
  String _mode = 'daily';
  String _deliverySlot = '7:00 - 9:00 AM';
  bool _applyWallet = true;
  int _monthlyDay = DateTime.now().day.clamp(1, 28);
  bool _isEditing = false;

  final Map<String, int> _dailyItems = {};
  final Map<String, Map<String, int>> _weeklyItems = {
    for (final day in _weekdayOrder) day: {},
  };
  final Map<String, int> _monthlyItems = {};
  final Set<String> _initialCurrentProductIds = <String>{};
  final Map<String, Set<String>> _initialWeeklyProductIds = {
    for (final day in _weekdayOrder) day: <String>{},
  };
  late final Set<DateTime> _selectedWeeks;
  String _searchQuery = '';
  String _selectedWeekday = _weekdayOrder.first;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialOrder != null;
    final firstOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _selectedWeeks = {weekStart(firstOfMonth)};
    _selectedWeekday = _weekdayOrder.firstWhere(
      (day) => !_isWeeklyDayDisabled(day),
      orElse: () => _weekdayOrder.first,
    );
    if (widget.initialOrder != null) {
      _hydrateFromInitialOrder(widget.initialOrder!);
    }
  }

  void _hydrateFromInitialOrder(RecursiveOrder order) {
    _mode = order.frequency;
    _deliverySlot = order.deliveryTime ?? _deliverySlot;
    if (order.monthlyDay != null) {
      _monthlyDay = order.monthlyDay!.clamp(1, 28);
    }

    if (order.frequency == 'daily') {
      final casted = _castQuantityMap(order.items);
      _dailyItems
        ..clear()
        ..addAll(casted);
      _initialCurrentProductIds
        ..clear()
        ..addAll(casted.keys);
    } else if (order.frequency == 'monthly') {
      final casted = _castQuantityMap(order.items);
      _monthlyItems
        ..clear()
        ..addAll(casted);
      _initialCurrentProductIds
        ..clear()
        ..addAll(casted.keys);
    } else if (order.frequency == 'weekly') {
      final weekly = _parseWeeklyItems(order.items);
      for (final day in _weekdayOrder) {
        final dayItems = weekly[day] ?? <String, int>{};
        _weeklyItems[day] = Map<String, int>.from(dayItems);
        _initialWeeklyProductIds[day] = dayItems.keys.toSet();
      }
      _selectedWeeks
        ..clear()
        ..add(weekStart(order.plannedWeekStart ?? DateTime.now()));
      final firstDayWithItems = _weekdayOrder.firstWhere(
        (day) => (_weeklyItems[day] ?? {}).isNotEmpty,
        orElse: () => _selectedWeekday,
      );
      _selectedWeekday = firstDayWithItems;
      _ensureSelectedWeekday();
    }
  }

  Map<String, int> _castQuantityMap(Map<String, dynamic> source) {
    return source.map((key, value) {
      final qty = value is num ? value.toInt() : 0;
      return MapEntry(key, qty);
    });
  }

  Map<String, Map<String, int>> _parseWeeklyItems(Map<String, dynamic> source) {
    final weeklyBlock = source.containsKey('weekly') && source['weekly'] is Map
        ? Map<String, dynamic>.from(source['weekly'] as Map)
        : Map<String, dynamic>.from(source);
    final result = <String, Map<String, int>>{};
    weeklyBlock.forEach((day, items) {
      if (!_weekdayOffsets.containsKey(day)) return;
      final dayMap = Map<String, dynamic>.from((items as Map?) ?? {});
      result[day] = dayMap.map((id, qty) {
        final count = qty is num ? qty.toInt() : 0;
        return MapEntry(id, count);
      });
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecursiveOrdersListScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _modeTabs(),
          if (_mode != 'weekly') _deliverySlotRow(),
          Expanded(
            child: ref.watch(catalogControllerProvider).when(
                  data: (products) => _bodyContent(products),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Failed to load products: $err')),
                ),
          ),
        ],
      ),
    );
  }

  Widget _modeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _modes.map((m) {
          final label = m[0].toUpperCase() + m.substring(1);
          final selected = _mode == m;
          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.teal.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: selected,
            selectedColor: Colors.teal.shade600,
            backgroundColor: Colors.teal.shade50,
            side: BorderSide(
              color: selected ? Colors.transparent : Colors.teal.shade200,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (_) => setState(() => _mode = m),
          );
        }).toList(),
      ),
    );
  }

  Widget _deliverySlotRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text('Delivery slot:'),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _deliverySlot,
            items: _deliverySlots
                .map((slot) => DropdownMenuItem(value: slot, child: Text(slot)))
                .toList(),
            onChanged: (v) => setState(() => _deliverySlot = v ?? _deliverySlot),
          ),
        ],
      ),
    );
  }

  Widget _bodyContent(List<Product> products) {
    final profile = ref.watch(profileControllerProvider);
    return Column(
      children: [
        Expanded(
          child: Builder(
            builder: (_) {
              switch (_mode) {
                case 'weekly':
                  return _buildWeekly(products);
                case 'monthly':
                  return _buildMonthly(products);
                default:
                  return _buildDaily(products);
              }
            },
          ),
        ),
        _paymentRow(products, profile),
      ],
    );
  }

  Widget _paymentRow(List<Product> products, ProfileState profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecursiveOrdersListScreen()),
              ),
              child: const Text('Show orders'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () async => _submit(context, products, profile),
              child: const Text('Proceed'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaily(List<Product> products) {
    const orderedCategories = ['Fruits', 'Dairy', 'Vegetables', 'Meat', 'Health', 'Others'];
    return _productList(
      products,
      _dailyItems,
      (id, qty) => setState(() => _dailyItems[id] = qty),
      orderedCategories: orderedCategories,
      currentProductIds: _isEditing ? _initialCurrentProductIds : const <String>{},
      showSections: _isEditing,
      selectedCategory: _selectedCategory,
      onCategorySelected: (value) => setState(() => _selectedCategory = value),
    );
  }

  static const _deliverySlots = [
    '7:00 - 9:00 AM',
    '9:00 - 11:00 AM',
    '5:00 - 7:00 PM',
  ];

  DateTime _defaultWeekStart() {
    final firstOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return weekStart(firstOfMonth);
  }

  DateTime _activeWeekStart() {
    if (_selectedWeeks.isEmpty) return _defaultWeekStart();
    return _selectedWeeks.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime _dayDateFor(String day) {
    final offset = _weekdayOffsets[day] ?? 0;
    return _activeWeekStart().add(Duration(days: offset));
  }

  Widget _buildWeekly(List<Product> products) {
    final weeks = generateUpcomingWeekStarts(count: 10);
    const weeklyCategories = ['Fruits', 'Dairy', 'Vegetables', 'Meat', 'Health', 'Others'];
    final activeStart = _activeWeekStart();
    final activeEnd = activeStart.add(const Duration(days: 6));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: weeks.map((wk) {
              final start = weekStart(wk);
              final end = start.add(const Duration(days: 6));
              final label = 'Week of ${start.day.toString().padLeft(2, '0')} ${_monthLabel(start)} – ${end.day.toString().padLeft(2, '0')} ${_monthLabel(end)}';
              final disabled = end.isBefore(_todayCutoff());
              final selected = _selectedWeeks.any((d) => isSameDay(d, start));
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: disabled
                      ? null
                      : (_) => setState(() {
                            _selectedWeeks
                              ..clear()
                              ..add(start);
                            _ensureSelectedWeekday();
                          }),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Week of ${activeStart.day.toString().padLeft(2, '0')} ${_monthLabel(activeStart)} – ${activeEnd.day.toString().padLeft(2, '0')} ${_monthLabel(activeEnd)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _daySelector(),
        const SizedBox(height: 10),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search products',
            prefixIcon: Icon(Icons.search),
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SizedBox(
              height: 520,
              child: _weeklyProductArea(products, weeklyCategories),
            ),
          ),
        ),
      ],
    );
  }

  Widget _daySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _weekdayOrder.map((day) {
          final disabled = _isWeeklyDayDisabled(day);
          return Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: ChoiceChip(
              label: Text(
                day.substring(0, 3),
                style: const TextStyle(fontSize: 12),
              ),
              selected: _selectedWeekday == day,
              onSelected: disabled
                  ? null
                  : (_) => setState(() => _selectedWeekday = day),
              backgroundColor: disabled ? Colors.grey.shade200 : Colors.green.shade50,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _weeklyProductArea(List<Product> products, List<String> categories) {
    final dayItems = _weeklyItems[_selectedWeekday]!;
    final disabled = _isWeeklyDayDisabled(_selectedWeekday);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dayItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: dayItems.entries.map((e) {
                final product = products.firstWhere((p) => p.id == e.key);
                return Chip(
                  label: Text('${product.name} x${e.value}'),
                  onDeleted: () => setState(() => _weeklyItems[_selectedWeekday]?.remove(e.key)),
                  visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                );
              }).toList(),
            ),
          ),
        if (disabled)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text('Ordering closed for this day (post 4:00 AM).', style: TextStyle(color: Colors.grey)),
          ),
        Expanded(
          child: _productList(
            products,
            dayItems,
            (id, qty) => setState(() {
              if (qty <= 0) {
                _weeklyItems[_selectedWeekday]?.remove(id);
              } else {
                _weeklyItems[_selectedWeekday]?[id] = qty;
              }
            }),
            orderedCategories: categories,
            searchTerm: _searchQuery,
            dense: true,
            currentProductIds:
              _isEditing ? (_initialWeeklyProductIds[_selectedWeekday] ?? const <String>{}) : const <String>{},
            showSections: _isEditing,
            selectedCategory: _selectedCategory,
            onCategorySelected: (value) => setState(() => _selectedCategory = value),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthly(List<Product> products) {
    const monthlyCategories = [
      'Rice',
      'Oil',
      'Pulses',
      'Spices',
      'Household essentials',
      'Snacks',
      'Dairy',
      'Fruits',
      'Vegetables',
      'Meat',
      'Health',
      'Other monthly groceries',
      'Others'
    ];
    return Column(
      children: [
        ListTile(
          title: const Text('Delivery day of month'),
          trailing: DropdownButton<int>(
            value: _monthlyDay,
            items: List.generate(28, (i) => i + 1)
                .map((d) => DropdownMenuItem<int>(value: d, child: Text(d.toString())))
                .toList(),
            onChanged: (v) => setState(() => _monthlyDay = v ?? _monthlyDay),
          ),
        ),
        Expanded(
          child: _productList(
            products,
            _monthlyItems,
            (id, qty) => setState(() => _monthlyItems[id] = qty),
            orderedCategories: monthlyCategories,
            currentProductIds: _isEditing ? _initialCurrentProductIds : const <String>{},
            showSections: _isEditing,
            selectedCategory: _selectedCategory,
            onCategorySelected: (value) => setState(() => _selectedCategory = value),
          ),
        ),
      ],
    );
  }

  Widget _productList(
    List<Product> products,
    Map<String, int> selections,
    void Function(String, int) onQtyChange, {
    List<String>? orderedCategories,
    String searchTerm = '',
    bool dense = false,
    Set<String> currentProductIds = const <String>{},
    bool showSections = false,
    String? selectedCategory,
    ValueChanged<String?>? onCategorySelected,
  }) {
    final normalizedQuery = searchTerm.toLowerCase();
    final categories = _categoryOptions(products, orderedCategories);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: const Text(
            'Choose a category to quickly find products',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final cat = categories[index];
              final isSelected = selectedCategory == cat;
              final catProducts = _filterProductsByCategory(
                products: products,
                category: cat,
                searchTerm: normalizedQuery,
              );
              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.teal.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${catProducts.length} items'),
                      trailing: Icon(
                        isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.teal,
                      ),
                      onTap: onCategorySelected == null
                          ? null
                          : () => onCategorySelected!(isSelected ? null : cat),
                    ),
                    if (isSelected)
                      catProducts.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Text('No products found for this category.'),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: catProducts.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, prodIndex) {
                                final product = catProducts[prodIndex];
                                final qty = selections[product.id] ?? 0;
                                final isCurrent = showSections && currentProductIds.contains(product.id);
                                return ListTile(
                                  dense: dense,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  leading: isCurrent
                                      ? const Icon(Icons.check_circle, color: Colors.teal, size: 20)
                                      : null,
                                  title: Text(product.name),
                                  subtitle: Text(formatCurrency(product.price)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: qty > 0 ? () => onQtyChange(product.id, qty - 1) : null,
                                      ),
                                      Text(qty.toString()),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => onQtyChange(product.id, qty + 1),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<String> _categoryOptions(List<Product> products, List<String>? orderedCategories) {
    final options = <String>[];
    for (final cat in _specialCategories) {
      if (_productsForCategory(cat, products).isNotEmpty) {
        options.add(cat);
      }
    }

    final regularSeen = <String>{};
    final regularCategories = orderedCategories ?? products.map((p) => p.category).toSet().toList();
    for (final cat in regularCategories) {
      if (regularSeen.add(cat) && _productsForCategory(cat, products).isNotEmpty) {
        options.add(cat);
      }
    }

    for (final cat in products.map((p) => p.category)) {
      if (!options.contains(cat) && _productsForCategory(cat, products).isNotEmpty) {
        options.add(cat);
      }
    }
    return options;
  }

  List<Product> _productsForCategory(String category, List<Product> products) {
    return products.where((p) => _productCategories(p).contains(category)).toList();
  }

  List<Product> _filterProductsByCategory({
    required List<Product> products,
    String? category,
    String searchTerm = '',
  }) {
    final hasCategory = category != null && category.isNotEmpty;
    final hasSearch = searchTerm.isNotEmpty;

    if (!hasCategory && !hasSearch) {
      return const <Product>[];
    }

    return products.where((p) {
      final matchesCategory = hasCategory ? _productCategories(p).contains(category) : true;
      if (!matchesCategory) return false;
      if (!hasSearch) return true;
      final normalizedName = _normalize(p.name);
      final normalizedCat = _normalize(p.category);
      return normalizedName.contains(searchTerm) || normalizedCat.contains(searchTerm);
    }).toList();
  }

  Set<String> _productCategories(Product product) {
    final categories = <String>{product.category};
    final normalizedName = _normalize(product.name);
    _specialCategoryKeywords.forEach((cat, keywords) {
      final matches = keywords.any((keyword) => normalizedName.contains(keyword));
      if (matches) categories.add(cat);
    });
    return categories;
  }

  String _normalize(String value) => value.toLowerCase();

  Future<void> _submit(
    BuildContext context,
    List<Product> products,
    ProfileState profileState,
  ) async {
    if (_mode == 'weekly') {
      final weeklyClean = _collectWeeklySelections();
      if (weeklyClean.isEmpty) {
        _warn(context, 'Add at least one product across the week.');
        return;
      }
      final proceed = await _showWeeklyReview(context, weeklyClean, products);
      if (proceed != true) return;
    }

    final address = await _pickAddress(context, profileState);
    if (address == null) return;

    final userId = _resolveUserId(profileState);
    final plannedWeekStart = _mode == 'weekly' ? _activeWeekStart() : null;
    final deliveryWeekStart = _resolveDeliveryWeek(
      plannedWeekStart: plannedWeekStart,
      monthlyDay: _mode == 'monthly' ? _monthlyDay : null,
    );
    final isDuplicate = await _checkDuplicateOrder(
      context: context,
      address: address,
      profileState: profileState,
      deliveryWeekStart: deliveryWeekStart,
    );
    if (isDuplicate) return;

    if (_mode == 'daily') {
      await _saveDaily(context, products, address, userId, deliveryWeekStart);
    } else if (_mode == 'weekly') {
      await _saveWeekly(context, products, address, userId, plannedWeekStart ?? deliveryWeekStart);
    } else {
      await _saveMonthly(context, products, address, userId, deliveryWeekStart);
    }
  }

  Future<void> _saveDaily(
    BuildContext context,
    List<Product> products,
    DeliveryLocation address,
    String userId,
    DateTime deliveryWeekStart,
  ) async {
    final items = Map<String, int>.from(_dailyItems)..removeWhere((_, q) => q <= 0);
    if (items.isEmpty) {
      _warn(context, 'Add at least one product.');
      return;
    }
    final total = _sum(items, products);
    final priorTotal = widget.initialOrder?.currentAmount ?? 0;
    final basePaid = widget.initialOrder?.basePaidAmount ?? total;
    final delta = total - priorTotal;
    final dayTotals = <String, double>{'Daily': total};
    await _handleSave(
      context,
      products,
      items,
      total,
      basePaid,
      delta,
      address,
      userId,
      deliveryWeekStart,
      plannedWeekStart: null,
      monthlyDay: null,
      dayTotals: dayTotals,
    );
  }

  String _resolveUserId(ProfileState profileState) {
    final phone = profileState.phone?.trim();
    if (phone != null && phone.isNotEmpty) return phone;
    final name = profileState.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'local-user';
  }

  String _addressKey(DeliveryLocation address) {
    final label = address.label?.trim().isNotEmpty == true ? address.label!.trim() : 'addr';
    return '$label|${address.address.trim()}';
  }

  DateTime _resolveDeliveryWeek({DateTime? plannedWeekStart, int? monthlyDay}) {
    if (_mode == 'weekly') {
      return weekStart(plannedWeekStart ?? _activeWeekStart());
    }
    if (_mode == 'monthly') {
      final now = DateTime.now();
      final target = DateTime(now.year, now.month, monthlyDay ?? now.day);
      return weekStart(target);
    }
    return weekStart(DateTime.now());
  }

  Future<bool> _checkDuplicateOrder({
    required BuildContext context,
    required DeliveryLocation address,
    required ProfileState profileState,
    required DateTime deliveryWeekStart,
  }) async {
    final repo = ref.read(recursiveOrderRepositoryProvider);
    final userId = _resolveUserId(profileState);
    final addressId = _addressKey(address);

    final duplicate = await repo.findDuplicate(
      userId: userId,
      deliveryWeekStart: deliveryWeekStart,
      addressId: addressId,
      frequency: _mode,
    );

    if (duplicate != null && duplicate.id != widget.initialOrder?.id) {
      await _showDuplicateDialog(context, duplicate);
      return true;
    }
    return false;
  }

  Future<void> _showDuplicateDialog(
    BuildContext context,
    RecursiveOrder duplicate,
  ) async {
    final navigator = Navigator.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Order already exists'),
          content: const Text(
            'You already have an active order for this address for this week.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => RecursiveOrdersScreen(initialOrder: duplicate),
                  ),
                );
              },
              child: const Text('Edit Existing Order'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveWeekly(
    BuildContext context,
    List<Product> products,
    DeliveryLocation address,
    String userId,
    DateTime plannedWeekStart,
  ) async {
    final weeklyClean = _collectWeeklySelections();
    if (weeklyClean.isEmpty) {
      _warn(context, 'Add at least one product across the week.');
      return;
    }
    final perWeekTotal = weeklyClean.values
        .map((dayItems) => _sum(dayItems, products))
        .fold<double>(0, (a, b) => a + b);
    final weeks = _selectedWeeks.isEmpty ? [weekStart(DateTime.now())] : _selectedWeeks.toList();
    final total = perWeekTotal * weeks.length;
    final basePaid = widget.initialOrder?.basePaidAmount ?? total;
    final priorTotal = widget.initialOrder?.currentAmount ?? 0;
    final delta = total - priorTotal;
    final deliveryWeekStart = weekStart(weeks.first);
    final dayTotals = _dayTotalsForWeekly(weeklyClean, products, multiplier: weeks.length.toDouble());

    await _handleSave(
      context,
      products,
      {'weekly': weeklyClean},
      total,
      basePaid,
      delta,
      address,
      userId,
      deliveryWeekStart,
      plannedWeekStart: weeks.first,
      monthlyDay: null,
      dayTotals: dayTotals,
    );
  }

  Map<String, Map<String, int>> _collectWeeklySelections() {
    final weeklyClean = <String, Map<String, int>>{};
    for (final entry in _weeklyItems.entries) {
      final filtered = Map<String, int>.from(entry.value)..removeWhere((_, q) => q <= 0);
      if (filtered.isNotEmpty) weeklyClean[entry.key] = filtered;
    }
    return weeklyClean;
  }

  Map<String, double> _dayTotalsForWeekly(
    Map<String, Map<String, int>> weekly,
    List<Product> products, {
    double multiplier = 1,
  }) {
    final totals = <String, double>{};
    weekly.forEach((day, items) {
      totals[day] = _sum(items, products) * multiplier;
    });
    return totals;
  }

  Future<bool?> _showWeeklyReview(
    BuildContext context,
    Map<String, Map<String, int>> weeklyClean,
    List<Product> products,
  ) {
    final daySummaries = _weekdayOrder
        .where((d) => weeklyClean.containsKey(d))
        .map((day) {
      final items = weeklyClean[day]!;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...items.entries.map((e) {
              final product = products.firstWhere((p) => p.id == e.key);
              return Text('- ${product.name} x${e.value}');
            }),
          ],
        ),
      );
    }).toList();

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final media = MediaQuery.of(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: media.size.width * 0.9,
              maxHeight: media.size.height * 0.75,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Weekly plan summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: daySummaries,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveMonthly(
    BuildContext context,
    List<Product> products,
    DeliveryLocation address,
    String userId,
    DateTime deliveryWeekStart,
  ) async {
    final items = Map<String, int>.from(_monthlyItems)..removeWhere((_, q) => q <= 0);
    if (items.isEmpty) {
      _warn(context, 'Add at least one product.');
      return;
    }
    final total = _sum(items, products);
    final basePaid = widget.initialOrder?.basePaidAmount ?? total;
    final priorTotal = widget.initialOrder?.currentAmount ?? 0;
    final delta = total - priorTotal;
    final dayTotals = <String, double>{'Monthly': total};

    await _handleSave(
      context,
      products,
      items,
      total,
      basePaid,
      delta,
      address,
      userId,
      deliveryWeekStart,
      plannedWeekStart: null,
      monthlyDay: _monthlyDay,
      dayTotals: dayTotals,
    );
  }

  Future<void> _handleSave(
    BuildContext context,
    List<Product> products,
    Map<String, dynamic> items,
    double total,
    double basePaid,
    double delta,
    DeliveryLocation address,
    String userId,
    DateTime deliveryWeekStart, {
    DateTime? plannedWeekStart,
    int? monthlyDay,
    Map<String, double> dayTotals = const {},
  }) async {
    final priorPaid = widget.initialOrder?.paidAmount ?? 0;
    double paidAmount = priorPaid;
    double deltaPendingAmount = 0;
    double walletAdjustmentAmount = 0;
    String status = widget.initialOrder?.status ?? 'ACTIVE';
    Order? pendingOrder;

    if (delta < 0) {
      final credit = -delta;
      ref.read(walletControllerProvider.notifier).credit(
            amount: credit,
            orderId: widget.initialOrder?.id ?? 'recurring',
            note: 'Recurring order reduction',
          );
      walletAdjustmentAmount = credit;
      status = 'ACTIVE';
    } else if (delta > 0) {
      final cartItems = _toCartItems(items, products);
      pendingOrder = ref.read(orderControllerProvider.notifier).createPendingAmount(
            amount: delta,
            items: cartItems,
            note: 'Recurring order top-up',
            applyWallet: _applyWallet,
            recurringOrderId: widget.initialOrder?.id,
            recurringDelta: delta,
            deliveryAddress: address.address,
            deliveryLatitude: address.latitude,
            deliveryLongitude: address.longitude,
            deliveryLabel: address.label,
          );
      deltaPendingAmount = pendingOrder.amountDue;
      paidAmount = priorPaid + pendingOrder.walletApplied;
      status = deltaPendingAmount > 0 ? 'ACTIVE_PENDING_PAYMENT' : 'ACTIVE';
    }

    final order = RecursiveOrder(
      id: widget.initialOrder?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      frequency: _mode,
      items: items,
      createdAt: DateTime.now(),
      monthlyDay: monthlyDay,
      deliveryTime: _deliverySlot,
      deliveryAddress: address.address,
      deliveryAddressId: _addressKey(address),
      deliveryLatitude: address.latitude,
      deliveryLongitude: address.longitude,
      plannedWeekStart: plannedWeekStart ?? deliveryWeekStart,
      paidAmount: paidAmount,
      basePaidAmount: basePaid,
      deltaPendingAmount: deltaPendingAmount,
      walletAdjustmentAmount: walletAdjustmentAmount,
      currentAmount: total,
      status: status,
      deliveredDays: widget.initialOrder?.deliveredDays ?? const [],
      refundedAmount: widget.initialOrder?.refundedAmount ?? 0,
      refundProcessed: widget.initialOrder?.refundProcessed ?? false,
      dayTotals: dayTotals,
    );

    await ref.read(recursiveOrderControllerProvider.notifier).saveOrder(order);
    if (!mounted) return;

    if (pendingOrder != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaymentScreen(order: pendingOrder!)),
      );
    } else {
      _warn(context, 'Plan saved successfully');
    }

    // Clear cart state after a successful save so user starts fresh.
    ref.read(cartControllerProvider.notifier).clear();
  }

  List<CartItem> _toCartItems(Map<String, dynamic> items, List<Product> products) {
    final result = <CartItem>[];
    if (_mode == 'weekly' && items.containsKey('weekly')) {
      final weekly = items['weekly'] as Map<String, dynamic>;
      final aggregate = <String, int>{};
      weekly.values.forEach((dayItems) {
        (dayItems as Map<String, dynamic>).forEach((id, qty) {
          aggregate[id] = (aggregate[id] ?? 0) + (qty as int);
        });
      });
      aggregate.forEach((id, qty) {
        final product = products.firstWhere((p) => p.id == id);
        result.add(CartItem(product: product, quantity: qty));
      });
    } else {
      items.forEach((id, qty) {
        final product = products.firstWhere((p) => p.id == id);
        result.add(CartItem(product: product, quantity: qty as int));
      });
    }
    return result;
  }

  double _sum(Map<String, int> items, List<Product> products) {
    double total = 0;
    items.forEach((id, qty) {
      final product = products.firstWhere((p) => p.id == id, orElse: () => products.first);
      total += product.price * qty;
    });
    return total;
  }

  DateTime _todayCutoff() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 4);
  }

  bool _isWeeklyDayDisabled(String day) {
    if (!_weekdayOffsets.containsKey(day)) return false;
    final dayDate = _dayDateFor(day);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (dayDate.isBefore(todayDate)) return true;
    if (isSameDay(dayDate, todayDate) && today.isAfter(_todayCutoff())) return true;
    return false;
  }
  
  void _ensureSelectedWeekday() {
    if (!_isWeeklyDayDisabled(_selectedWeekday)) return;
    for (final day in _weekdayOrder) {
      if (!_isWeeklyDayDisabled(day)) {
        _selectedWeekday = day;
        return;
      }
    }
    _selectedWeekday = _weekdayOrder.first;
  }

  String _monthLabel(DateTime date) {
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return labels[date.month - 1];
  }

  Future<DeliveryLocation?> _pickAddress(
    BuildContext context,
    ProfileState profile,
  ) async {
    final secondaryCount = profile.savedAddresses.where((a) => !a.isPrimary).length;
    String choice = profile.savedAddresses.isNotEmpty ? 'existing' : 'new';
    int selectedIndex = 0;
    final controller = TextEditingController();
    String label = 'Home';

    return showDialog<DeliveryLocation?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final canSubmit = choice == 'existing'
                ? profile.savedAddresses.isNotEmpty
                : controller.text.trim().isNotEmpty;
            final media = MediaQuery.of(dialogContext);
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: media.size.width * 0.9,
                  maxHeight: media.size.height * 0.8,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Delivery address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile<String>(
                                value: 'existing',
                                groupValue: choice,
                                onChanged: (v) => setState(() => choice = v ?? 'existing'),
                                title: const Text('Use saved address'),
                                subtitle: profile.savedAddresses.isEmpty
                                    ? const Text('No saved addresses')
                                    : Text('Selected: ${profile.savedAddresses[selectedIndex].label}'),
                              ),
                              if (choice == 'existing' && profile.savedAddresses.isNotEmpty)
                                SizedBox(
                                  height: 180,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: profile.savedAddresses.length,
                                    itemBuilder: (context, index) {
                                      final saved = profile.savedAddresses[index];
                                      return RadioListTile<int>(
                                        value: index,
                                        groupValue: selectedIndex,
                                        onChanged: (val) => setState(() => selectedIndex = val ?? 0),
                                        title: Text('${saved.label}: ${saved.address}'),
                                        subtitle: saved.isPrimary ? const Text('Primary') : null,
                                      );
                                    },
                                  ),
                                ),
                              RadioListTile<String>(
                                value: 'new',
                                groupValue: choice,
                                onChanged: (v) => setState(() => choice = v ?? 'new'),
                                title: const Text('Add new address'),
                              ),
                              if (choice == 'new') ...[
                                if (secondaryCount >= 10 && profile.savedAddresses.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      'You have reached the limit of 10 secondary addresses. Remove one in profile to add another.',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                TextField(
                                  controller: controller,
                                  minLines: 2,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Delivery address',
                                    hintText: 'Type the delivery address',
                                  ),
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: ['Home', 'Office', 'Other']
                                      .map((l) => ChoiceChip(
                                            label: Text(l),
                                            selected: label == l,
                                            onSelected: (v) {
                                              if (v) setState(() => label = l);
                                            },
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, null),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: !canSubmit
                                ? null
                                : () async {
                                    if (choice == 'existing') {
                                      final saved = profile.savedAddresses[selectedIndex];
                                      Navigator.pop(
                                        dialogContext,
                                        DeliveryLocation(
                                          address: saved.address,
                                          latitude: saved.latitude,
                                          longitude: saved.longitude,
                                          label: saved.label,
                                        ),
                                      );
                                    } else {
                                      if (secondaryCount >= 10 && profile.savedAddresses.isNotEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Maximum 10 secondary addresses reached. Remove one in profile to add another.'),
                                          ),
                                        );
                                        return;
                                      }
                                      final addr = controller.text.trim();
                                      await ref.read(profileControllerProvider.notifier).saveProfile(
                                            address: addr,
                                            addressLabel: label,
                                            setAsPrimary: profile.savedAddresses.isEmpty,
                                          );
                                      Navigator.pop(
                                        dialogContext,
                                        DeliveryLocation(
                                          address: addr,
                                          label: label,
                                        ),
                                      );
                                    }
                                  },
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _warn(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class DeliveryLocation {
  const DeliveryLocation({
    required this.address,
    this.latitude,
    this.longitude,
    this.label,
  });

  final String address;
  final double? latitude;
  final double? longitude;
  final String? label;

  DeliveryLocation copyWith({
    String? address,
    double? latitude,
    double? longitude,
    String? label,
  }) {
    return DeliveryLocation(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
    );
  }
}