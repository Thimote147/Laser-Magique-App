import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/game_session_model.dart';
import '../../../shared/repositories/game_session_repository.dart';
import '../../../shared/utils/price_utils.dart';
import '../models/booking_model.dart';

String formatPrice(double price) {
  return '${price.toStringAsFixed(2)} €';
}

class GameSessionsScreen extends StatefulWidget {
  final Booking booking;

  const GameSessionsScreen({
    super.key,
    required this.booking,
  });

  @override
  State<GameSessionsScreen> createState() => _GameSessionsScreenState();
}

class _GameSessionsScreenState extends State<GameSessionsScreen> {
  final GameSessionRepository _gameSessionRepository = GameSessionRepository();
  List<GameSession> _gameSessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGameSessions();
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partie ${session.gameNumber} mise à jour: $newParticipants participants'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startGameSession(GameSession session) async {
    try {
      await _gameSessionRepository.startGameSession(session.id);
      await _loadGameSessions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partie ${session.gameNumber} démarrée'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeGameSession(GameSession session) async {
    try {
      await _gameSessionRepository.completeGameSession(session.id);
      await _loadGameSessions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partie ${session.gameNumber} terminée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
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
      builder: (context) => AlertDialog(
        title: Text('Modifier les participants - Partie ${session.gameNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nombre initial: ${widget.booking.numberOfPersons}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Nombre de participants',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final newParticipants = int.tryParse(controller.text) ?? 0;
              if (newParticipants > 0 && newParticipants <= widget.booking.numberOfPersons) {
                Navigator.pop(context);
                _updateParticipatingPersons(session, newParticipants);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nombre invalide (1-${widget.booking.numberOfPersons})'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des parties'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erreur: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadGameSessions,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _buildGameSessionsList(),
    );
  }

  Widget _buildGameSessionsList() {
    final totalAdjustedPrice = _gameSessions.fold<double>(
      0.0,
      (sum, session) => sum + session.adjustedPrice,
    );

    return Column(
      children: [
        // Résumé de la réservation
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Résumé de la réservation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Participants prévus: ${widget.booking.numberOfPersons}'),
                  Text('Parties prévues: ${widget.booking.numberOfGames}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Prix standard: ${formatPrice(widget.booking.formulaPrice)}'),
                  Text('Prix ajusté: ${formatPrice(totalAdjustedPrice)}'),
                ],
              ),
              if (totalAdjustedPrice != widget.booking.formulaPrice)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Différence: ${formatPrice(totalAdjustedPrice - widget.booking.formulaPrice)}',
                    style: TextStyle(
                      color: totalAdjustedPrice > widget.booking.formulaPrice
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Liste des parties
        Expanded(
          child: ListView.builder(
            itemCount: _gameSessions.length,
            itemBuilder: (context, index) {
              final session = _gameSessions[index];
              return _buildGameSessionCard(session);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameSessionCard(GameSession session) {
    final isReduced = session.participatingPersons < widget.booking.numberOfPersons;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Partie ${session.gameNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(session),
              ],
            ),
            const SizedBox(height: 12),
            
            // Informations de la partie
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Participants: ${session.participatingPersons}'),
                    if (isReduced)
                      Text(
                        'Réduit de ${widget.booking.numberOfPersons - session.participatingPersons}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Prix: ${formatPrice(session.adjustedPrice)}'),
                    if (session.startTime != null)
                      Text(
                        'Début: ${session.startTime!.toLocal().toString().substring(11, 16)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!session.isCompleted && session.startTime == null)
                  ElevatedButton.icon(
                    onPressed: () => _showEditParticipantsDialog(session),
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                if (!session.isCompleted && session.startTime == null)
                  ElevatedButton.icon(
                    onPressed: () => _startGameSession(session),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Démarrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                if (session.startTime != null && !session.isCompleted)
                  ElevatedButton.icon(
                    onPressed: () => _completeGameSession(session),
                    icon: const Icon(Icons.check),
                    label: const Text('Terminer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(GameSession session) {
    String text;
    Color color;
    
    if (session.isCompleted) {
      text = 'Terminée';
      color = Colors.green;
    } else if (session.startTime != null) {
      text = 'En cours';
      color = Colors.blue;
    } else {
      text = 'En attente';
      color = Colors.grey;
    }
    
    return Chip(
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
    );
  }
}