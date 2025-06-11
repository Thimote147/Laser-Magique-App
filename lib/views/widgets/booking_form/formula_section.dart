import 'package:flutter/material.dart';
import '../../../models/formula_model.dart';

class FormulaSection extends StatelessWidget {
  final Formula? selectedFormula;
  final List<Formula> formulas;
  final Function(Formula?) onFormulaChanged;
  final int numberOfPersons;
  final int numberOfGames;
  final Function(int) onPersonsChanged;
  final Function(int) onGamesChanged;

  const FormulaSection({
    super.key,
    required this.selectedFormula,
    required this.formulas,
    required this.onFormulaChanged,
    required this.numberOfPersons,
    required this.numberOfGames,
    required this.onPersonsChanged,
    required this.onGamesChanged,
  });

  IconData _getActivityIcon(String activityName) {
    switch (activityName.toLowerCase()) {
      case 'laser game':
        return Icons.sports_esports;
      case 'réalité virtuelle':
        return Icons.vrpano;
      case 'arcade':
        return Icons.gamepad;
      case 'karaoké':
        return Icons.mic;
      default:
        return Icons.extension;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total =
        selectedFormula != null
            ? selectedFormula!.price * numberOfPersons * numberOfGames
            : 0.0;

    Widget buildFormulaItem(Formula formula, {bool inDropdown = false}) {
      final icon = _getActivityIcon(formula.activity.name);
      return SizedBox(
        height: 24,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, size: 14, color: theme.primaryColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child:
                  !inDropdown
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formula.activity.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              height: 1,
                            ),
                          ),
                          Text(
                            formula.name,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formula.activity.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              height: 1,
                            ),
                          ),
                          Text(
                            formula.name,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${formula.price.toStringAsFixed(2)}€',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  height: 1,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Formule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (selectedFormula != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sélectionnée',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (formulas.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<Formula>(
                  value: selectedFormula,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
                  dropdownColor: theme.cardColor,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                    hintText: 'Sélectionner une formule',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return formulas.map((Formula formula) {
                      return buildFormulaItem(formula);
                    }).toList();
                  },
                  items:
                      formulas.map((formula) {
                        return DropdownMenuItem<Formula>(
                          value: formula,
                          child: buildFormulaItem(formula, inDropdown: true),
                        );
                      }).toList(),
                  onChanged: onFormulaChanged,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.groups, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Personnes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 40),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<int>(
                          value: numberOfPersons,
                          isExpanded: true,
                          isDense: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          items:
                              List.generate(20, (index) => index + 1)
                                  .map(
                                    (value) => DropdownMenuItem<int>(
                                      value: value,
                                      child: Text(
                                        value.toString(),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) onPersonsChanged(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Parties',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 40),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<int>(
                          value: numberOfGames,
                          isExpanded: true,
                          isDense: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          items:
                              List.generate(5, (index) => index + 1)
                                  .map(
                                    (value) => DropdownMenuItem<int>(
                                      value: value,
                                      child: Text(
                                        value.toString(),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) onGamesChanged(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (selectedFormula != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)}€',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
