import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../features/statistics/viewmodels/statistics_view_model.dart';
import '../features/statistics/models/daily_statistics_model.dart';
import '../features/statistics/models/cash_movement_model.dart';
import '../features/statistics/widgets/cash_movement_dialog.dart';
import '../features/statistics/services/pdf_export_service.dart';
import './user_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with AutomaticKeepAliveClientMixin {
  late StatisticsViewModel _viewModel;

  // Permet de conserver l'état lorsqu'on navigue entre les onglets
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _viewModel = StatisticsViewModel();
    _viewModel.loadStatistics();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super.build for AutomaticKeepAliveClientMixin
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Statistiques'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          actions: [
            // Vérifier si l'utilisateur est admin avant d'afficher le bouton PDF
            Builder(
              builder: (context) {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                final bool isAdmin = userProvider.isAdmin;

                if (isAdmin) {
                  return IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: 'Exporter en PDF',
                    onPressed: () => _exportStatistics(context),
                  );
                } else {
                  return const SizedBox.shrink(); // Ne rien afficher pour les non-admins
                }
              },
            ),
          ],
        ),
        body: Consumer<StatisticsViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.currentStatistics == null) {
              return _buildLoadingWidget();
            }

            if (viewModel.error != null) {
              return _buildErrorWidget(viewModel.error!);
            }

            final statistics = viewModel.currentStatistics;
            if (statistics == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune donnée disponible pour cette période',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Changer de date'),
                    ),
                  ],
                ),
              );
            }

            return GestureDetector(
              onTap: () {
                // Fermer le clavier quand on tape en dehors des champs
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  _buildDateHeader(viewModel),
                  const SizedBox(height: 16),
                  // N'afficher la section de saisie manuelle que pour la vue jour
                  if (viewModel.periodType == PeriodType.day) ...[
                    _buildManualFieldsSection(viewModel),
                    const SizedBox(height: 16),
                  ],
                  _buildPaymentMethodsSection(statistics),
                  const SizedBox(height: 16),
                  _buildCategoriesSection(statistics),
                  const SizedBox(height: 16),
                  // N'afficher le résumé de caisse que pour la vue jour
                  if (viewModel.periodType == PeriodType.day) ...[
                    // Utiliser un Consumer pour s'assurer que cette section se reconstruit
                    // lorsque le ViewModel change, indépendamment du reste de l'interface
                    Consumer<StatisticsViewModel>(
                      builder: (context, vm, child) {
                        // Force la reconstruction chaque fois que le ViewModel change
                        return _buildSummarySection(vm);
                      },
                    ),
                  ],
                ],
              ),
            ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateHeader(StatisticsViewModel viewModel) {
    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withAlpha((255 * 0.2).round()),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Période',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (viewModel.isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Chargement...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap:
                      viewModel.isLoading ? null : () => _selectDate(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withAlpha((255 * 0.3).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.today,
                          size: 20,
                          color:
                              viewModel.isLoading
                                  ? Theme.of(context).disabledColor
                                  : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date sélectionnée',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(viewModel.selectedDate),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Actualiser',
                          onPressed:
                              viewModel.isLoading
                                  ? null
                                  : () => viewModel.refreshStatistics(),
                          iconSize: 20,
                          color:
                              viewModel.isLoading
                                  ? Theme.of(context).disabledColor
                                  : Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                // Obtenir le statut admin pour déterminer s'il faut ajouter un espace supplémentaire
                Builder(
                  builder: (context) {
                    return Column(children: [_buildPeriodSelector(viewModel)]);
                  },
                ),
                if (viewModel.isLoading &&
                    viewModel.periodType != PeriodType.day)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: LinearProgressIndicator(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha((255 * 0.1).round()),
                      color: Theme.of(context).colorScheme.primary,
                      minHeight: 4,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (viewModel.periodType != PeriodType.day &&
            viewModel.periodStatistics.length > 1)
          _buildSalesEvolutionChart(viewModel),
      ],
    );
  }

  Widget _buildPeriodSelector(StatisticsViewModel viewModel) {
    // Obtenir le statut admin de l'utilisateur
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isAdmin = userProvider.isAdmin;

    // Si l'utilisateur n'est pas administrateur, ne pas afficher la section "Vue"
    if (!isAdmin) {
      return const SizedBox.shrink(); // Retourne un widget vide
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Vue',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withAlpha((255 * 0.3).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPeriodButton(
                label: 'Jour',
                icon: Icons.today,
                selected: viewModel.periodType == PeriodType.day,
                onTap:
                    () => viewModel.changePeriodType(
                      PeriodType.day,
                      isAdmin: isAdmin,
                    ),
              ),
              _buildPeriodButton(
                label: 'Semaine',
                icon: Icons.date_range,
                selected: viewModel.periodType == PeriodType.week,
                onTap:
                    () => viewModel.changePeriodType(
                      PeriodType.week,
                      isAdmin: isAdmin,
                    ),
              ),
              _buildPeriodButton(
                label: 'Mois',
                icon: Icons.calendar_month,
                selected: viewModel.periodType == PeriodType.month,
                onTap:
                    () => viewModel.changePeriodType(
                      PeriodType.month,
                      isAdmin: isAdmin,
                    ),
              ),
              _buildPeriodButton(
                label: 'Année',
                icon: Icons.calendar_today,
                selected: viewModel.periodType == PeriodType.year,
                onTap:
                    () => viewModel.changePeriodType(
                      PeriodType.year,
                      isAdmin: isAdmin,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Consumer<StatisticsViewModel>(
        builder: (context, viewModel, child) {
          return InkWell(
            onTap: viewModel.isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color:
                    selected
                        ? Theme.of(context).colorScheme.primary.withAlpha((255 * 0.2).round())
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color:
                        viewModel.isLoading
                            ? Theme.of(context).disabledColor
                            : selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color:
                          viewModel.isLoading
                              ? Theme.of(context).disabledColor
                              : selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildManualFieldsSection(StatisticsViewModel viewModel) {
    // Nous n'effectuons plus de calcul automatique du fond de caisse de fermeture
    // car il s'agit maintenant d'une saisie manuelle

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Saisie manuelle', Icons.edit_rounded),
        // Utiliser un Consumer ici pour s'assurer que toute la carte est reconstruite
        // lorsque le ViewModel change
        Consumer<StatisticsViewModel>(
          builder: (context, vm, child) {
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withAlpha((255 * 0.2).round()),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildManualFieldContainer(
                      'Fond de caisse ouverture',
                      vm.fondOuvertureController,
                      (value) async {
                        // Utiliser une mise à jour asynchrone pour éviter les blocages UI
                        await vm.updateManualField('fond_ouverture', value);
                      },
                      Icons.account_balance_wallet,
                      'Obligatoire',
                      readOnly: _isDateInPast(),
                    ),

                    // Afficher l'alerte de différence de fond de caisse si nécessaire
                    // Ne pas afficher si le fond d'ouverture est à 0
                    if (vm.balanceMismatch &&
                        vm.previousDayClosingBalance != null &&
                        double.tryParse(vm.fondOuvertureController.text) !=
                            0) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Différence avec la caisse de la veille',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fermeture veille: ${vm.formatCurrency(vm.previousDayClosingBalance)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Différence: ${vm.balanceDifference.abs().toStringAsFixed(2).replaceAll('.', ',')} €',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await vm.usePreviousDayClosingBalance();
                                      // Plus besoin d'appeler setState() car le ViewModel notifiera déjà via notifyListeners()
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                    ),
                                    child: const Text(
                                      'Utiliser le fond de la veille',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    _buildManualFieldContainer(
                      'Fond de caisse fermeture',
                      vm.fondFermetureController,
                      (value) async {
                        // Utiliser une mise à jour asynchrone pour éviter les blocages UI
                        await vm.updateManualField('fond_fermeture', value);
                      },
                      Icons.account_balance_wallet_outlined,
                      'Obligatoire',
                      readOnly: _isDateInPast(),
                    ),
                    const SizedBox(height: 8),
                    _buildManualFieldContainer(
                      'Montant déposé au coffre',
                      vm.montantCoffreController,
                      (value) async {
                        // Utiliser une mise à jour asynchrone pour éviter les blocages UI
                        await vm.updateManualField('montant_coffre', value);
                      },
                      Icons.lock,
                      'Obligatoire',
                      readOnly: _isDateInPast(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
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
    );
  }

  // Helper pour vérifier si la date est passée
  bool _isDateInPast() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_viewModel.selectedDate.year, _viewModel.selectedDate.month, _viewModel.selectedDate.day);
    return selectedDay.isBefore(today);
  }

  Widget _buildManualFieldContainer(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
    IconData icon,
    String subtitle, {
    bool readOnly = false,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withAlpha((255 * 0.7).round()),
                  ),
                ),
                if (helperText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      helperText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              readOnly: readOnly,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                suffixText: '€',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
                fillColor:
                    readOnly
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : null,
                filled: readOnly,
              ),
              style:
                  readOnly
                      ? TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      )
                      : null,
              onChanged:
                  readOnly
                      ? null
                      : (value) {
                        // Appeler la fonction de modification immédiatement sans attendre
                        // que la base de données soit mise à jour
                        onChanged(value);
                      },
              // Ajout de onFieldSubmitted pour gérer l'appui sur la touche Enter
              onFieldSubmitted:
                  readOnly
                      ? null
                      : (value) {
                        // Appeler la même fonction que pour onChanged
                        onChanged(value);
                        // Fermer le clavier après validation
                        FocusScope.of(context).unfocus();
                      },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection(DailyStatistics statistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Méthodes de paiement', Icons.payment_rounded),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withAlpha((255 * 0.2).round()),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Ajout du graphique camembert pour les méthodes de paiement
                if (statistics.total > 0)
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: _buildPaymentMethodsPieChart(statistics),
                  ),
                const SizedBox(height: 16),
                _buildStatsContainer(
                  'Bancontact',
                  statistics.totalBancontact,
                  Icons.credit_card,
                ),
                const SizedBox(height: 8),
                _buildStatsContainer(
                  'Espèces',
                  statistics.totalCash,
                  Icons.money,
                ),
                const SizedBox(height: 8),
                _buildStatsContainer(
                  'Virement',
                  statistics.totalVirement,
                  Icons.account_balance,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Total',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${statistics.total.toStringAsFixed(2).replaceAll('.', ',')} €',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Nouvelle méthode pour le graphique camembert des méthodes de paiement
  Widget _buildPaymentMethodsPieChart(DailyStatistics statistics) {
    final double total = statistics.total;
    if (total <= 0) {
      return const SizedBox(
        height: 20,
        child: Center(child: Text('Aucune donnée')),
      );
    }

    // Définir les couleurs pour chaque méthode de paiement
    final cardColor = Theme.of(context).colorScheme.primary;
    final cashColor = Theme.of(context).colorScheme.secondary;
    final transferColor = Theme.of(context).colorScheme.tertiary;

    // Calculer les pourcentages
    final cardPercentage = statistics.totalBancontact / total;
    final cashPercentage = statistics.totalCash / total;
    final transferPercentage = statistics.totalVirement / total;

    // Vérifier s'il y a des données pour chaque méthode
    final hasBancontact = statistics.totalBancontact > 0;
    final hasCash = statistics.totalCash > 0;
    final hasVirement = statistics.totalVirement > 0;

    // Créer les sections pour le graphique
    final List<PieChartSectionData> sections = [];

    if (hasBancontact) {
      sections.add(
        PieChartSectionData(
          color: cardColor,
          value: statistics.totalBancontact,
          title: '${(cardPercentage * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (hasCash) {
      sections.add(
        PieChartSectionData(
          color: cashColor,
          value: statistics.totalCash,
          title: '${(cashPercentage * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (hasVirement) {
      sections.add(
        PieChartSectionData(
          color: transferColor,
          value: statistics.totalVirement,
          title: '${(transferPercentage * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return SizedBox(
      height: 200, // Ensure this container fits within the parent's constraints
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child:
                      sections.isEmpty
                          ? Center(
                            child: Text(
                              'Aucune donnée',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                          : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: sections,
                            ),
                          ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasBancontact)
                        _buildLegendItem('Bancontact', cardColor),
                      if (hasBancontact && (hasCash || hasVirement))
                        const SizedBox(height: 8),
                      if (hasCash) _buildLegendItem('Espèces', cashColor),
                      if (hasCash && hasVirement) const SizedBox(height: 8),
                      if (hasVirement)
                        _buildLegendItem('Virement', transferColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire un élément de légende
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCategoriesSection(DailyStatistics statistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Ventes par catégorie', Icons.category_rounded),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withAlpha((255 * 0.2).round()),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Ajout du graphique camembert pour les catégories
                if (statistics.totalParCategorie > 0)
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: _buildCategoriesPieChart(statistics),
                  ),
                const SizedBox(height: 16),
                _buildStatsContainer(
                  'Boissons',
                  statistics.totalBoissons,
                  Icons.local_drink,
                ),
                const SizedBox(height: 8),
                _buildStatsContainer(
                  'Nourritures',
                  statistics.totalNourritures,
                  Icons.restaurant,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Total par catégorie',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${statistics.totalParCategorie.toStringAsFixed(2).replaceAll('.', ',')} €',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Méthode pour le graphique camembert des catégories
  Widget _buildCategoriesPieChart(DailyStatistics statistics) {
    if (statistics.totalParCategorie <= 0) {
      return const SizedBox(
        height: 20,
        child: Center(child: Text('Aucune donnée')),
      );
    }

    // Récupérer les données des catégories depuis les statistiques
    final categoriesData = <String, double>{};

    // Utiliser categorieDetails si disponible, sinon utiliser les totaux par défaut
    if (statistics.categorieDetails.isNotEmpty) {
      // Agréger les données par catégorie depuis categorieDetails
      for (var category in statistics.categorieDetails) {
        if (category.total > 0) {
          categoriesData[category.categoryDisplayName] = category.total;
        }
      }
    } else {
      // Utiliser les totaux par défaut
      if (statistics.totalBoissons > 0) {
        categoriesData['Boissons'] = statistics.totalBoissons;
      }
      if (statistics.totalNourritures > 0) {
        categoriesData['Nourritures'] = statistics.totalNourritures;
      }
    }

    // Si aucune catégorie n'a de données, afficher un message
    if (categoriesData.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Aucune donnée par catégorie',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Définir une liste de couleurs pour les catégories
    final List<Color> categoryColors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.amber,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    // Générer les sections du graphique
    final List<PieChartSectionData> sections = [];
    final List<Widget> legendItems = [];

    int colorIndex = 0;
    for (var entry in categoriesData.entries) {
      final category = entry.key;
      final value = entry.value;

      // Ne pas inclure les catégories avec une valeur de 0
      if (value <= 0) continue;

      final percentage = value / statistics.totalParCategorie;
      final color = categoryColors[colorIndex % categoryColors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '${(percentage * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

      legendItems.add(_buildLegendItem(category, color));
      if (colorIndex < categoriesData.entries.length - 1) {
        legendItems.add(const SizedBox(height: 4));
      }

      colorIndex++;
    }

    return SizedBox(
      height: 200, // Fixed height for the outer container
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventes par catégorie',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child:
                      sections.isEmpty
                          ? Center(
                            child: Text(
                              'Aucune donnée',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                          : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: sections,
                            ),
                          ),
                ),
                if (sections.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: legendItems,
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

  Widget _buildSummarySection(StatisticsViewModel viewModel) {
    // S'assurer que les statistiques courantes sont disponibles
    final statistics = viewModel.currentStatistics;
    if (statistics == null) return const SizedBox.shrink();

    // Calculer l'écart de caisse avec les valeurs les plus récentes
    final double theoricalCashAmount = viewModel.getTheoricalCashAmount();
    final double totalCashMovements = viewModel.getTotalCashMovements();

    // Calcul de l'écart de caisse en tenant compte des mouvements de caisse
    final double cashDifference =
        statistics.fondCaisseFermeture - (theoricalCashAmount + totalCashMovements);
    final bool hasCashDiscrepancy =
        cashDifference.abs() > 0.01; // Seuil de tolérance pour les arrondis

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Résumé de caisse',
          Icons.account_balance_wallet_rounded,
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withAlpha((255 * 0.2).round()),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatsContainer(
                  'Fond ouverture',
                  statistics.fondCaisseOuverture,
                  Icons.start,
                ),
                const SizedBox(height: 8),
                _buildStatsContainer(
                  'Fond fermeture',
                  statistics.fondCaisseFermeture,
                  Icons.stop,
                  valueColor:
                      hasCashDiscrepancy
                          ? (cashDifference > 0 ? Colors.green : Colors.red)
                          : null,
                ),
                const SizedBox(height: 8),
                _buildStatsContainer(
                  'Espèces théoriques en caisse',
                  theoricalCashAmount + totalCashMovements,
                  Icons.calculate,
                ),
                const SizedBox(height: 8),
                _buildStatsContainer(
                  'Total Bancontact',
                  statistics.totalBancontact,
                  Icons.credit_card,
                ),
                const SizedBox(height: 8),
                _buildStatsContainer(
                  'Total cash',
                  statistics.totalCash,
                  Icons.payments,
                ),
                const SizedBox(height: 8),
                _buildStatsContainer(
                  'Dépôt au coffre',
                  statistics.montantCoffre,
                  Icons.lock,
                ),

                // Section mouvements de caisse
                const SizedBox(height: 16),
                _buildCashMovementsSection(viewModel),

                // N'afficher l'écart de caisse que si le fond d'ouverture n'est pas à 0
                if (statistics.fondCaisseOuverture > 0) ...[
                  // Ajout de l'écart de caisse
                  if (hasCashDiscrepancy) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color:
                            cashDifference > 0
                                ? Colors.green.withAlpha((255 * 0.1).round())
                                : Colors.red.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            cashDifference > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color:
                                cashDifference > 0 ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cashDifference > 0
                                      ? 'Excédent de caisse'
                                      : 'Déficit de caisse',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        cashDifference > 0
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Écart: ${cashDifference.abs().toStringAsFixed(2).replaceAll('.', ',')} €',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cashDifference > 0
                                      ? "Il y a plus d'argent en caisse que prévu."
                                      : "Il manque de l'argent en caisse.",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsContainer(
    String label,
    double value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            // Formatage spécial pour les valeurs positives/négatives (signe plus visible)
            value < 0
                ? '-${value.abs().toStringAsFixed(2).replaceAll('.', ',')} €'
                : '${value.toStringAsFixed(2).replaceAll('.', ',')} €',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Graphique d'évolution des ventes
  Widget _buildSalesEvolutionChart(StatisticsViewModel viewModel) {
    // Pour la vue année, utiliser les statistiques agrégées par mois
    final statistics =
        viewModel.periodType == PeriodType.year
            ? viewModel.monthlyAggregatedStatistics
            : viewModel.periodStatistics;

    if (statistics.isEmpty) {
      return const SizedBox.shrink();
    }

    // Formatage des dates selon la période
    String formatDate(DateTime date) {
      switch (viewModel.periodType) {
        case PeriodType.day:
          return DateFormat('dd/MM').format(date);
        case PeriodType.week:
          return DateFormat('E', 'fr_FR').format(date); // Jour de la semaine en français
        case PeriodType.month:
          return DateFormat('dd/MM', 'fr_FR').format(date); // Jour du mois
        case PeriodType.year:
          return DateFormat('MMM', 'fr_FR').format(date); // Mois de l'année en français
      }
    }

    // Préparation des données
    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    // Limiter et optimiser le nombre de barres pour éviter la surcharge
    final optimalDataPoints = 20;
    final step =
        statistics.length > optimalDataPoints
            ? (statistics.length / optimalDataPoints).ceil()
            : 1;

    // Calculer la largeur optimale des barres en fonction du nombre affiché
    final displayedBars = (statistics.length / step).ceil();
    final barWidth =
        displayedBars > 15 ? 8.0 : (displayedBars > 10 ? 10.0 : 12.0);

    for (int i = 0; i < statistics.length; i += step) {
      final stat = statistics[i];
      final total = stat.total;
      maxY = total > maxY ? total : maxY;

      barGroups.add(
        BarChartGroupData(
          x: i ~/ step,
          barRods: [
            BarChartRodData(
              toY: total,
              color: Theme.of(context).colorScheme.primary,
              width: barWidth,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    // Calculer une valeur maxY arrondie pour l'échelle
    maxY = ((maxY * 1.1) / 100).ceil() * 100;
    if (maxY < 100) maxY = 100;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outline.withAlpha((255 * 0.2).round()),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Évolution des ventes', Icons.trending_up),
              const SizedBox(height: 8),
              Container(
                height: 220,
                padding: const EdgeInsets.only(top: 16, right: 8),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: maxY,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey.shade800,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final index = group.x * step;
                          if (index >= statistics.length) return null;
                          return BarTooltipItem(
                            '${formatDate(statistics[index].date)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '${statistics[index].total.toStringAsFixed(2).replaceAll('.', ',')} €',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                '${value.toInt()} €',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                          interval: maxY / 5,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = (value.toInt() * step);
                            if (index >= statistics.length) {
                              return const SizedBox.shrink();
                            }

                            // Limiter le nombre d'étiquettes affichées en fonction du nombre de barres
                            int skipFactor =
                                displayedBars > 15
                                    ? 3
                                    : (displayedBars > 10 ? 2 : 1);
                            if (value.toInt() % skipFactor != 0) {
                              return const SizedBox.shrink();
                            }

                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                formatDate(statistics[index].date),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      horizontalInterval: maxY / 5,
                      getDrawingHorizontalLine:
                          (value) => FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          ),
                      getDrawingVerticalLine:
                          (_) => FlLine(color: Colors.transparent),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _viewModel.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      _viewModel.changeDate(date);
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Méthode améliorée pour l'exportation avec indicateur de progression
  Future<void> _exportStatistics(BuildContext context) async {
    // Vérifier si l'utilisateur est admin avant de permettre l'export
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isAdmin = userProvider.isAdmin;

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous n\'avez pas les droits pour exporter les statistiques',
          ),
        ),
      );
      return;
    }

    // Utiliser l'instance locale plutôt que le Provider
    final statistics =
        _viewModel.periodType == PeriodType.day
            ? _viewModel.currentStatistics
            : _viewModel.periodAggregateStatistics;

    if (statistics == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucune donnée à exporter')));
      return;
    }

    // Afficher un indicateur de progression
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withAlpha((255 * 0.2).round()),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Utilisation d'un effet de pulsation pour l'indicateur
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer
                          .withAlpha((255 * 0.3).round()),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Génération du PDF en cours...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Veuillez patienter pendant la préparation de votre document',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final pdfExportService = PdfExportService();
      final pdfBytes = await pdfExportService.generateStatisticsReport(
        statistics: statistics,
        periodType: _viewModel.periodType,
        startDate: _viewModel.startDate,
        endDate: _viewModel.endDate,
        periodStatistics: _viewModel.periodStatistics,
        cashMovements: _viewModel.cashMovements,
      );

      // Fermer le dialogue de progression
      Navigator.of(context, rootNavigator: true).pop();

      // Format du nom de fichier: statistiques_jj_mm_aaaa.pdf
      final fileName =
          'statistiques_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';

      // Montrer un dialogue de succès avant le partage
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withAlpha((255 * 0.2).round()),
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            title: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer
                        .withAlpha((255 * 0.5).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Exportation réussie',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Le PDF a été généré avec succès.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withAlpha((255 * 0.4).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withAlpha((255 * 0.2).round()),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 22,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nom du fichier',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fileName,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Que souhaitez-vous faire?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    label: const Text('Fermer'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      pdfExportService.sharePdf(pdfBytes, fileName);
                    },
                    label: const Text('Partager'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.preview_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Printing.layoutPdf(
                        onLayout: (PdfPageFormat format) async => pdfBytes,
                        name: fileName,
                      );
                    },
                    label: const Text('Aperçu'),
                  ),
                ],
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          );
        },
      );
    } catch (e) {
      // Fermer le dialogue de progression en cas d'erreur
      Navigator.of(context, rootNavigator: true).pop();

      // Afficher un dialogue d'erreur plus détaillé
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.error.withAlpha((255 * 0.2).round()),
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            title: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withAlpha((255 * 0.5).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Échec de l\'exportation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Une erreur est survenue lors de la génération du PDF.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withAlpha((255 * 0.3).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withAlpha((255 * 0.4).round()),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détails de l\'erreur',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    label: const Text('Fermer'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _exportStatistics(context); // Réessayer l'export
                    },
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          );
        },
      );
    }
  }

  // Widget pour le chargement des données
  Widget _buildLoadingWidget({
    String message = 'Chargement des statistiques...',
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget pour afficher les erreurs
  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Une erreur est survenue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildCashMovementsSection(StatisticsViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec bouton d'ajout
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mouvements de caisse',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: () {
                CashMovementDialog.show(
                  context,
                  onSubmit: (movement) {
                    viewModel.addCashMovement(movement);
                  },
                );
              },
              icon: const Icon(Icons.add),
              tooltip: 'Ajouter un mouvement',
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Total des mouvements
        _buildStatsContainer(
          'Total mouvements',
          viewModel.getTotalCashMovements(),
          Icons.compare_arrows,
          valueColor:
              viewModel.getTotalCashMovements() == 0
                  ? null
                  : viewModel.getTotalCashMovements() > 0
                  ? Colors.green
                  : Colors.red,
        ),

        const SizedBox(height: 8),

        // Liste des mouvements
        if (viewModel.isLoadingMovements)
          const Center(child: CircularProgressIndicator())
        else if (viewModel.cashMovements.isEmpty)
          const SizedBox.shrink()
        else
          ...viewModel.cashMovements.map(
            (movement) => _buildCashMovementItem(movement, viewModel),
          ),
      ],
    );
  }

  Widget _buildCashMovementItem(
    CashMovement movement,
    StatisticsViewModel viewModel,
  ) {
    final isEntry = movement.type == CashMovementType.entry;
    final color = isEntry ? Colors.green : Colors.red;
    final icon = isEntry ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outline.withAlpha((255 * 0.2).round()),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha((255 * 0.1).round()),
          child: Icon(icon, color: color, size: 16),
        ),
        title: Text(
          movement.justification,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isEntry ? '+' : '-'}${movement.amount.toStringAsFixed(2).replaceAll('.', ',')} €',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            if (movement.details != null) ...[
              const SizedBox(height: 4),
              Text(
                movement.details!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            Text(
              'Créé le ${DateFormat('dd/MM/yyyy à HH:mm').format(movement.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Supprimer le mouvement'),
                    content: const Text(
                      'Êtes-vous sûr de vouloir supprimer ce mouvement de caisse ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          viewModel.deleteCashMovement(movement.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
            );
          },
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Supprimer',
        ),
      ),
    );
  }
}
