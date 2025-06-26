import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';

class EquipmentEditModal extends StatefulWidget {
  final Equipment equipment;
  final void Function(Equipment) onSave;
  
  const EquipmentEditModal({
    super.key,
    required this.equipment,
    required this.onSave,
  });

  @override
  State<EquipmentEditModal> createState() => _EquipmentEditModalState();

  static Future<void> show(
    BuildContext context,
    Equipment equipment,
    void Function(Equipment) onSave,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      builder: (context) => EquipmentEditModal(
        equipment: equipment,
        onSave: onSave,
      ),
    );
  }
}

class _EquipmentEditModalState extends State<EquipmentEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late bool isFunctional;
  bool _isAddMode = false;

  @override
  void initState() {
    super.initState();
    _isAddMode = widget.equipment.name.isEmpty;
    nameController = TextEditingController(text: widget.equipment.name);
    descriptionController = TextEditingController(
      text: widget.equipment.description ?? '',
    );
    isFunctional = widget.equipment.isFunctional;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  _isAddMode ? 'Nouvel équipement' : 'Modifier l\'équipement',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: _saveEquipment,
                  child: Text(
                    _isAddMode ? 'Ajouter' : 'Enregistrer',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
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
                    icon: Icons.inventory_2_outlined,
                    children: [
                      if (_isAddMode)
                        _buildTextField(
                          controller: nameController,
                          label: 'Nom de l\'équipement',
                          validator: (value) => value?.isEmpty == true
                              ? 'Le nom est requis'
                              : null,
                        ),
                      if (!_isAddMode)
                        _buildInfoContainer(
                          label: 'Équipement',
                          value: widget.equipment.name,
                          icon: _getEquipmentIcon(widget.equipment.name),
                          color: _getEquipmentColor(widget.equipment.name, theme),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'État de fonctionnement',
                    icon: Icons.settings_outlined,
                    children: [
                      _buildStatusToggle(theme),
                      if (!isFunctional) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: descriptionController,
                          label: 'Description du problème',
                          helperText: 'Décrivez le problème rencontré',
                          maxLines: 3,
                          validator: (value) => !isFunctional && value?.trim().isEmpty == true
                              ? 'Une description du problème est requise'
                              : null,
                        ),
                      ],
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
    final theme = Theme.of(context);
    
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
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
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
              color: theme.colorScheme.outline.withOpacity(0.2),
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              helperText: helperText,
              helperStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              helperMaxLines: 2,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
            maxLines: maxLines,
            validator: validator,
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContainer({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
            child: Text(
              'État',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatusOption(
                    theme,
                    icon: Icons.check_circle,
                    label: 'Fonctionnel',
                    isSelected: isFunctional,
                    color: theme.colorScheme.primary,
                    onTap: () => setState(() => isFunctional = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusOption(
                    theme,
                    icon: Icons.error,
                    label: 'En panne',
                    isSelected: !isFunctional,
                    color: theme.colorScheme.error,
                    onTap: () => setState(() => isFunctional = false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEquipmentIcon(String name) {
    if (name.toLowerCase().contains('gun') || name.toLowerCase().contains('laser')) {
      return Icons.sports_esports;
    } else if (name.toLowerCase().contains('gilet') || name.toLowerCase().contains('vest')) {
      return Icons.sports_martial_arts;
    }
    return Icons.devices;
  }

  Color _getEquipmentColor(String name, ThemeData theme) {
    if (name.toLowerCase().contains('gun') || name.toLowerCase().contains('laser')) {
      return theme.colorScheme.primary;
    } else if (name.toLowerCase().contains('gilet') || name.toLowerCase().contains('vest')) {
      return theme.colorScheme.secondary;
    }
    return theme.colorScheme.tertiary;
  }

  void _saveEquipment() {
    if (_formKey.currentState?.validate() == true) {
      final now = DateTime.now();
      widget.onSave(
        Equipment(
          id: widget.equipment.id,
          name: _isAddMode ? nameController.text.trim() : widget.equipment.name,
          isFunctional: isFunctional,
          description: isFunctional ? null : descriptionController.text.trim(),
          createdAt: widget.equipment.createdAt,
          updatedAt: now,
        ),
      );
      Navigator.pop(context);
    }
  }
}