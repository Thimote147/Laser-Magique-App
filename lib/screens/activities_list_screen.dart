import 'package:flutter/cupertino.dart';
import '../main.dart';
import '../models/activity.dart';

class ActivitiesListScreen extends StatefulWidget {
  const ActivitiesListScreen({super.key});

  @override
  ActivitiesListScreenState createState() => ActivitiesListScreenState();
}

class ActivitiesListScreenState extends State<ActivitiesListScreen> {
  List<Activity> _activities = [];
  bool _isLoading = true;
  Activity? _selectedActivity;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Using the get_activities RPC function
      final response = await supabase.rpc('get_activities');

      final activities =
          (response as List)
              .map((activity) => Activity.fromJson(activity))
              .toList();

      setState(() {
        _activities = activities;
        _isLoading = false;
        // Select the first activity by default if available
        if (activities.isNotEmpty) {
          _selectedActivity = activities.first;
        }
      });
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Sélectionner une activité'),
        previousPageTitle: 'Retour',
      ),
      child: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _activities.isEmpty
                ? _buildEmptyState()
                : _buildActivitySelector(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 50,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune activité disponible',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: _fetchActivities,
            child: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySelector() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez une activité:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showActivityPicker(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedActivity?.name ?? 'Sélectionner une activité',
                      style: const TextStyle(
                        color: CupertinoColors.black,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_down,
                    color: CupertinoColors.systemGrey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedActivity != null)
            _buildActivityDetails(_selectedActivity!),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed:
                  _selectedActivity != null
                      ? () => Navigator.pop(context, _selectedActivity!.id)
                      : null,
              child: const Text('Sélectionner'),
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Annuler'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Confirmer'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedActivity = _activities[index];
                    });
                  },
                  children:
                      _activities
                          .map((activity) => Center(child: Text(activity.name)))
                          .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityDetails(Activity activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activity.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorForActivityType(
                    activity.type,
                  ).withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getActivityTypeLabel(activity.type),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getColorForActivityType(activity.type),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            CupertinoIcons.person_2_fill,
            'Joueurs: ${activity.minPlayer} - ${activity.maxPlayer} personnes',
          ),
          _buildDetailRow(
            CupertinoIcons.clock_fill,
            'Durée: ${activity.duration} minutes',
          ),
          _buildDetailRow(
            CupertinoIcons.money_euro_circle_fill,
            'Prix: €${activity.firstPrice.toStringAsFixed(2)} - €${activity.thirdPrice.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: CupertinoColors.systemGrey),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: CupertinoColors.black),
          ),
        ],
      ),
    );
  }

  Color _getColorForActivityType(String type) {
    switch (type.toLowerCase()) {
      case 'standard':
        return CupertinoColors.activeBlue;
      case 'vip':
        return CupertinoColors.systemPurple;
      case 'group':
        return CupertinoColors.activeGreen;
      case 'private':
        return CupertinoColors.activeOrange;
      case 'customized':
        return CupertinoColors.systemPink;
      default:
        return CupertinoColors.activeBlue;
    }
  }

  String _getActivityTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'standard':
        return 'Standard';
      case 'vip':
        return 'VIP';
      case 'group':
        return 'Groupe';
      case 'private':
        return 'Privé';
      case 'customized':
        return 'Personnalisé';
      default:
        return type.toUpperCase();
    }
  }
}
