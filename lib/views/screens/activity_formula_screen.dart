import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/activity_formula_view_model.dart';
import '../../models/activity_model.dart';
import '../../models/formula_model.dart';

class ActivityFormulaScreen extends StatelessWidget {
  const ActivityFormulaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Formules et activités'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Activités'), Tab(text: 'Formules')],
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
    );
  }

  Widget _buildActivitiesList(
    BuildContext context,
    ActivityFormulaViewModel viewModel,
  ) {
    return ListView.builder(
      itemCount: viewModel.activities.length,
      itemBuilder: (context, index) {
        final activity = viewModel.activities[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(activity.name),
            subtitle:
                activity.description != null
                    ? Text(activity.description!)
                    : null,
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed:
                  () => _showEditActivityDialog(context, viewModel, activity),
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
    return ListView.builder(
      itemCount: viewModel.formulas.length,
      itemBuilder: (context, index) {
        final formula = viewModel.formulas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text('${formula.activity.name} - ${formula.name}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (formula.description != null) Text(formula.description!),
                Text('Prix: ${formula.price.toStringAsFixed(2)}€'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed:
                  () => _showEditFormulaDialog(context, viewModel, formula),
            ),
          ),
        );
      },
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nouvelle activité'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Prix par personne',
                      border: OutlineInputBorder(),
                      prefixText: '€ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                  if (nameController.text.isNotEmpty) {
                    final viewModel = context.read<ActivityFormulaViewModel>();
                    viewModel.addActivity(
                      name: nameController.text,
                      description:
                          descriptionController.text.isNotEmpty
                              ? descriptionController.text
                              : null,
                      pricePerPerson:
                          priceController.text.isNotEmpty
                              ? double.parse(priceController.text)
                              : null,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
    );
  }

  void _showAddFormulaDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final minParticipantsController = TextEditingController();
    final maxParticipantsController = TextEditingController();
    final defaultGameCountController = TextEditingController();

    final viewModel = context.read<ActivityFormulaViewModel>();
    Activity? selectedActivity;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Nouvelle formule'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<Activity>(
                          value: selectedActivity,
                          decoration: const InputDecoration(
                            labelText: 'Activité *',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              viewModel.activities.map((activity) {
                                return DropdownMenuItem(
                                  value: activity,
                                  child: Text(activity.name),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() => selectedActivity = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Prix *',
                            border: OutlineInputBorder(),
                            prefixText: '€ ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: minParticipantsController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre minimum de personnes',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: maxParticipantsController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre maximum de personnes',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: defaultGameCountController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de parties par défaut',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty &&
                            selectedActivity != null &&
                            priceController.text.isNotEmpty) {
                          viewModel.addFormula(
                            name: nameController.text,
                            description: descriptionController.text,
                            price: double.tryParse(priceController.text) ?? 0.0,
                            activity: selectedActivity!,
                            minParticipants:
                                minParticipantsController.text.isNotEmpty
                                    ? int.parse(minParticipantsController.text)
                                    : null,
                            maxParticipants:
                                maxParticipantsController.text.isNotEmpty
                                    ? int.parse(maxParticipantsController.text)
                                    : null,
                            defaultGameCount:
                                defaultGameCountController.text.isNotEmpty
                                    ? int.parse(defaultGameCountController.text)
                                    : null,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Créer'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditActivityDialog(
    BuildContext context,
    ActivityFormulaViewModel viewModel,
    Activity activity,
  ) {
    final nameController = TextEditingController(text: activity.name);
    final descriptionController = TextEditingController(
      text: activity.description ?? '',
    );
    final priceController = TextEditingController(
      text: activity.pricePerPerson?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modifier l\'activité'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Prix par personne',
                      border: OutlineInputBorder(),
                      prefixText: '€ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                  if (nameController.text.isNotEmpty) {
                    viewModel.updateActivity(
                      activity.copyWith(
                        name: nameController.text,
                        description:
                            descriptionController.text.isNotEmpty
                                ? descriptionController.text
                                : null,
                        pricePerPerson:
                            priceController.text.isNotEmpty
                                ? double.parse(priceController.text)
                                : null,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  void _showEditFormulaDialog(
    BuildContext context,
    ActivityFormulaViewModel viewModel,
    Formula formula,
  ) {
    final nameController = TextEditingController(text: formula.name);
    final descriptionController = TextEditingController(
      text: formula.description ?? '',
    );
    final priceController = TextEditingController(
      text: formula.price.toString(),
    );
    final minParticipantsController = TextEditingController(
      text: formula.minParticipants?.toString() ?? '',
    );
    final maxParticipantsController = TextEditingController(
      text: formula.maxParticipants?.toString() ?? '',
    );
    final defaultGameCountController = TextEditingController(
      text: formula.defaultGameCount?.toString() ?? '',
    );
    final minGamesController = TextEditingController(
      text: formula.minGames?.toString() ?? '',
    );
    final maxGamesController = TextEditingController(
      text: formula.maxGames?.toString() ?? '',
    );

    final viewModel = context.read<ActivityFormulaViewModel>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Modifier ${formula.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Prix'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  TextField(
                    controller: minParticipantsController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre minimum de personnes',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: maxParticipantsController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre maximum de personnes',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: defaultGameCountController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de parties par défaut',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: minGamesController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre minimum de parties',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: maxGamesController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre maximum de parties',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  viewModel.updateFormula(
                    formula.copyWith(
                      name: nameController.text,
                      description: descriptionController.text,
                      price:
                          double.tryParse(priceController.text) ??
                          formula.price,
                      minParticipants:
                          minParticipantsController.text.isNotEmpty
                              ? int.parse(minParticipantsController.text)
                              : null,
                      maxParticipants:
                          maxParticipantsController.text.isNotEmpty
                              ? int.parse(maxParticipantsController.text)
                              : null,
                      defaultGameCount:
                          defaultGameCountController.text.isNotEmpty
                              ? int.parse(defaultGameCountController.text)
                              : null,
                      minGames:
                          minGamesController.text.isNotEmpty
                              ? int.parse(minGamesController.text)
                              : null,
                      maxGames:
                          maxGamesController.text.isNotEmpty
                              ? int.parse(maxGamesController.text)
                              : null,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }
}
