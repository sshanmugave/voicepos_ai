import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/app_state.dart';
import 'bill_summary_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;
  int _quickAddQuantity = 1;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _BarcodeScanPage()),
    );
    if (result != null && mounted) {
      final product = await context.read<AppState>().lookupBarcode(result);
      if (product != null && mounted) {
        context.read<AppState>().addProductToCart(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${product.name}')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found for this barcode')),
        );
      }
    }
  }

  List<Product> _filteredProducts(AppState appState) {
    var products = appState.searchProducts(_searchQuery);
    if (_selectedCategoryId != null) {
      products = products
          .where((product) => product.categoryId == _selectedCategoryId)
          .toList();
    }
    return products;
  }

  Future<void> _showCartItemEditor(OrderItem item) async {
    final quantityCtrl = TextEditingController(text: item.quantity.toString());
    final discountCtrl =
        TextEditingController(text: item.discountPercent.toStringAsFixed(0));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Discount %'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final qty in [1, 2, 5, 10])
                    ActionChip(
                      label: Text('Qty $qty'),
                      onPressed: () => quantityCtrl.text = qty.toString(),
                    ),
                  for (final discount in [0, 5, 10])
                    ActionChip(
                      label: Text('$discount% Off'),
                      onPressed: () => discountCtrl.text = discount.toString(),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context
                            .read<AppState>()
                            .removeProductFromCart(item.productId);
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Remove'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        final quantity =
                            int.tryParse(quantityCtrl.text.trim()) ?? item.quantity;
                        final discount =
                            double.tryParse(discountCtrl.text.trim()) ?? item.discountPercent;
                        final appState = context.read<AppState>();
                        appState.setCartItemQuantity(item.productId, quantity);
                        appState.setItemDiscount(item.productId, discount.clamp(0, 100));
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBillDiscountDialog(AppState appState) async {
    final controller = TextEditingController(
      text: appState.draftDiscountAmount > 0
          ? appState.draftDiscountAmount.toStringAsFixed(0)
          : '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bill Discount'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Discount Amount',
              prefixText: '₹',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                appState.setBillDiscount(0);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(controller.text.trim()) ?? 0;
                appState.setBillDiscount(amount);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final filteredProducts = _filteredProducts(appState);
    final cartItems = appState.draftItems;

    return SafeArea(
      child: Stack(
        children: [
          // ─── Main content (product grid fills full area) ───
          Column(
            children: [
              // ─── Top bar: Search + Barcode + Voice ───
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _scanBarcode,
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Scan barcode',
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () async {
                        if (appState.isListening) {
                          await appState.stopVoiceCapture();
                        } else {
                          await appState.startVoiceCapture();
                        }
                      },
                      icon: Icon(
                        appState.isListening ? Icons.mic_off : Icons.mic,
                        color: appState.isListening
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      tooltip: appState.isListening
                          ? 'Stop listening'
                          : 'Voice order',
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  children: [
                    ChoiceChip(
                      label: Text('Qty $_quickAddQuantity'),
                      selected: true,
                      onSelected: (_) {},
                    ),
                    const SizedBox(width: 8),
                    for (final qty in [1, 2, 5]) ...[
                      ChoiceChip(
                        label: Text('+${qty == 1 ? '1' : qty}'),
                        selected: _quickAddQuantity == qty,
                        onSelected: (_) =>
                            setState(() => _quickAddQuantity = qty),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategoryId = null),
                    ),
                    const SizedBox(width: 8),
                    for (final category in appState.categories) ...[
                      ChoiceChip(
                        label: Text(category.name),
                        selected: _selectedCategoryId == category.id,
                        onSelected: (_) => setState(
                            () => _selectedCategoryId = category.id),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),

              // ─── Voice feedback ───
              if (appState.recognizedText.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.record_voice_over, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appState.recognizedText,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── Favorites section ───
              if (appState.favoriteProducts.isNotEmpty &&
                  _searchQuery.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            'Favorites',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: appState.favoriteProducts.length,
                        itemBuilder: (context, index) {
                          final product =
                              appState.favoriteProducts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4),
                            child: _FavoriteChip(
                              product: product,
                              onTap: () {
                                for (var c = 0;
                                    c < _quickAddQuantity;
                                    c++) {
                                  context
                                      .read<AppState>()
                                      .addProductToCart(product);
                                }
                              },
                              onLongPress: () =>
                                  appState.toggleFavorite(product.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

              // ─── Product grid (extra bottom padding when cart overlay visible) ───
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(child: Text('No products found'))
                    : GridView.builder(
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 12,
                          // leave room so last row is not hidden by cart sheet
                          bottom: appState.hasDraft ? 120 : 12,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final inCart = cartItems
                              .where((i) => i.productId == product.id)
                              .firstOrNull;
                          return _ProductTile(
                            product: product,
                            cartQty: inCart?.quantity ?? 0,
                            quickAddQuantity: _quickAddQuantity,
                            onTap: () {
                              for (var count = 0;
                                  count < _quickAddQuantity;
                                  count++) {
                                context
                                    .read<AppState>()
                                    .addProductToCart(product);
                              }
                            },
                            onLongPress: () {
                              context
                                  .read<AppState>()
                                  .toggleFavorite(product.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    product.isFavorite
                                        ? '${product.name} removed from favorites'
                                        : '${product.name} added to favorites',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),

          // ─── DraggableScrollableSheet cart overlay ───
          if (appState.hasDraft)
            DraggableScrollableSheet(
              initialChildSize: 0.22,
              minChildSize: 0.09,
              maxChildSize: 0.88,
              snap: true,
              snapSizes: const [0.09, 0.22, 0.88],
              builder: (ctx, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      // Drag handle
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Cart header bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
                          child: Row(
                            children: [
                              Text(
                                'Cart  •  ${cartItems.fold<int>(0, (s, i) => s + i.quantity)} items',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () =>
                                    _showBillDiscountDialog(appState),
                                child: appState.draftDiscountAmount > 0
                                    ? Text(
                                        'Discount ₹${appState.draftDiscountAmount.toStringAsFixed(0)}',
                                      )
                                    : const Text('Discount'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.read<AppState>().clearDraft(),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Cart items list
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = cartItems[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: _CartRow(
                                item: item,
                                onEdit: () => _showCartItemEditor(item),
                                onIncrement: () => context
                                    .read<AppState>()
                                    .incrementCartItem(item.productId),
                                onDecrement: () => context
                                    .read<AppState>()
                                    .decrementCartItem(item.productId),
                                onRemove: () => context
                                    .read<AppState>()
                                    .removeProductFromCart(item.productId),
                              ),
                            );
                          },
                          childCount: cartItems.length,
                        ),
                      ),

                      // Totals + Checkout
                      SliverToBoxAdapter(
                        child: Container(
                          padding:
                              const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal'),
                                    Text(
                                        '₹${appState.draftSubtotal.toStringAsFixed(2)}'),
                                  ],
                                ),
                                if (appState.draftTaxAmount > 0)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('GST'),
                                      Text(
                                          '₹${appState.draftTaxAmount.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                if (appState.draftDiscountAmount > 0)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Discount'),
                                      Text(
                                          '-₹${appState.draftDiscountAmount.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Grand Total',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800),
                                    ),
                                    Text(
                                      '₹${appState.draftGrandTotal.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const BillSummaryScreen(),
                                        ),
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    child: const Text('Checkout'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}


// ─── Product Tile ───

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.cartQty,
    required this.quickAddQuantity,
    required this.onTap,
    this.onLongPress,
  });

  final Product product;
  final int cartQty;
  final int quickAddQuantity;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.sellingPrice.toStringAsFixed(0)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (quickAddQuantity > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Tap adds $quickAddQuantity',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  if (product.isLowStock)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Low stock',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (cartQty > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$cartQty',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            if (product.isFavorite)
              const Positioned(
                top: 4,
                left: 4,
                child: Icon(Icons.star, size: 14, color: Colors.amber),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Cart Row ───

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.onEdit,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final OrderItem item;
  final VoidCallback onEdit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '₹${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}'
                      '${item.discountPercent > 0 ? ' • ${item.discountPercent.toStringAsFixed(0)}% off' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: onDecrement,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Text('${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: onIncrement,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Text(
                '₹${item.subtotal.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: Theme.of(context).colorScheme.error),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Barcode Scanner Page ───

class _BarcodeScanPage extends StatefulWidget {
  const _BarcodeScanPage();

  @override
  State<_BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<_BarcodeScanPage> {
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

// ─── Favorite Chip ───

class _FavoriteChip extends StatelessWidget {
  const _FavoriteChip({
    required this.product,
    required this.onTap,
    required this.onLongPress,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: const BoxConstraints(minWidth: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '₹${product.sellingPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}