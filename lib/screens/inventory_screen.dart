import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/app_state.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _search = '';
  int? _categoryFilter;

  List<Product> _filteredProducts(AppState appState) {
    var list = appState.searchProducts(_search);
    if (_categoryFilter != null) {
      list = list.where((p) => p.categoryId == _categoryFilter).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final products = _filteredProducts(appState);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => _showAddCategoryDialog(context),
                    icon: const Icon(Icons.playlist_add),
                    tooltip: 'Add category',
                  ),
                ],
              ),
            ),

            // Category filter chips
            if (appState.categories.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _categoryFilter == null,
                        onSelected: (_) =>
                            setState(() => _categoryFilter = null),
                      ),
                    ),
                    ...appState.categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onLongPress: () =>
                                _showCategoryOptions(context, cat),
                            child: FilterChip(
                              label: Text(cat.name),
                              selected: _categoryFilter == cat.id,
                              onSelected: (_) => setState(
                                  () => _categoryFilter = cat.id),
                            ),
                          ),
                        )),
                  ],
                ),
              ),

            // Low stock banner
            if (appState.lowStockProducts.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${appState.lowStockProducts.length} product(s) low on stock',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ),
              ),

            // Product list
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('No products found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _ProductCard(
                          product: product,
                          categories: appState.categories,
                          onRestock: () =>
                              _showRestockDialog(context, product),
                          onEdit: () =>
                              _showProductDialog(context, product: product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Future<void> _showRestockDialog(
      BuildContext context, Product product) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restock ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Quantity to add'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final amount in [5, 10, 25, 50])
                  ActionChip(
                    label: Text('+${amount.toString()}'),
                    onPressed: () => controller.text = amount.toString(),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount =
                  double.tryParse(controller.text.trim()) ?? 0;
              if (amount > 0) {
                await context
                    .read<AppState>()
                    .restockProduct(product.id, amount);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await context.read<AppState>().addCategory(name);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCategoryOptions(
      BuildContext context, Category category) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text('Rename "${category.name}"'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showRenameCategoryDialog(context, category);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Delete "${category.name}"',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showDeleteCategoryConfirm(context, category);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRenameCategoryDialog(
      BuildContext context, Category category) async {
    final controller = TextEditingController(text: category.name);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Rename Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'New name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await context
                    .read<AppState>()
                    .updateCategory(category.id, name);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteCategoryConfirm(
      BuildContext context, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Delete "${category.name}"?'),
          content: const Text(
            'Products in this category will be moved to Uncategorised. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppState>().deleteCategory(category.id);
      if (_categoryFilter == category.id) {
        setState(() => _categoryFilter = null);
      }
    }
  }

  Future<void> _showProductDialog(BuildContext context,
      {Product? product}) async {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final purchasePriceCtrl = TextEditingController(
        text: product != null ? product.purchasePrice.toString() : '');
    final sellingPriceCtrl = TextEditingController(
        text: product != null ? product.sellingPrice.toString() : '');
    final gstCtrl = TextEditingController(
        text: product != null ? product.gstRate.toString() : '5');
    final stockCtrl = TextEditingController(
        text: product != null ? product.stockQuantity.toString() : '');
    final thresholdCtrl = TextEditingController(
        text: product != null ? product.lowStockThreshold.toString() : '10');
    String unit = product?.unit ?? 'pcs';
    int? categoryId = product?.categoryId;

    final appState = context.read<AppState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Product' : 'Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Product Name'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Barcode'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final result = await Navigator.of(ctx).push<String>(
                          MaterialPageRoute(
                              builder: (_) => const _ScanPage()),
                        );
                        if (result != null) barcodeCtrl.text = result;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: categoryId,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: appState.categories
                      .map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.name)))
                    .toList()
                    .cast<DropdownMenuItem<int>>(),
                  onChanged: (v) =>
                      setDialogState(() => categoryId = v),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      await _showAddCategoryDialog(context);
                      if (!context.mounted) return;
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New category'),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: purchasePriceCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Purchase Price'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: sellingPriceCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Selling Price'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: gstCtrl,
                        decoration:
                            const InputDecoration(labelText: 'GST %'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: unit,
                        decoration:
                            const InputDecoration(labelText: 'Unit'),
                        items: const [
                          DropdownMenuItem(
                              value: 'pcs', child: Text('Pieces')),
                          DropdownMenuItem(
                              value: 'kg', child: Text('kg')),
                          DropdownMenuItem(
                              value: 'L', child: Text('Litres')),
                          DropdownMenuItem(
                              value: 'g', child: Text('Grams')),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => unit = v ?? 'pcs'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Stock Qty'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: thresholdCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Low Stock Alert'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            if (!isEdit)
              OutlinedButton(
                onPressed: () async {
                  final saved = await _saveProduct(
                    appState: appState,
                    existing: product,
                    name: nameCtrl.text.trim(),
                    barcode: barcodeCtrl.text.trim(),
                    categoryId: categoryId,
                    purchasePrice: purchasePriceCtrl.text.trim(),
                    sellingPrice: sellingPriceCtrl.text.trim(),
                    gstRate: gstCtrl.text.trim(),
                    stockQuantity: stockCtrl.text.trim(),
                    unit: unit,
                    lowStockThreshold: thresholdCtrl.text.trim(),
                  );
                  if (!saved) return;
                  nameCtrl.clear();
                  barcodeCtrl.clear();
                  purchasePriceCtrl.clear();
                  sellingPriceCtrl.clear();
                  gstCtrl.text = '5';
                  stockCtrl.clear();
                  thresholdCtrl.text = '10';
                  setDialogState(() {
                    unit = 'pcs';
                    categoryId = null;
                  });
                },
                child: const Text('Save & Next'),
              ),
            FilledButton(
              onPressed: () async {
                final saved = await _saveProduct(
                  appState: appState,
                  existing: product,
                  name: nameCtrl.text.trim(),
                  barcode: barcodeCtrl.text.trim(),
                  categoryId: categoryId,
                  purchasePrice: purchasePriceCtrl.text.trim(),
                  sellingPrice: sellingPriceCtrl.text.trim(),
                  gstRate: gstCtrl.text.trim(),
                  stockQuantity: stockCtrl.text.trim(),
                  unit: unit,
                  lowStockThreshold: thresholdCtrl.text.trim(),
                );
                if (saved && ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _saveProduct({
    required AppState appState,
    required Product? existing,
    required String name,
    required String barcode,
    required int? categoryId,
    required String purchasePrice,
    required String sellingPrice,
    required String gstRate,
    required String stockQuantity,
    required String unit,
    required String lowStockThreshold,
  }) async {
    final parsedSellingPrice = double.tryParse(sellingPrice) ?? 0;
    if (name.isEmpty || parsedSellingPrice <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a product name and selling price')),
        );
      }
      return false;
    }

    final product = Product(
      id: existing?.id ?? 0,
      name: name,
      barcode: barcode.isEmpty ? null : barcode,
      categoryId: categoryId,
      purchasePrice: double.tryParse(purchasePrice) ?? 0,
      sellingPrice: parsedSellingPrice,
      gstRate: double.tryParse(gstRate) ?? 0,
      stockQuantity: double.tryParse(stockQuantity) ?? 0,
      unit: unit,
      lowStockThreshold: double.tryParse(lowStockThreshold) ?? 10,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    if (existing != null) {
      await appState.updateProduct(product);
    } else {
      await appState.addProduct(product);
    }
    return true;
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categories,
    required this.onRestock,
    required this.onEdit,
  });

  final Product product;
  final List<Category> categories;
  final VoidCallback onRestock;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categoryName = categories
        .where((c) => c.id == product.categoryId)
        .map((c) => c.name)
        .firstOrNull;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 50,
                decoration: BoxDecoration(
                  color: product.isLowStock ? cs.error : cs.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        Text('₹${product.sellingPrice.toStringAsFixed(0)}'),
                        if (categoryName != null) ...[
                          const Text(' · '),
                          Text(categoryName,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                        const Text(' · '),
                        Text('GST ${product.gstRate.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    Text(
                      'Stock: ${product.stockQuantity.toStringAsFixed(0)} ${product.unit}',
                      style: TextStyle(
                        color: product.isLowStock ? cs.error : null,
                        fontWeight:
                            product.isLowStock ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: onRestock,
                child: const Text('Restock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanPage extends StatefulWidget {
  const _ScanPage();

  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_scanned) return;
          final barcode = capture.barcodes.firstOrNull;
          if (barcode?.rawValue != null) {
            _scanned = true;
            Navigator.of(context).pop(barcode!.rawValue);
          }
        },
      ),
    );
  }
}