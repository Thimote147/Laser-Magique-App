import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:laser_magique_app/models/food.dart';
import 'package:laser_magique_app/services/supabase_service.dart';
import 'package:laser_magique_app/utils/app_strings.dart';
import 'package:laser_magique_app/main.dart' show themeService;

enum SortType { name, price, quantity }

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _foodItems = [];
  List<FoodItem> _filteredItems = [];
  bool _isLoading = true;
  String _errorMessage = '';
  SortType _currentSortType = SortType.name;
  bool _sortDescending = false;
  bool _showingLowStockOnly = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
    themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {}); // Refresh UI when theme changes
  }

  Future<void> _loadFoodItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final items = await SupabaseService.instance.getFoodItems();

      // Sort the items based on current sort type
      switch (_currentSortType) {
        case SortType.name:
          items.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          break;
        case SortType.price:
          items.sort((a, b) => a.price.compareTo(b.price));
          break;
        case SortType.quantity:
          items.sort((a, b) => a.quantity.compareTo(b.quantity));
          break;
      }

      setState(() {
        _foodItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _filterItems(String query) {
    List<FoodItem> tempFilteredItems = _foodItems;

    // First apply low stock filter if enabled
    if (_showingLowStockOnly) {
      tempFilteredItems =
          tempFilteredItems.where((item) => item.quantity <= 10).toList();
    }

    // Then apply search query filter
    if (query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      tempFilteredItems =
          tempFilteredItems
              .where((item) => item.name.toLowerCase().contains(lowercaseQuery))
              .toList();
    }

    setState(() {
      _filteredItems = tempFilteredItems;
    });
  }

  void _toggleLowStockFilter() {
    setState(() {
      _showingLowStockOnly = !_showingLowStockOnly;
    });
    // Re-apply filtering with current search text
    _filterItems(_searchController.text);
  }

  Future<void> _showItemDialog({FoodItem? item}) async {
    final isEditing = item != null;
    final TextEditingController nameController = TextEditingController(
      text: item?.name ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: item?.price != null ? item!.price.toString() : '',
    );
    final TextEditingController quantityController = TextEditingController(
      text: item?.quantity != null ? item!.quantity.toString() : '',
    );

    // Form validation state
    bool isNameValid = true;
    bool isPriceValid = true;
    bool isQuantityValid = true;
    String nameError = '';
    String priceError = '';
    String quantityError = '';

    // Instead of using a dialog, use a full-screen modal with better styling
    await Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              // Validation functions
              void validateName() {
                if (nameController.text.trim().isEmpty) {
                  setState(() {
                    isNameValid = false;
                    nameError = 'Le nom est requis';
                  });
                } else {
                  setState(() {
                    isNameValid = true;
                    nameError = '';
                  });
                }
              }

              void validatePrice() {
                final priceText = priceController.text.trim();
                if (priceText.isEmpty) {
                  setState(() {
                    isPriceValid = false;
                    priceError = 'Le prix est requis';
                  });
                } else {
                  final price = double.tryParse(priceText);
                  if (price == null || price < 0) {
                    setState(() {
                      isPriceValid = false;
                      priceError = 'Prix invalide';
                    });
                  } else {
                    setState(() {
                      isPriceValid = true;
                      priceError = '';
                    });
                  }
                }
              }

              void validateQuantity() {
                final quantityText = quantityController.text.trim();
                if (quantityText.isEmpty) {
                  setState(() {
                    isQuantityValid = false;
                    quantityError = 'La quantité est requise';
                  });
                } else {
                  final quantity = int.tryParse(quantityText);
                  if (quantity == null || quantity < 0) {
                    setState(() {
                      isQuantityValid = false;
                      quantityError = 'Quantité invalide';
                    });
                  } else {
                    setState(() {
                      isQuantityValid = true;
                      quantityError = '';
                    });
                  }
                }
              }

              // Validate all fields
              bool validateFields() {
                validateName();
                validatePrice();
                validateQuantity();
                return isNameValid && isPriceValid && isQuantityValid;
              }

              // Save function
              Future<void> saveItem() async {
                if (!validateFields()) {
                  return;
                }

                try {
                  final name = nameController.text.trim();
                  final price = double.parse(priceController.text.trim());
                  final quantity = int.parse(quantityController.text.trim());

                  if (isEditing) {
                    final updatedItem = item.copyWith(
                      name: name,
                      price: price,
                      quantity: quantity,
                    );
                    await SupabaseService.instance.updateFoodItem(updatedItem);
                  } else {
                    final newItem = FoodItem(
                      name: name,
                      price: price,
                      quantity: quantity,
                    );
                    await SupabaseService.instance.addFoodItem(newItem);
                  }

                  Navigator.of(context).pop();
                  _loadFoodItems();

                  // Show success message
                  _showSuccessMessage(
                    isEditing
                        ? 'Article modifié avec succès'
                        : 'Article ajouté avec succès',
                  );
                } catch (error) {
                  _showErrorMessage('${AppStrings.errorOccurred}: $error');
                }
              }

              final backgroundColor = themeService.getBackgroundColor();
              final cardColor = themeService.getCardColor();
              final textColor = themeService.getTextColor();
              final secondaryTextColor = themeService.getSecondaryTextColor();
              final primaryColor = CupertinoTheme.of(context).primaryColor;

              return CupertinoPageScaffold(
                backgroundColor: backgroundColor,
                navigationBar: CupertinoNavigationBar(
                  backgroundColor: backgroundColor,
                  border: null,
                  heroTag:
                      'stockItemDialog${isEditing ? '_edit_' : '_add_'}${item?.id ?? DateTime.now().millisecondsSinceEpoch}',
                  transitionBetweenRoutes: false,
                  middle: Text(
                    isEditing ? AppStrings.editItem : AppStrings.addItem,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  leading: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      AppStrings.cancel,
                      style: TextStyle(fontSize: 17),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    color: backgroundColor,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated Header with illustration
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.only(bottom: 32.0),
                              child: Column(
                                children: [
                                  Hero(
                                    tag: 'item_icon_${item?.id ?? "new"}',
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color:
                                            isEditing
                                                ? CupertinoColors.systemIndigo
                                                    .withOpacity(0.15)
                                                : primaryColor.withOpacity(
                                                  0.15,
                                                ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                isEditing
                                                    ? CupertinoColors
                                                        .systemIndigo
                                                        .withOpacity(0.2)
                                                    : primaryColor.withOpacity(
                                                      0.2,
                                                    ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isEditing
                                              ? CupertinoIcons
                                                  .pencil_circle_fill
                                              : CupertinoIcons.cube_box_fill,
                                          color:
                                              isEditing
                                                  ? CupertinoColors.systemIndigo
                                                  : primaryColor,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 500),
                                    opacity: 1.0,
                                    child: Text(
                                      isEditing
                                          ? "Modifier les informations"
                                          : "Ajouter un nouvel article",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  if (!isEditing)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        "Remplissez les informations ci-dessous",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: secondaryTextColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Form Section
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      themeService.darkMode
                                          ? Colors.black.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name Field
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.tag_fill,
                                            color: primaryColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Nom de l\'article',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color:
                                                !isNameValid
                                                    ? CupertinoColors.systemRed
                                                    : themeService.darkMode
                                                    ? const Color(0xFF3A3A3C)
                                                    : const Color(0xFFE5E5EA),
                                            width: 1,
                                          ),
                                        ),
                                        child: CupertinoTextField(
                                          controller: nameController,
                                          placeholder:
                                              "Ex: Soda, Snack, Eau minérale...",
                                          padding: const EdgeInsets.all(16),
                                          clearButtonMode:
                                              OverlayVisibilityMode.editing,
                                          prefix: Container(
                                            padding: const EdgeInsets.only(
                                              left: 12,
                                            ),
                                            child: Icon(
                                              CupertinoIcons.tag_fill,
                                              color: primaryColor.withOpacity(
                                                0.7,
                                              ),
                                              size: 20,
                                            ),
                                          ),
                                          decoration: null,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16,
                                          ),
                                          onChanged: (value) {
                                            if (!isNameValid) {
                                              setState(() {
                                                isNameValid = true;
                                                nameError = '';
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      if (!isNameValid)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                            top: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                CupertinoIcons
                                                    .exclamationmark_circle,
                                                color:
                                                    CupertinoColors.systemRed,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                nameError,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      CupertinoColors.systemRed,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Price Field
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons
                                                .money_euro_circle_fill,
                                            color: primaryColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Prix',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color:
                                                !isPriceValid
                                                    ? CupertinoColors.systemRed
                                                    : themeService.darkMode
                                                    ? const Color(0xFF3A3A3C)
                                                    : const Color(0xFFE5E5EA),
                                            width: 1,
                                          ),
                                        ),
                                        child: CupertinoTextField(
                                          controller: priceController,
                                          placeholder: "Ex: 2.50",
                                          padding: const EdgeInsets.all(16),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          clearButtonMode:
                                              OverlayVisibilityMode.editing,
                                          prefix: Container(
                                            padding: const EdgeInsets.only(
                                              left: 12,
                                            ),
                                            child: Icon(
                                              CupertinoIcons
                                                  .money_euro_circle_fill,
                                              color: primaryColor.withOpacity(
                                                0.7,
                                              ),
                                              size: 20,
                                            ),
                                          ),
                                          suffix: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            child: Text(
                                              '€',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                          decoration: null,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16,
                                          ),
                                          onChanged: (value) {
                                            if (!isPriceValid) {
                                              setState(() {
                                                isPriceValid = true;
                                                priceError = '';
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      if (!isPriceValid)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                            top: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                CupertinoIcons
                                                    .exclamationmark_circle,
                                                color:
                                                    CupertinoColors.systemRed,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                priceError,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      CupertinoColors.systemRed,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Quantity Field
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.cube_box_fill,
                                            color: primaryColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Quantité en stock',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color:
                                                !isQuantityValid
                                                    ? CupertinoColors.systemRed
                                                    : themeService.darkMode
                                                    ? const Color(0xFF3A3A3C)
                                                    : const Color(0xFFE5E5EA),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: CupertinoTextField(
                                                controller: quantityController,
                                                placeholder: "Ex: 42",
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                clearButtonMode:
                                                    OverlayVisibilityMode
                                                        .editing,
                                                prefix: Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 12,
                                                      ),
                                                  child: Icon(
                                                    CupertinoIcons
                                                        .cube_box_fill,
                                                    color: primaryColor
                                                        .withOpacity(0.7),
                                                    size: 20,
                                                  ),
                                                ),
                                                decoration: null,
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 16,
                                                ),
                                                onChanged: (value) {
                                                  if (!isQuantityValid) {
                                                    setState(() {
                                                      isQuantityValid = true;
                                                      quantityError = '';
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  CupertinoButton(
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () {
                                                      final currentValue =
                                                          int.tryParse(
                                                            quantityController
                                                                .text,
                                                          ) ??
                                                          0;
                                                      if (currentValue > 0) {
                                                        setState(() {
                                                          quantityController
                                                                  .text =
                                                              (currentValue - 1)
                                                                  .toString();
                                                        });
                                                      }
                                                    },
                                                    child: Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            themeService
                                                                    .darkMode
                                                                ? const Color(
                                                                  0xFF2C2C2E,
                                                                )
                                                                : const Color(
                                                                  0xFFF2F2F7,
                                                                ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Center(
                                                        child: Icon(
                                                          CupertinoIcons.minus,
                                                          color:
                                                              CupertinoColors
                                                                  .systemGrey,
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  CupertinoButton(
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () {
                                                      final currentValue =
                                                          int.tryParse(
                                                            quantityController
                                                                .text,
                                                          ) ??
                                                          0;
                                                      setState(() {
                                                        quantityController
                                                                .text =
                                                            (currentValue + 1)
                                                                .toString();
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: primaryColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: primaryColor
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  3,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Center(
                                                        child: Icon(
                                                          CupertinoIcons.add,
                                                          color:
                                                              CupertinoColors
                                                                  .white,
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isQuantityValid)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                            top: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                CupertinoIcons
                                                    .exclamationmark_circle,
                                                color:
                                                    CupertinoColors.systemRed,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                quantityError,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      CupertinoColors.systemRed,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Preview Card
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        themeService.darkMode
                                            ? Colors.black.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              margin: const EdgeInsets.only(bottom: 30),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.eye_fill,
                                        size: 18,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Aperçu",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    height: 24,
                                    color:
                                        themeService.darkMode
                                            ? const Color(0xFF3A3A3C)
                                            : const Color(0xFFE5E5EA),
                                  ),
                                  StatefulBuilder(
                                    builder: (context, setPreviewState) {
                                      // Update preview when input changes
                                      nameController.addListener(
                                        () => setPreviewState(() {}),
                                      );
                                      priceController.addListener(
                                        () => setPreviewState(() {}),
                                      );
                                      quantityController.addListener(
                                        () => setPreviewState(() {}),
                                      );

                                      final name =
                                          nameController.text.isNotEmpty
                                              ? nameController.text
                                              : "Nom de l'article";
                                      final price =
                                          double.tryParse(
                                            priceController.text,
                                          ) ??
                                          0.0;
                                      final quantity =
                                          int.tryParse(
                                            quantityController.text,
                                          ) ??
                                          0;

                                      // This row now mirrors the exact structure in the food items list
                                      return Row(
                                        children: [
                                          // Left side with icon based on stock status
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: _getStockStatusColor(
                                                quantity,
                                              ).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                _getStockStatusIcon(quantity),
                                                color: _getStockStatusColor(
                                                  quantity,
                                                ),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Middle section with item details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: textColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    Text(
                                                      '${price.toStringAsFixed(2)} €',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: primaryColor,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            themeService
                                                                    .darkMode
                                                                ? const Color(
                                                                  0xFF2C2C2E,
                                                                )
                                                                : CupertinoColors
                                                                    .systemGrey6,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Quantité: $quantity',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              secondaryTextColor,
                                                        ),
                                                      ),
                                                    ),
                                                    _buildStockBadge(quantity),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Right side with edit icon
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(
                                                0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              CupertinoIcons.eye,
                                              color: primaryColor,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Save button
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              width: double.infinity,
                              child: CupertinoButton(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(16),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                onPressed: saveItem,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isEditing
                                          ? CupertinoIcons.arrow_up_doc_fill
                                          : CupertinoIcons.add,
                                      color: CupertinoColors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEditing
                                          ? "Mettre à jour l'article"
                                          : "Ajouter l'article",
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          if (isEditing) ...[
                            // Delete button for editing mode
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: double.infinity,
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _confirmDelete(item);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.trash,
                                        color: CupertinoColors.systemRed,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Supprimer l'article",
                                        style: const TextStyle(
                                          color: CupertinoColors.systemRed,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // Bottom padding for safe area
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSuccessMessage(String message) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Icon(
              CupertinoIcons.checkmark_circle,
              color: CupertinoColors.activeGreen,
              size: 40,
            ),
            message: Text(message, style: const TextStyle(fontSize: 16)),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
    );
  }

  void _showErrorMessage(String message) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Icon(
              CupertinoIcons.exclamationmark_circle,
              color: CupertinoColors.systemRed,
              size: 40,
            ),
            message: Text(message, style: const TextStyle(fontSize: 16)),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ),
    );
  }

  Future<void> _confirmDelete(FoodItem item) async {
    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final textColor = themeService.getTextColor();

        return CupertinoAlertDialog(
          title: Row(
            children: [
              const Icon(
                CupertinoIcons.delete,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(width: 8),
              Text(AppStrings.deleteItem),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: [
                Text(AppStrings.deleteConfirmationItem),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        themeService.darkMode
                            ? const Color(0xFF2C2C2E)
                            : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${item.price.toStringAsFixed(2)} €'),
                        ],
                      ),
                      _buildStockBadge(item.quantity),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text(AppStrings.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(AppStrings.delete),
              onPressed: () async {
                try {
                  await SupabaseService.instance.deleteFoodItem(item.id);

                  Navigator.of(context).pop();
                  _loadFoodItems();

                  // Show success message
                  _showSuccessMessage('Article supprimé avec succès');
                } catch (error) {
                  Navigator.of(context).pop();
                  _showErrorMessage('${AppStrings.errorOccurred}: $error');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStockBadge(int quantity) {
    if (quantity <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          AppStrings.outOfStock,
          style: TextStyle(color: CupertinoColors.systemRed, fontSize: 12),
        ),
      );
    } else if (quantity <= 10) {
      // Merge "Avertissement" and "Stock Bas" into one category
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: CupertinoColors.systemOrange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          AppStrings.lowStock,
          style: TextStyle(color: CupertinoColors.systemOrange, fontSize: 12),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: CupertinoColors.activeGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          AppStrings.inStock,
          style: TextStyle(color: CupertinoColors.activeGreen, fontSize: 12),
        ),
      );
    }
  }

  // Sort the food items based on the current sort type and direction
  void _sortItems() {
    setState(() {
      switch (_currentSortType) {
        case SortType.name:
          _foodItems.sort((a, b) {
            int result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            return _sortDescending ? -result : result;
          });
          break;
        case SortType.price:
          _foodItems.sort((a, b) {
            int result = a.price.compareTo(b.price);
            return _sortDescending ? -result : result;
          });
          break;
        case SortType.quantity:
          _foodItems.sort((a, b) {
            int result = a.quantity.compareTo(b.quantity);
            return _sortDescending ? -result : result;
          });
          break;
      }

      // Apply the same sorting to filtered items
      if (_searchController.text.isNotEmpty) {
        switch (_currentSortType) {
          case SortType.name:
            _filteredItems.sort((a, b) {
              int result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
              return _sortDescending ? -result : result;
            });
            break;
          case SortType.price:
            _filteredItems.sort((a, b) {
              int result = a.price.compareTo(b.price);
              return _sortDescending ? -result : result;
            });
            break;
          case SortType.quantity:
            _filteredItems.sort((a, b) {
              int result = a.quantity.compareTo(b.quantity);
              return _sortDescending ? -result : result;
            });
            break;
        }
      }
    });
  }

  // Show the sort options popup menu with enhanced UI
  void _showSortOptions() {
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final backgroundColor = themeService.getBackgroundColor();
    final textColor = themeService.getTextColor();
    final cardColor = themeService.getCardColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();

    // Track the temporary sort selections that will be applied on confirm
    SortType tempSortType = _currentSortType;
    bool tempSortDescending = _sortDescending;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar at the top
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: secondaryTextColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: Text(
                        "Trier par",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),

                    // Sort options with access to the modal's StateSetter
                    ..._buildSortOptionItems(
                      context,
                      tempSortType,
                      tempSortDescending,
                      (SortType newType, bool newDirection) {
                        setModalState(() {
                          tempSortType = newType;
                          tempSortDescending = newDirection;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Cancel and Confirm buttons side by side
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Cancel button
                          Expanded(
                            child: CupertinoButton(
                              color: backgroundColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Annuler',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Confirm button
                          Expanded(
                            child: CupertinoButton(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              onPressed: () {
                                setState(() {
                                  _currentSortType = tempSortType;
                                  _sortDescending = tempSortDescending;
                                });
                                _sortItems();
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Confirmer',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Build the sort option items
  List<Widget> _buildSortOptionItems(
    BuildContext context,
    SortType tempSortType,
    bool tempSortDescending,
    Function(SortType, bool) onSortChange,
  ) {
    final options = [
      {
        'type': SortType.name,
        'title': 'Nom',
        'icon': CupertinoIcons.textformat_abc,
        'description': 'Trier alphabétiquement par nom',
      },
      {
        'type': SortType.price,
        'title': 'Prix',
        'icon': CupertinoIcons.money_euro_circle,
        'description': 'Trier par prix, du plus bas au plus élevé',
      },
      {
        'type': SortType.quantity,
        'title': 'Quantité',
        'icon': CupertinoIcons.cube_box,
        'description': 'Trier par quantité disponible en stock',
      },
    ];

    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final backgroundColor = themeService.getBackgroundColor();
    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();

    return options.map((option) {
      final SortType optionType = option['type'] as SortType;
      final bool isSelected = tempSortType == optionType;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            onSortChange(optionType, tempSortDescending);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon on the left
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? primaryColor.withOpacity(0.2)
                            : backgroundColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      option['icon'] as IconData,
                      color: isSelected ? primaryColor : secondaryTextColor,
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Middle text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['title'] as String,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? primaryColor : textColor,
                        ),
                      ),
                      Text(
                        option['description'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side order indicator showing the current sort direction
                if (isSelected)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      onSortChange(optionType, !tempSortDescending);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          tempSortDescending
                              ? CupertinoIcons.sort_down
                              : CupertinoIcons.sort_up,
                          color: primaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // Get the appropriate icon for the current sort type
  IconData _getSortIcon() {
    switch (_currentSortType) {
      case SortType.name:
        return CupertinoIcons.textformat_abc;
      case SortType.price:
        return CupertinoIcons.money_euro_circle;
      case SortType.quantity:
        return CupertinoIcons.cube_box;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textColor = themeService.getTextColor();
    final backgroundColor = themeService.getBackgroundColor();
    final cardColor = themeService.getCardColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final separatorColor = themeService.getSeparatorColor();

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
        middle: null,
        backgroundColor: backgroundColor,
        border: null,
        heroTag: 'stockScreenMain',
        transitionBetweenRoutes: false,
        leading: Text(
          AppStrings.stockManagement,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: textColor,
            fontFamily: '.SF Pro Display',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showSortOptions,
              child: Row(
                children: [
                  Icon(
                    _getSortIcon(),
                    size: 22,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 14,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showItemDialog(),
              child: Icon(
                CupertinoIcons.add,
                size: 28,
                color: CupertinoTheme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child:
            _isLoading && _foodItems.isEmpty
                ? const Center(child: CupertinoActivityIndicator())
                : _errorMessage.isNotEmpty && _foodItems.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${AppStrings.errorOccurred}: $_errorMessage',
                        style: TextStyle(color: textColor),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        onPressed: _loadFoodItems,
                        child: Text(AppStrings.retry),
                      ),
                    ],
                  ),
                )
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CupertinoSearchTextField(
                        controller: _searchController,
                        placeholder: AppStrings.searchItems,
                        onChanged: _filterItems,
                        onSubmitted: (_) {},
                        onSuffixTap: () {
                          _searchController.clear();
                          _filterItems('');
                        },
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    // Stock summary row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Total Articles',
                              value: '${_foodItems.length}',
                              icon: CupertinoIcons.cube_box,
                              iconColor:
                                  CupertinoTheme.of(context).primaryColor,
                              onTap: () {
                                // Reset the low stock filter and show all items
                                setState(() {
                                  _showingLowStockOnly = false;
                                });
                                _filterItems(_searchController.text);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Articles Bas',
                              value:
                                  '${_foodItems.where((item) => item.quantity <= 10).length}',
                              icon: CupertinoIcons.exclamationmark_triangle,
                              iconColor: CupertinoColors.systemOrange,
                              onTap: _toggleLowStockFilter,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Show active filter indicator when low stock filter is enabled
                    if (_showingLowStockOnly)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemOrange.withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CupertinoColors.systemOrange.withOpacity(
                                0.3,
                              ),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                color: CupertinoColors.systemOrange,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Filtre actif : Articles avec stock bas uniquement',
                                  style: TextStyle(
                                    color: CupertinoColors.systemOrange,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minSize: 0,
                                child: Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  color: CupertinoColors.systemOrange,
                                  size: 20,
                                ),
                                onPressed: _toggleLowStockFilter,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child:
                          _filteredItems.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.cube_box,
                                      size: 50,
                                      color: secondaryTextColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isEmpty
                                          ? AppStrings.noItemsYet
                                          : AppStrings.noItemsMatch,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                    if (_searchController.text.isNotEmpty)
                                      CupertinoButton(
                                        child: const Text(
                                          'Effacer la recherche',
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterItems('');
                                        },
                                      ),
                                  ],
                                ),
                              )
                              : CustomScrollView(
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                slivers: [
                                  CupertinoSliverRefreshControl(
                                    onRefresh: _loadFoodItems,
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate((
                                        context,
                                        index,
                                      ) {
                                        final item = _filteredItems[index];
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cardColor,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: separatorColor,
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed:
                                                () =>
                                                    _showItemDialog(item: item),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                12.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  // Left side with icon based on stock status
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          _getStockStatusColor(
                                                            item.quantity,
                                                          ).withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        _getStockStatusIcon(
                                                          item.quantity,
                                                        ),
                                                        color:
                                                            _getStockStatusColor(
                                                              item.quantity,
                                                            ),
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  // Middle section with item details
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          item.name,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Wrap(
                                                          spacing: 8,
                                                          runSpacing: 4,
                                                          crossAxisAlignment:
                                                              WrapCrossAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              '${item.price.toStringAsFixed(2)} €',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    CupertinoTheme.of(
                                                                      context,
                                                                    ).primaryColor,
                                                              ),
                                                            ),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical: 2,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    themeService
                                                                            .darkMode
                                                                        ? const Color(
                                                                          0xFF2C2C2E,
                                                                        )
                                                                        : CupertinoColors
                                                                            .systemGrey6,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                'Quantité: ${item.quantity}',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      secondaryTextColor,
                                                                ),
                                                              ),
                                                            ),
                                                            _buildStockBadge(
                                                              item.quantity,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Right side with actions
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      CupertinoButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        child: Container(
                                                          width: 36,
                                                          height: 36,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                CupertinoTheme.of(
                                                                      context,
                                                                    )
                                                                    .primaryColor
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            CupertinoIcons
                                                                .pencil,
                                                            color:
                                                                CupertinoTheme.of(
                                                                  context,
                                                                ).primaryColor,
                                                            size: 18,
                                                          ),
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                _showItemDialog(
                                                                  item: item,
                                                                ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      CupertinoButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        child: Container(
                                                          width: 36,
                                                          height: 36,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                CupertinoColors
                                                                    .systemRed
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                            CupertinoIcons
                                                                .delete,
                                                            color:
                                                                CupertinoColors
                                                                    .systemRed,
                                                            size: 18,
                                                          ),
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                _confirmDelete(
                                                                  item,
                                                                ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }, childCount: _filteredItems.length),
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final cardColor = themeService.getCardColor();
    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final separatorColor = themeService.getSeparatorColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: separatorColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStockStatusColor(int quantity) {
    if (quantity <= 0) {
      return CupertinoColors.systemRed;
    } else if (quantity <= 10) {
      // Merge "Avertissement" and "Stock Bas" into one category
      return CupertinoColors.systemOrange;
    } else {
      return CupertinoColors.activeGreen;
    }
  }

  IconData _getStockStatusIcon(int quantity) {
    if (quantity <= 0) {
      return CupertinoIcons.xmark_circle;
    } else if (quantity <= 10) {
      // Use a single icon for all low stock items (1-10)
      return CupertinoIcons.exclamationmark_circle;
    } else {
      return CupertinoIcons.check_mark_circled;
    }
  }
}
