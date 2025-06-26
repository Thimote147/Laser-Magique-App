import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/activity_model.dart';
import 'models/formula_model.dart';

class FormulaFormWidget extends StatefulWidget {
  final Formula? formula;
  final List<Activity> activities;
  final Function(
    String name,
    String? description,
    Activity activity,
    double price,
    int minParticipants,
    int? maxParticipants,
    int durationMinutes,
    int minGames,
    int? maxGames,
  )
  onSave;
  final VoidCallback onCancel;

  const FormulaFormWidget({
    super.key,
    this.formula,
    required this.activities,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<FormulaFormWidget> createState() => _FormulaFormWidgetState();
}

class _FormulaFormWidgetState extends State<FormulaFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final minParticipantsController = TextEditingController();
  final maxParticipantsController = TextEditingController();
  final durationController = TextEditingController(text: '15');
  final minGamesController = TextEditingController(text: '1');
  final maxGamesController = TextEditingController();
  Activity? selectedActivity;

  @override
  void initState() {
    super.initState();
    if (widget.formula != null) {
      nameController.text = widget.formula!.name;
      descriptionController.text = widget.formula!.description ?? '';
      priceController.text = widget.formula!.price.toString();
      minParticipantsController.text =
          widget.formula!.minParticipants.toString();
      maxParticipantsController.text =
          widget.formula!.maxParticipants?.toString() ?? '';
      durationController.text = widget.formula!.durationMinutes.toString();
      minGamesController.text = widget.formula!.minGames.toString();
      maxGamesController.text = widget.formula!.maxGames?.toString() ?? '';
      selectedActivity = widget.formula!.activity;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    minParticipantsController.dispose();
    maxParticipantsController.dispose();
    durationController.dispose();
    minGamesController.dispose();
    maxGamesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                ),
                Text(
                  widget.formula == null
                      ? 'Nouvelle formule'
                      : 'Modifier la formule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() == true) {
                      widget.onSave(
                        nameController.text,
                        descriptionController.text.isNotEmpty
                            ? descriptionController.text
                            : null,
                        selectedActivity!,
                        double.parse(priceController.text),
                        int.parse(minParticipantsController.text),
                        maxParticipantsController.text.isNotEmpty
                            ? int.parse(maxParticipantsController.text)
                            : null,
                        int.parse(durationController.text),
                        int.parse(minGamesController.text),
                        maxGamesController.text.isNotEmpty
                            ? int.parse(maxGamesController.text)
                            : null,
                      );
                    }
                  },
                  child: Text(
                    widget.formula == null ? 'Ajouter' : 'Enregistrer',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Form content
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _buildSection(
                    title: 'Informations générales',
                    icon: Icons.description_outlined,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 12,
                                top: 8,
                              ),
                              child: Text(
                                'Activité',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            DropdownButtonFormField<Activity>(
                              value: selectedActivity,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.fromLTRB(
                                  12,
                                  4,
                                  12,
                                  8,
                                ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                              ),
                              items:
                                  widget.activities
                                      .map(
                                        (activity) => DropdownMenuItem(
                                          value: activity,
                                          child: Text(
                                            activity.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedActivity = value;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Veuillez sélectionner une activité'
                                          : null,
                            ),
                          ],
                        ),
                      ),
                      _buildTextField(
                        controller: nameController,
                        label: 'Nom',
                        validator:
                            (value) =>
                                value?.isEmpty == true
                                    ? 'Le nom est requis'
                                    : null,
                      ),
                      _buildTextField(
                        controller: descriptionController,
                        label: 'Description',
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Tarification',
                    icon: Icons.payments_outlined,
                    children: [
                      _buildTextField(
                        controller: priceController,
                        label: 'Prix',
                        prefixText: '€ ',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        validator: (value) {
                          if (value?.isEmpty == true)
                            return 'Le prix est requis';
                          if (double.tryParse(value!) == null)
                            return 'Prix invalide';
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Configuration',
                    icon: Icons.tune_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: minParticipantsController,
                              label: 'Min. participants',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value?.isEmpty == true) return 'Requis';
                                final number = int.tryParse(value!);
                                if (number == null || number < 1)
                                  return 'Min. 1';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: maxParticipantsController,
                              label: 'Max. participants',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value?.isNotEmpty == true) {
                                  final max = int.tryParse(value!);
                                  final min = int.tryParse(
                                    minParticipantsController.text,
                                  );
                                  if (max != null && min != null && max < min) {
                                    return 'Doit être ≥ min';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      _buildTextField(
                        controller: durationController,
                        label: 'Durée (minutes)',
                        helperText: 'Valeur par défaut : 15 minutes',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Requis';
                          final number = int.tryParse(value!);
                          if (number == null || number < 1)
                            return 'Min. 1 minute';
                          return null;
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: minGamesController,
                              label: 'Min. parties',
                              helperText: 'Valeur par défaut : 1',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value?.isEmpty == true) return 'Requis';
                                final number = int.tryParse(value!);
                                if (number == null || number < 1)
                                  return 'Min. 1';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: maxGamesController,
                              label: 'Max. parties',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value?.isNotEmpty == true) {
                                  final max = int.tryParse(value!);
                                  final min = int.tryParse(
                                    minGamesController.text,
                                  );
                                  if (max != null && min != null && max < min) {
                                    return 'Doit être ≥ min';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...children
                    .expand(
                      (child) => [
                        child,
                        if (child != children.last) const SizedBox(height: 12),
                      ],
                    )
                    .toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? helperText,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              helperText: helperText,
              helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              helperMaxLines: 2,
              prefixText: prefixText,
              prefixStyle: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
