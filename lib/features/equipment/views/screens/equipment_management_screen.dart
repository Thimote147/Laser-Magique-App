import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/equipment_model.dart';
import '../../viewmodels/equipment_view_model.dart';
import '../../../profile/viewmodels/employee_profile_view_model.dart';
import '../widgets/equipment_edit_modal.dart';

class EquipmentManagementScreen extends StatefulWidget {
  const EquipmentManagementScreen({super.key});

  @override
  State<EquipmentManagementScreen> createState() =>
      _EquipmentManagementScreenState();
}

class _EquipmentManagementScreenState extends State<EquipmentManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentViewModel>().loadEquipment();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EquipmentViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestion du matériel'),
            elevation: 0,
            actions: [
              if (viewModel.error != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => viewModel.loadEquipment(),
                  tooltip: 'Actualiser',
                ),
            ],
          ),
          floatingActionButton:
              Provider.of<EmployeeProfileViewModel>(context).role ==
                      UserRole.admin
                  ? FloatingActionButton(
                    onPressed: () => _showAddEquipmentDialog(context),
                    child: const Icon(Icons.add),
                  )
                  : null,
          body: _buildBody(context, viewModel),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, EquipmentViewModel viewModel) {
    if (viewModel.isLoading && viewModel.equipment.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des équipements...'),
          ],
        ),
      );
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.loadEquipment(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadEquipment(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(context, viewModel),
            const SizedBox(height: 24),
            _buildEquipmentSection(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    EquipmentViewModel viewModel,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Vue d\'ensemble',
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
            side: BorderSide(color: theme.colorScheme.outline.withAlpha((255 * 0.2).round())),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    viewModel,
                    Icons.check_circle,
                    'Fonctionnel',
                    viewModel.functionalCount.toString(),
                    theme.colorScheme.primary,
                    EquipmentFilter.functional,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.outline.withAlpha((255 * 0.2).round()),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    viewModel,
                    Icons.error,
                    'En panne',
                    viewModel.nonFunctionalCount.toString(),
                    theme.colorScheme.error,
                    EquipmentFilter.nonFunctional,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.outline.withAlpha((255 * 0.2).round()),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    viewModel,
                    Icons.inventory,
                    'Total',
                    viewModel.totalCount.toString(),
                    theme.colorScheme.onSurfaceVariant,
                    EquipmentFilter.all,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    EquipmentViewModel viewModel,
    IconData icon,
    String label,
    String value,
    Color color,
    EquipmentFilter filter,
  ) {
    final theme = Theme.of(context);
    final isSelected = viewModel.currentFilter == filter;

    return InkWell(
      onTap: () => viewModel.setFilter(filter),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withAlpha((255 * 0.1).round()) : Colors.transparent,
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : color.withAlpha((255 * 0.7).round()),
              size: isSelected ? 26 : 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? color : color.withAlpha((255 * 0.8).round()),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  int _naturalCompare(String a, String b) {
    final regex = RegExp(r'\d+|\D+');
    final aMatches = regex.allMatches(a);
    final bMatches = regex.allMatches(b);
    final aParts = aMatches.map((m) => m.group(0)!).toList();
    final bParts = bMatches.map((m) => m.group(0)!).toList();
    for (var i = 0; i < aParts.length && i < bParts.length; i++) {
      final aPart = aParts[i];
      final bPart = bParts[i];
      final aNum = int.tryParse(aPart);
      final bNum = int.tryParse(bPart);
      if (aNum != null && bNum != null) {
        if (aNum != bNum) return aNum.compareTo(bNum);
      } else {
        final cmp = aPart.compareTo(bPart);
        if (cmp != 0) return cmp;
      }
    }
    return aParts.length.compareTo(bParts.length);
  }

  Widget _buildEquipmentSection(
    BuildContext context,
    EquipmentViewModel viewModel,
  ) {
    final equipmentList = [...viewModel.equipment];
    equipmentList.sort((a, b) => _naturalCompare(a.name, b.name));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.devices, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                _getSectionTitle(viewModel),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (equipmentList.isEmpty)
          _buildEmptyState(context, viewModel)
        else
          ...equipmentList.map(
            (equipment) => _buildEquipmentCard(context, equipment, viewModel),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, EquipmentViewModel viewModel) {
    final theme = Theme.of(context);

    String getEmptyMessage() {
      switch (viewModel.currentFilter) {
        case EquipmentFilter.functional:
          return 'Aucun équipement fonctionnel';
        case EquipmentFilter.nonFunctional:
          return 'Aucun équipement en panne';
        case EquipmentFilter.all:
          return 'Aucun équipement';
      }
    }

    String getEmptySubMessage() {
      switch (viewModel.currentFilter) {
        case EquipmentFilter.functional:
          return 'Tous vos équipements sont actuellement en panne ou aucun équipement n\'est ajouté';
        case EquipmentFilter.nonFunctional:
          return 'Parfait ! Tous vos équipements sont fonctionnels';
        case EquipmentFilter.all:
          return 'Appuyez sur + pour ajouter votre premier équipement';
      }
    }

    return Center(
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outline.withAlpha((255 * 0.2).round())),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  viewModel.currentFilter == EquipmentFilter.nonFunctional
                      ? Icons.check_circle_outline
                      : Icons.inventory_2_outlined,
                  size: 48,
                  color:
                      viewModel.currentFilter == EquipmentFilter.nonFunctional
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  getEmptyMessage(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getEmptySubMessage(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(
    BuildContext context,
    Equipment equipment,
    EquipmentViewModel viewModel,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha((255 * 0.2).round())),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditDialog(context, equipment, viewModel),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getEquipmentColor(
                        equipment.name,
                        theme,
                      ).withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEquipmentIcon(equipment.name),
                      color: _getEquipmentColor(equipment.name, theme),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          equipment.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getEquipmentType(equipment.name),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context, equipment),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (!equipment.isFunctional && equipment.description != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withAlpha((255 * 0.3).round()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withAlpha((255 * 0.3).round()),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          equipment.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Equipment equipment) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            equipment.isFunctional
                ? theme.colorScheme.primary.withAlpha((255 * 0.1).round())
                : theme.colorScheme.error.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            equipment.isFunctional ? Icons.check_circle : Icons.error,
            size: 14,
            color:
                equipment.isFunctional
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            equipment.isFunctional ? 'OK' : 'HS',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  equipment.isFunctional
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEquipmentIcon(String name) {
    if (name.toLowerCase().contains('gun') ||
        name.toLowerCase().contains('laser')) {
      return Icons.sports_esports;
    } else if (name.toLowerCase().contains('gilet') ||
        name.toLowerCase().contains('vest')) {
      return Icons.sports_martial_arts;
    }
    return Icons.devices;
  }

  Color _getEquipmentColor(String name, ThemeData theme) {
    if (name.toLowerCase().contains('gun') ||
        name.toLowerCase().contains('laser')) {
      return theme.colorScheme.primary;
    } else if (name.toLowerCase().contains('gilet') ||
        name.toLowerCase().contains('vest')) {
      return theme.colorScheme.secondary;
    }
    return theme.colorScheme.tertiary;
  }

  String _getEquipmentType(String name) {
    if (name.toLowerCase().contains('gun') ||
        name.toLowerCase().contains('laser')) {
      return 'Pistolet laser';
    } else if (name.toLowerCase().contains('gilet') ||
        name.toLowerCase().contains('vest')) {
      return 'Gilet de jeu';
    }
    return 'Équipement';
  }

  void _showAddEquipmentDialog(BuildContext context) async {
    final now = DateTime.now();
    final newEquipment = Equipment(
      id: '',
      name: '',
      isFunctional: true,
      createdAt: now,
      updatedAt: now,
    );

    await EquipmentEditModal.show(context, newEquipment, (equipment) async {
      try {
        await context.read<EquipmentViewModel>().addEquipment(
          name: equipment.name,
          isFunctional: equipment.isFunctional,
          description: equipment.description,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Équipement ajouté avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  void _showEditDialog(
    BuildContext context,
    Equipment equipment,
    EquipmentViewModel viewModel,
  ) async {
    await EquipmentEditModal.show(context, equipment, (updated) async {
      try {
        await viewModel.updateEquipment(updated);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Équipement mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  String _getSectionTitle(EquipmentViewModel viewModel) {
    final count = viewModel.equipment.length;
    switch (viewModel.currentFilter) {
      case EquipmentFilter.functional:
        return 'Équipements fonctionnels ($count)';
      case EquipmentFilter.nonFunctional:
        return 'Équipements en panne ($count)';
      case EquipmentFilter.all:
        return 'Équipements ($count)';
    }
  }
}
