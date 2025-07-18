import 'package:flutter/material.dart';
import 'models/activity_model.dart';

class ActivityFormWidget extends StatefulWidget {
  final Activity? activity;
  final Function(String name, String? description) onSave;
  final VoidCallback onCancel;

  const ActivityFormWidget({
    super.key,
    this.activity,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ActivityFormWidget> createState() => _ActivityFormWidgetState();
}

class _ActivityFormWidgetState extends State<ActivityFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.activity != null) {
      _nameController.text = widget.activity!.name;
      _descriptionController.text = widget.activity!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
              color: Theme.of(context).colorScheme.outline.withAlpha((255 * 0.2).round()),
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
                    ),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.all(12),
          hintText: label,
          hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.normal,
          ),
          helperText: helperText,
          helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
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
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.activity == null
                      ? 'Nouvelle activité'
                      : 'Modifier l\'activité',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Fermer',
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
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nom de l\'activité',
                        validator:
                            (value) =>
                                value?.isEmpty == true
                                    ? 'Le nom est requis'
                                    : null,
                      ),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description (facultative)',
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Bouton d'action
                  FilledButton.icon(
                    onPressed: () {
                      if (_formKey.currentState?.validate() == true) {
                        widget.onSave(
                          _nameController.text,
                          _descriptionController.text.isNotEmpty
                              ? _descriptionController.text
                              : null,
                        );
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: Text(widget.activity == null ? 'Ajouter' : 'Enregistrer'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
