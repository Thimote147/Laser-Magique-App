import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/stock_item_model.dart';
import '../../viewmodels/stock_view_model.dart';

class StockItemDialog extends StatefulWidget {
  final StockItem? item;

  const StockItemDialog({Key? key, this.item}) : super(key: key);

  @override
  State<StockItemDialog> createState() => _StockItemDialogState();
}

class _StockItemDialogState extends State<StockItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _alertThresholdController;
  String _category = 'DRINK';

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name);
    _quantityController = TextEditingController(
      text: item?.quantity.toString(),
    );
    _priceController = TextEditingController(text: item?.price.toString());
    _alertThresholdController = TextEditingController(
      text: item?.alertThreshold.toString(),
    );
    if (item != null) {
      _category = item.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null ? 'Ajouter un article' : 'Modifier l\'article',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantité'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Prix'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _alertThresholdController,
              decoration: const InputDecoration(labelText: 'Seuil d\'alerte'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: _category,
              items: const [
                DropdownMenuItem(value: 'DRINK', child: Text('Boisson')),
                DropdownMenuItem(value: 'FOOD', child: Text('Nourriture')),
                DropdownMenuItem(value: 'OTHER', child: Text('Autre')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            final stockVM = context.read<StockViewModel>();
            if (widget.item == null) {
              stockVM.addItem(
                name: _nameController.text,
                quantity: int.tryParse(_quantityController.text) ?? 0,
                price: double.tryParse(_priceController.text) ?? 0.0,
                alertThreshold:
                    int.tryParse(_alertThresholdController.text) ?? 0,
                category: _category,
              );
            } else {
              final item = StockItem(
                id: widget.item!.id,
                name: _nameController.text,
                quantity: int.tryParse(_quantityController.text) ?? 0,
                price: double.tryParse(_priceController.text) ?? 0.0,
                alertThreshold:
                    int.tryParse(_alertThresholdController.text) ?? 0,
                category: _category,
              );
              stockVM.updateItem(item);
            }

            Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
