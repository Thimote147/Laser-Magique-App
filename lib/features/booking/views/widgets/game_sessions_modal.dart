import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/models/game_session_model.dart';
import '../../../../shared/repositories/game_session_repository.dart';
import '../../../../shared/utils/price_utils.dart';
import '../../../../shared/widgets/custom_dialog.dart';
import '../../models/booking_model.dart';

String formatPrice(double price) {
  return '${price.toStringAsFixed(2)} €';
}

class GameSessionsModal extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onSessionsUpdated;

  const GameSessionsModal({
    super.key,
    required this.booking,
    this.onSessionsUpdated,
  });

  @override
  State<GameSessionsModal> createState() => _GameSessionsModalState();
}

class _GameSessionsModalState extends State<GameSessionsModal>
    with TickerProviderStateMixin {
  final GameSessionRepository _gameSessionRepository = GameSessionRepository();
  List<GameSession> _gameSessions = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _loadGameSessions();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGameSessions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final sessions = await _gameSessionRepository.getGameSessionsByBookingId(widget.booking.id);
      
      setState(() {
        _gameSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateParticipatingPersons(GameSession session, int newParticipants) async {
    try {
      final adjustedPrice = calculateTotalPrice(widget.booking.formula.price, 1, newParticipants);
      
      await _gameSessionRepository.updateParticipatingPersons(
        session.id,
        newParticipants,
        adjustedPrice,
      );
      
      await _loadGameSessions();
      widget.onSessionsUpdated?.call();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomSuccessDialog(
            title: 'Mise à jour réussie',
            content: 'Partie ${session.gameNumber} mise à jour: $newParticipants participants',
            autoClose: true,
            autoCloseDuration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(
            title: 'Erreur',
            content: 'Erreur: $e',
          ),
        );
      }
    }
  }


  void _showEditParticipantsDialog(GameSession session) {
    final TextEditingController controller = TextEditingController(
      text: session.participatingPersons.toString(),
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête compact avec icône et titre
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 24,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modifier les participants',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Partie ${session.gameNumber}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Info compacte
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prévu: ${widget.booking.numberOfPersons}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${widget.booking.formula.price.toStringAsFixed(2)} €/pers.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Champ de saisie compact
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                decoration: InputDecoration(
                  labelText: 'Nombre effectif',
                  hintText: '${session.participatingPersons}',
                  prefixIcon: Icon(
                    Icons.people,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Actions compactes
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final newParticipants = int.tryParse(controller.text) ?? 0;
                        if (newParticipants > 0) {
                          Navigator.pop(context);
                          _updateParticipatingPersons(session, newParticipants);
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => CustomErrorDialog(
                              title: 'Nombre invalide',
                              content: 'Le nombre de participants doit être au minimum 1',
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Confirmer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // En-tête
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_esports,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Gestion des parties',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 1),
                    
                    // Contenu
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? _buildErrorState()
                              : _buildGameSessionsList(scrollController),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Erreur lors du chargement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadGameSessions,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSessionsList(ScrollController scrollController) {
    final totalAdjustedPrice = _gameSessions.fold<double>(
      0.0,
      (sum, session) => sum + session.adjustedPrice,
    );

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé de la réservation
          _buildSummaryCard(totalAdjustedPrice),
          
          const SizedBox(height: 16),
          
          // En-tête des parties
          Row(
            children: [
              Icon(
                Icons.list_alt,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Parties (${_gameSessions.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Liste des parties
          ...List.generate(_gameSessions.length, (index) {
            final session = _gameSessions[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == _gameSessions.length - 1 ? 0 : 12),
              child: _buildGameSessionCard(session),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalAdjustedPrice) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Résumé de la réservation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Participants prévus:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${widget.booking.numberOfPersons}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Parties prévues:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${widget.booking.numberOfGames}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prix standard:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formatPrice(widget.booking.formulaPrice),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prix ajusté:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formatPrice(totalAdjustedPrice),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: totalAdjustedPrice != widget.booking.formulaPrice
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                  if (totalAdjustedPrice != widget.booking.formulaPrice) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: totalAdjustedPrice > widget.booking.formulaPrice
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Différence:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: totalAdjustedPrice > widget.booking.formulaPrice
                                  ? Theme.of(context).colorScheme.onErrorContainer
                                  : Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${totalAdjustedPrice > widget.booking.formulaPrice ? '+' : ''}${formatPrice(totalAdjustedPrice - widget.booking.formulaPrice)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: totalAdjustedPrice > widget.booking.formulaPrice
                                  ? Theme.of(context).colorScheme.onErrorContainer
                                  : Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSessionCard(GameSession session) {
    final isReduced = session.participatingPersons < widget.booking.numberOfPersons;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.games,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Partie ${session.gameNumber}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Informations de la partie dans un container coloré
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Participants',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${session.participatingPersons}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isReduced) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${widget.booking.numberOfPersons - session.participatingPersons}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: VerticalDivider(
                      width: 32,
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prix',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatPrice(session.adjustedPrice),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Action de modification
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showEditParticipantsDialog(session),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Modifier le nombre de participants'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}