import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/equipment_model.dart';
import '../../viewmodels/employee_profile_view_model.dart';

class EquipmentManagementScreen extends StatelessWidget {
  const EquipmentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemple de données statiques, à remplacer par une source réelle plus tard
    final List<Equipment> equipmentList = [
      Equipment(name: 'Laser Gun 1', isFunctional: true),
      Equipment(
        name: 'Laser Gun 2',
        isFunctional: false,
        description: 'Batterie défectueuse',
      ),
      Equipment(name: 'Gilet 1', isFunctional: true),
      Equipment(
        name: 'Gilet 2',
        isFunctional: false,
        description: 'Capteur cassé',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion du matériel')),
      floatingActionButton:
          Provider.of<EmployeeProfileViewModel>(context).role == UserRole.admin
              ? FloatingActionButton.extended(
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder:
                        (context) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: _EquipmentEditModal(
                            equipment: Equipment(name: '', isFunctional: true),
                            onSave: (newEquipment) {
                              // TODO: Ajouter à la liste réelle
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Matériel ajouté (démo)'),
                                ),
                              );
                            },
                          ),
                        ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              )
              : null,
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: equipmentList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final equipment = equipmentList[index];
          final colorScheme = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color:
                    equipment.isFunctional
                        ? colorScheme.primary.withOpacity(0.18)
                        : colorScheme.error.withOpacity(0.22),
              ),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 8),
                    child: Icon(
                      equipment.isFunctional ? Icons.check_circle : Icons.error,
                      color:
                          equipment.isFunctional
                              ? colorScheme.primary
                              : colorScheme.error,
                      size: 32,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          equipment.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (!equipment.isFunctional &&
                            equipment.description != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              equipment.description!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          equipment.isFunctional
                              ? colorScheme.primary.withOpacity(
                                isDark ? 0.13 : 0.09,
                              )
                              : colorScheme.error.withOpacity(
                                isDark ? 0.13 : 0.09,
                              ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      equipment.isFunctional
                          ? 'Fonctionnel'
                          : 'Non fonctionnel',
                      style: TextStyle(
                        color:
                            equipment.isFunctional
                                ? colorScheme.primary
                                : colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 22),
                    tooltip: 'Modifier',
                    color: colorScheme.primary,
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder:
                            (context) => Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: _EquipmentEditModal(
                                equipment: equipment,
                                onSave: (updated) {
                                  // TODO: Mettre à jour la liste réelle
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Matériel mis à jour (démo)',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EquipmentEditModal extends StatefulWidget {
  final Equipment equipment;
  final void Function(Equipment) onSave;
  const _EquipmentEditModal({required this.equipment, required this.onSave});

  @override
  State<_EquipmentEditModal> createState() => _EquipmentEditModalState();
}

class _EquipmentEditModalState extends State<_EquipmentEditModal> {
  late bool isFunctional;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    isFunctional = widget.equipment.isFunctional;
    descriptionController = TextEditingController(
      text: widget.equipment.description ?? '',
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Modifier ${widget.equipment.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: isFunctional,
            onChanged: (val) {
              setState(() => isFunctional = val);
            },
            title: const Text('Fonctionnel'),
            activeColor: colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
          if (!isFunctional)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description du problème',
                  hintText: 'Ex : Batterie à changer',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  widget.onSave(
                    Equipment(
                      name: widget.equipment.name,
                      isFunctional: isFunctional,
                      description:
                          isFunctional
                              ? null
                              : descriptionController.text.trim(),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
