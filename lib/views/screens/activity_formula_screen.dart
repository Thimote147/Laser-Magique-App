import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/activity_formula_view_model.dart';
import '../../models/activity_model.dart';
import '../../models/formula_model.dart';
import '../widgets/activity_form_widget.dart';
import '../widgets/formula_form_widget.dart';

class ActivityFormulaScreen extends StatelessWidget {
  const ActivityFormulaScreen({super.key});

  Widget _buildTab(String text, IconData icon) {
    return Tab(
      height: 36,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: DefaultTextStyle.of(context).style,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Theme(
        data: Theme.of(context).copyWith(
          tabBarTheme: TabBarTheme(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Formules et activités'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                    tabs: [
                      _buildTab('Activités', Icons.category_outlined),
                      _buildTab(
                        'Formules',
                        Icons.format_list_bulleted_outlined,
                      ),
                    ],
                    isScrollable: false,
                  ),
                ),
              ),
            ),
          ),
          body: Consumer<ActivityFormulaViewModel>(
            builder: (context, viewModel, child) {
              return TabBarView(
                children: [
                  _buildActivitiesList(context, viewModel),
                  _buildFormulasList(context, viewModel),
                ],
              );
            },
          ),
          floatingActionButton: Builder(
            builder:
                (context) => FloatingActionButton(
                  onPressed: () {
                    final currentIndex = DefaultTabController.of(context).index;
                    if (currentIndex == 0) {
                      _showAddActivityDialog(context);
                    } else {
                      _showAddFormulaDialog(context);
                    }
                  },
                  child: const Icon(Icons.add),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivitiesList(
    BuildContext context,
    ActivityFormulaViewModel viewModel,
  ) {
    if (viewModel.activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune activité',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur + pour en ajouter une',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.activities.length,
      itemBuilder: (context, index) {
        final activity = viewModel.activities[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showEditActivityDialog(context, viewModel, activity),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getActivityIcon(activity.name),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          activity.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed:
                            () => _showEditActivityDialog(
                              context,
                              viewModel,
                              activity,
                            ),
                        tooltip: 'Modifier l\'activité',
                      ),
                    ],
                  ),
                  if (activity.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      activity.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${viewModel.getFormulasForActivity(activity.id).length} formule(s)',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormulasList(
    BuildContext context,
    ActivityFormulaViewModel viewModel,
  ) {
    if (viewModel.formulas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.format_list_bulleted_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune formule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur + pour en ajouter une',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.formulas.length,
      itemBuilder: (context, index) {
        final formula = viewModel.formulas[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showEditFormulaDialog(context, viewModel, formula),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getActivityIcon(formula.activity.name),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formula.activity.name,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formula.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${formula.price.toStringAsFixed(2)}€',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed:
                            () => _showEditFormulaDialog(
                              context,
                              viewModel,
                              formula,
                            ),
                        tooltip: 'Modifier la formule',
                      ),
                    ],
                  ),
                  if (formula.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      formula.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        context,
                        Icons.group_outlined,
                        _formatMinMax(
                          formula.minParticipants,
                          formula.maxParticipants,
                          'pers.',
                        ),
                      ),
                      _buildInfoChip(
                        context,
                        Icons.timer_outlined,
                        '${formula.durationMinutes} min',
                      ),
                      _buildInfoChip(
                        context,
                        Icons.sports_esports_outlined,
                        _formatMinMax(
                          formula.minGames,
                          formula.maxGames,
                          'parties',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatMinMax(int min, int? max, String suffix) {
    if (max == null) {
      return '$min+ $suffix';
    }
    return min == max ? '$min $suffix' : '$min-$max $suffix';
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<T?> _showFormModal<T>(BuildContext context, Widget child) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      builder: (context) => child,
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    _showFormModal(
      context,
      ActivityFormWidget(
        onSave: (name, description) {
          final viewModel = context.read<ActivityFormulaViewModel>();
          viewModel.addActivity(name: name, description: description);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showAddFormulaDialog(BuildContext context) {
    final viewModel = context.read<ActivityFormulaViewModel>();
    _showFormModal(
      context,
      FormulaFormWidget(
        activities: viewModel.activities,
        onSave: (
          name,
          description,
          activity,
          price,
          minParticipants,
          maxParticipants,
          durationMinutes,
          minGames,
          maxGames,
        ) {
          viewModel.addFormula(
            name: name,
            description: description,
            activity: activity,
            price: price,
            minParticipants: minParticipants,
            maxParticipants: maxParticipants,
            durationMinutes: durationMinutes,
            minGames: minGames,
            maxGames: maxGames,
          );
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showEditActivityDialog(
    BuildContext context,
    ActivityFormulaViewModel viewModel,
    Activity activity,
  ) {
    _showFormModal(
      context,
      ActivityFormWidget(
        activity: activity,
        onSave: (name, description) {
          viewModel.updateActivity(
            activity.copyWith(name: name, description: description),
          );
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showEditFormulaDialog(
    BuildContext context,
    ActivityFormulaViewModel viewModel,
    Formula formula,
  ) {
    _showFormModal(
      context,
      FormulaFormWidget(
        formula: formula,
        activities: viewModel.activities,
        onSave: (
          name,
          description,
          activity,
          price,
          minParticipants,
          maxParticipants,
          durationMinutes,
          minGames,
          maxGames,
        ) {
          viewModel.updateFormula(
            formula.copyWith(
              name: name,
              description: description,
              activity: activity,
              price: price,
              minParticipants: minParticipants,
              maxParticipants: maxParticipants,
              durationMinutes: durationMinutes,
              minGames: minGames,
              maxGames: maxGames,
            ),
          );
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

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
}
