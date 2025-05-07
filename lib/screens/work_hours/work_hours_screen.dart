import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:laser_magique_app/models/work_hour.dart';
import 'package:laser_magique_app/services/work_hours_service.dart';
import 'package:laser_magique_app/main.dart'; // Import main.dart to access themeService

class WorkHoursScreen extends StatefulWidget {
  const WorkHoursScreen({super.key});

  @override
  State<WorkHoursScreen> createState() => _WorkHoursScreenState();
}

class _WorkHoursScreenState extends State<WorkHoursScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  List<WorkHour> _workHours = [];
  double _totalAmount = 0;
  String _totalHours = '00:00';
  bool _isAdmin = false; // To track if user has admin role
  bool _showAllUsers = false; // Toggle between personal and all users views
  final Map<String, bool> _expandedUsers = {}; // Track expanded state for each user

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadWorkHours();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // Check if the current user has admin role
  Future<void> _checkAdminStatus() async {
    try {
      final workHoursService = Provider.of<WorkHoursService>(
        context,
        listen: false,
      );
      final isAdmin = await workHoursService.isCurrentUserAdmin();

      setState(() {
        _isAdmin = isAdmin;
      });
    } catch (e) {
      // If there's an error, assume user is not admin
      setState(() {
        _isAdmin = false;
        _showAllUsers = false;
      });
    }
  }

  Future<void> _loadWorkHours() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final workHoursService = Provider.of<WorkHoursService>(
        context,
        listen: false,
      );

      // Decide which method to call based on the view mode
      final List<WorkHour> hours =
          _showAllUsers
              ? await workHoursService.getAllUsersHours(
                _selectedMonth,
                _selectedYear,
              )
              : await workHoursService.getPersonalHours(
                _selectedMonth,
                _selectedYear,
              );

      // Sort work hours by descending date and time
      hours.sort((a, b) {
        // First sort by user name if in admin mode
        if (_showAllUsers) {
          int nameCompare = a.userName.compareTo(b.userName);
          if (nameCompare != 0) {
            return nameCompare;
          }
        }

        // Then compare by date (descending)
        int dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) {
          return dateCompare;
        }

        // If dates are the same, compare by beginning time (descending)
        return b.beginning.compareTo(a.beginning);
      });

      setState(() {
        _workHours = hours;
        _calculateTotals();

        // Initialize all users as collapsed by default
        if (_showAllUsers) {
          final Set<String> uniqueUsers =
              hours
                  .where((h) => h.hourId.isNotEmpty)
                  .map((h) => h.userName)
                  .toSet();

          // Set all users to collapsed (false) state
          for (var user in uniqueUsers) {
            _expandedUsers[user] = false;
          }
        }
      });
    } catch (e) {
      if (mounted) { // Add mounted check before using BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          _createThemedSnackBar(
            'Error loading work hours: ${e.toString()}',
            isError: true,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Toggle between personal and all users views
  void _toggleViewMode() {
    if (!_isAdmin) return; // Only admins can toggle

    setState(() {
      _showAllUsers = !_showAllUsers;
    });

    // Reload work hours with the new view mode
    _loadWorkHours();
  }

  void _calculateTotals() {
    double totalAmount = 0;
    int totalMinutes = 0;

    for (var hour in _workHours) {
      totalAmount += hour.amount;

      // Parse the nbr_hours format (HH:MM or HH:MM:SS)
      final parts = hour.nbrHours.split(':');
      if (parts.length >= 2) {
        totalMinutes += int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    }

    setState(() {
      _totalAmount = totalAmount;

      // Format total minutes back to HH:MM format
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      _totalHours =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _deleteWorkHour(WorkHour workHour) async {
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Confirmation'),
          content: const Text(
            'Voulez-vous vraiment supprimer ces heures de travail ?',
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final workHoursService = Provider.of<WorkHoursService>(
          context,
          listen: false,
        );
        await workHoursService.deleteWorkHour(workHour.hourId);
        _loadWorkHours();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _createThemedSnackBar('Heures de travail supprimées avec succès'),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _createThemedSnackBar(
              'Erreur lors de la suppression: ${e.toString()}',
              isError: true,
            ),
          );
        }
      }
    }
  }

  void _showAddWorkHourDialog() {
    showCupertinoModalPopup(
      context: context,
      // Use Builder to create a fresh context for proper ScaffoldMessenger access
      builder: (BuildContext dialogContext) {
        return SafeArea(
          bottom: false, // Don't add padding at the bottom
          child: Theme(
            // Ensure Material widgets have proper styling
            data: Theme.of(dialogContext).copyWith(
              colorScheme: ColorScheme.light(
                primary: CupertinoTheme.of(context).primaryColor,
              ),
              canvasColor: Colors.transparent,
            ),
            child: const AddWorkHourDialog(),
          ),
        );
      },
    ).then((value) {
      if (value == true) {
        _loadWorkHours();
      }
    });
  }

  void _showEditWorkHourDialog(WorkHour workHour) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext dialogContext) {
        return SafeArea(
          bottom: false,
          child: Theme(
            data: Theme.of(dialogContext).copyWith(
              colorScheme: ColorScheme.light(
                primary: CupertinoTheme.of(context).primaryColor,
              ),
              canvasColor: Colors.transparent,
            ),
            child: EditWorkHourDialog(workHour: workHour),
          ),
        );
      },
    ).then((value) {
      if (value == true) {
        _loadWorkHours();
      }
    });
  }

  void _changeMonth(int change) {
    int newMonth = _selectedMonth + change;
    int newYear = _selectedYear;

    if (newMonth > 12) {
      newMonth = 1;
      newYear += 1;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear -= 1;
    }

    setState(() {
      _selectedMonth = newMonth;
      _selectedYear = newYear;
    });

    _loadWorkHours();
  }

  String _getMonthName(int month) {
    final date = DateTime(2023, month, 1);
    return DateFormat('MMMM', 'fr_FR').format(date);
  }

  // Format time to display hours and minutes only (HH:MM) removing seconds if present
  String _formatTime(String time) {
    // If the time already has the format HH:MM, return it as is
    if (time.length == 5) {
      return time;
    }

    // If the time has the format HH:MM:SS, return only hours and minutes
    final parts = time.split(':');
    if (parts.length == 3) {
      return '${parts[0]}:${parts[1]}';
    }

    // Return the original time if format is unknown
    return time;
  }

  // Format work hours to display hours and minutes only (removing seconds)
  String _formatWorkHours(String workHours) {
    // Check if the string is in the format "HH:MM:SS" or "H:MM:SS"
    final parts = workHours.split(':');
    if (parts.length == 3) {
      // Return only hours and minutes part
      return '${parts[0]}:${parts[1]}';
    }
    // Return original if not in expected format
    return workHours;
  }

  // Create a grouped structure of work hours by user
  Map<String, List<WorkHour>> _groupWorkHoursByUser() {
    Map<String, List<WorkHour>> groupedHours = {};

    for (var hour in _workHours) {
      if (!groupedHours.containsKey(hour.userName)) {
        groupedHours[hour.userName] = [];
      }
      groupedHours[hour.userName]?.add(hour);
    }

    return groupedHours;
  }

  // Calculate total hours and amount for a specific user
  Map<String, dynamic> _calculateUserTotals(List<WorkHour> userHours) {
    int totalMinutes = 0;
    double totalAmount = 0;

    for (var hour in userHours.where((h) => h.hourId.isNotEmpty)) {
      totalAmount += hour.amount;

      final parts = hour.nbrHours.split(':');
      if (parts.length >= 2) {
        totalMinutes += int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final totalHours =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

    return {'hours': totalHours, 'amount': totalAmount};
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors from themeService
    final textColor = themeService.getTextColor();
    final cardColor = themeService.getCardColor();
    final backgroundColor = themeService.getBackgroundColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final separatorColor = themeService.getSeparatorColor();
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    // Use Material for SnackBar support but no need for ScaffoldMessenger now
    return Material(
      color: Colors.transparent, // Make Material transparent
      child: CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        navigationBar: CupertinoNavigationBar(
          padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
          middle: Text(
            'Heures de Travail',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: backgroundColor,
          border: Border(bottom: BorderSide(color: separatorColor, width: 0.5)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only show the toggle button for admin users
              if (_isAdmin)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _toggleViewMode,
                  child: Icon(
                    _showAllUsers
                        ? CupertinoIcons.person_fill
                        : CupertinoIcons.person_2_fill,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showAddWorkHourDialog,
                child: Icon(CupertinoIcons.add, color: primaryColor, size: 28),
              ),
            ],
          ),
          // Give it a globally unique heroTag to prevent conflicts
          heroTag: UniqueKey(),
          transitionBetweenRoutes: false,
        ),
        child: Column(
          children: [
            // Summary card and work hours list
            Expanded(
              child: SafeArea(
                bottom: false, // Don't add padding at the bottom
                child: Column(
                  children: [
                    // Only show Summary card in personal view
                    if (!_showAllUsers)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: separatorColor,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                cardColor,
                                themeService.darkMode
                                    ? CupertinoTheme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.15)
                                    : CupertinoTheme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.07),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Résumé du mois',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_workHours.length} session${_workHours.length > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildSummaryItem(
                                      icon: CupertinoIcons.clock,
                                      title: 'Total des heures',
                                      value: _totalHours,
                                      textColor: textColor,
                                      secondaryTextColor: secondaryTextColor,
                                      primaryColor: primaryColor,
                                    ),
                                    Container(
                                      height: 40,
                                      width: 1,
                                      color: separatorColor.withOpacity(0.5),
                                    ),
                                    _buildSummaryItem(
                                      icon: CupertinoIcons.money_euro,
                                      title: 'Montant total',
                                      value:
                                          '${_totalAmount.toStringAsFixed(2)} €',
                                      textColor: textColor,
                                      secondaryTextColor: secondaryTextColor,
                                      primaryColor: primaryColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Work hours list with pull-to-refresh
                    Expanded(
                      child:
                          _isLoading
                              ? const Center(
                                child: CupertinoActivityIndicator(),
                              )
                              : _workHours.isEmpty
                              ? Center(
                                child: Text(
                                  'Aucune heure de travail ce mois-ci',
                                  style: TextStyle(color: secondaryTextColor),
                                ),
                              )
                              : CustomScrollView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                slivers: [
                                  // Add the pull-to-refresh control
                                  CupertinoSliverRefreshControl(
                                    onRefresh: () async {
                                      // Refresh the work hours data
                                      await _loadWorkHours();
                                      // Show a toast to confirm refresh
                                      if (mounted) {
                                        _showCupertinoToast(
                                          'Heures de travail mises à jour',
                                        );
                                      }
                                    },
                                  ),

                                  // List of work hours by user
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        if (!_showAllUsers || !_isAdmin) {
                                          // Personal view - show individual entries
                                          if (index >= _workHours.length) {
                                            return null;
                                          }

                                          final workHour = _workHours[index];
                                          return _buildWorkHourItem(
                                            workHour,
                                            textColor,
                                            cardColor,
                                            primaryColor,
                                            secondaryTextColor,
                                            separatorColor,
                                          );
                                        } else {
                                          // Admin view - show user summaries with expandable details
                                          Map<String, List<WorkHour>>
                                          groupedHours =
                                              _groupWorkHoursByUser();
                                          List<String> userNames =
                                              groupedHours.keys.toList();

                                          if (index >= userNames.length) {
                                            return null;
                                          }

                                          String userName = userNames[index];
                                          List<WorkHour> userHours =
                                              groupedHours[userName] ?? [];
                                          Map<String, dynamic> totals =
                                              _calculateUserTotals(userHours);

                                          return _buildUserSummaryItem(
                                            userName: userName,
                                            userHours: userHours,
                                            totalHours: totals['hours'],
                                            totalAmount: totals['amount'],
                                            textColor: textColor,
                                            cardColor: cardColor,
                                            primaryColor: primaryColor,
                                            secondaryTextColor:
                                                secondaryTextColor,
                                            separatorColor: separatorColor,
                                          );
                                        }
                                      },
                                      childCount:
                                          _showAllUsers && _isAdmin
                                              ? _groupWorkHoursByUser().length
                                              : _workHours.length,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ],
                ),
              ),
            ),

            // Month selector moved at the bottom
            Container(
              width: double.infinity,
              height: 75,
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  top: BorderSide(color: separatorColor, width: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: separatorColor,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.only(left: 32),
                    minSize: 0, // Remove minimum height constraint
                    child: Icon(
                      CupertinoIcons.chevron_left,
                      color: primaryColor,
                    ),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    '${_getMonthName(_selectedMonth)} $_selectedYear',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.only(right: 32),
                    minSize: 0, // Remove minimum height constraint
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      color: primaryColor,
                    ),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSummaryItem({
    required String userName,
    required List<WorkHour> userHours,
    required String totalHours,
    required double totalAmount,
    required Color textColor,
    required Color cardColor,
    required Color primaryColor,
    required Color secondaryTextColor,
    required Color separatorColor,
  }) {
    // Get expanded state for this user
    final isExpanded = _expandedUsers[userName] ?? false;
    
    // Count the number of work hour entries
    final entryCount = userHours.where((h) => h.hourId.isNotEmpty).length;

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 6, right: 16, bottom: 6), // Reduced vertical padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header card with summary information
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: separatorColor,
                  blurRadius: 2, // Reduced blur
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedUsers[userName] = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Reduced padding
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // User name with icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6), // Reduced padding
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                CupertinoIcons.person_fill,
                                color: Colors.white,
                                size: 16, // Reduced size
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16, // Reduced font size
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Number of sessions badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Smaller padding
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$entryCount session${entryCount != 1 ? "s" : ""}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12, // Smaller font
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Toggle icon
                        Container(
                          padding: const EdgeInsets.all(5), // Reduced padding
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isExpanded
                                ? CupertinoIcons.chevron_up
                                : CupertinoIcons.chevron_down,
                            color: Colors.white,
                            size: 14, // Reduced size
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10), // Reduced spacing

                    // Totals row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Total hours
                        Column(
                          children: [
                            Text(
                              'Total heures',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                            const SizedBox(height: 2), // Reduced spacing
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3, // Reduced padding
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                totalHours,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15, // Reduced font size
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Separator
                        Container(
                          height: 24, // Reduced height
                          width: 1,
                          color: Colors.white.withOpacity(0.3),
                        ),

                        // Total amount
                        Column(
                          children: [
                            Text(
                              'Montant total',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                            const SizedBox(height: 2), // Reduced spacing
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3, // Reduced padding
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${totalAmount.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15, // Reduced font size
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Only show details if expanded
          if (isExpanded)
            Column(
              children:
                  userHours
                      .where(
                        (hour) => hour.hourId.isNotEmpty,
                      ) // Filter out placeholders
                      .map(
                        (workHour) => Padding(
                          padding: const EdgeInsets.only(top: 6), // Reduced spacing
                          child: _buildWorkHourItem(
                            workHour,
                            textColor,
                            cardColor,
                            primaryColor,
                            secondaryTextColor,
                            separatorColor,
                          ),
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkHourItem(
    WorkHour workHour,
    Color textColor,
    Color cardColor,
    Color primaryColor,
    Color secondaryTextColor,
    Color separatorColor,
  ) {
    // If this is a placeholder entry (no hourId)
    if (workHour.hourId.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: separatorColor, width: 1),
        ),
        child: Center(
          child: Text(
            'Aucune heure de travail ce mois-ci',
            style: TextStyle(
              color: secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Regular work hour item
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: separatorColor,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.1), width: 1),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Work hour item content...
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CupertinoIcons.calendar,
                          color: primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat(
                          'EEEE d MMMM',
                          'fr_FR',
                        ).format(workHour.date),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${workHour.amount.toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: secondaryTextColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          CupertinoIcons.clock,
                          color: secondaryTextColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${_formatTime(workHour.beginning)} - ${_formatTime(workHour.ending)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: ' (${_formatWorkHours(workHour.nbrHours)})',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Only show edit and delete buttons in personal view (not in admin view)
                      if (!_showAllUsers) ...[
                        // Edit button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              CupertinoIcons.pencil,
                              color: primaryColor,
                              size: 16,
                            ),
                          ),
                          onPressed: () => _showEditWorkHourDialog(workHour),
                        ),
                        // Delete button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              CupertinoIcons.delete,
                              color:
                                  themeService.darkMode
                                      ? CupertinoColors.systemRed.darkColor
                                      : CupertinoColors.systemRed,
                              size: 16,
                            ),
                          ),
                          onPressed: () => _deleteWorkHour(workHour),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Create a themed SnackBar that respects dark mode
  SnackBar _createThemedSnackBar(String message, {bool isError = false}) {
    final backgroundColor =
        isError
            ? (themeService.darkMode
                ? CupertinoColors.systemRed.darkColor
                : CupertinoColors.systemRed)
            : (themeService.darkMode
                ? CupertinoColors.activeGreen.darkColor
                : CupertinoColors.activeGreen);

    final textColor = CupertinoColors.white;

    return SnackBar(
      backgroundColor: backgroundColor,
      content: Text(message, style: TextStyle(color: textColor)),
    );
  }

  // Show a Cupertino-style toast message that will auto-dismiss
  void _showCupertinoToast(String message, {bool isError = false}) {
    // Show an overlay notification at the top of the screen
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 80, // Position below the navigation bar
            left: 16,
            right: 16,
            child: Material(
              // Using Material just for the elevation
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color:
                  isError
                      ? CupertinoColors.destructiveRed
                      : CupertinoColors.activeGreen,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      isError
                          ? CupertinoIcons.exclamationmark_circle
                          : CupertinoIcons.checkmark_circle,
                      color: CupertinoColors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primaryColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 14, color: secondaryTextColor)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class AddWorkHourDialog extends StatefulWidget {
  const AddWorkHourDialog({super.key});

  @override
  State<AddWorkHourDialog> createState() => _AddWorkHourDialogState();
}

class _AddWorkHourDialogState extends State<AddWorkHourDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(
    hour: TimeOfDay.now().hour + 1,
  );
  bool _isSubmitting = false;

  // Create a GlobalKey for ScaffoldMessenger
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Calculate estimated duration
  String get _estimatedDuration {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    // Handle case where end time is on the next day
    final diffMinutes =
        endMinutes >= startMinutes
            ? endMinutes - startMinutes
            : (24 * 60 - startMinutes) + endMinutes;

    final hours = diffMinutes ~/ 60;
    final minutes = diffMinutes % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (BuildContext context) {
          // Allow any date, including past dates
          DateTime selectedDate = _selectedDate;

          final bgColor =
              themeService.darkMode
                  ? CupertinoColors.systemBackground.darkColor
                  : CupertinoColors.systemBackground;
          final headerColor =
              themeService.darkMode
                  ? CupertinoColors.secondarySystemBackground.darkColor
                  : CupertinoColors.secondarySystemBackground;
          final separatorColor = themeService.getSeparatorColor();
          final textColor = themeService.getTextColor();

          return Container(
            height: 300,
            color: bgColor,
            child: Column(
              children: [
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: headerColor,
                    border: Border(
                      bottom: BorderSide(color: separatorColor, width: 0.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Annuler'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop(selectedDate);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Localizations.override(
                    context: context,
                    locale: const Locale('fr', 'FR'),
                    delegates: [
                      DefaultCupertinoLocalizations.delegate,
                      DefaultMaterialLocalizations.delegate,
                      DefaultWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    child: Builder(
                      builder: (BuildContext context) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            textTheme: Theme.of(context).textTheme.copyWith(
                              bodyMedium: TextStyle(color: textColor),
                            ),
                          ),
                          child: CupertinoDatePicker(
                            initialDateTime: selectedDate,
                            // No minimum date to allow past dates
                            // Set a reasonable maximum date of 1 year in the future
                            maximumDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            mode: CupertinoDatePickerMode.date,
                            dateOrder: DatePickerDateOrder.dmy,
                            onDateTimeChanged: (DateTime newDate) {
                              selectedDate = newDate;
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    } catch (e) {
      // Handle any potential errors with date picker
      _showErrorSnackBar('Erreur lors de la sélection de la date: $e');
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    try {
      final TimeOfDay? picked = await showCupertinoModalPopup<TimeOfDay>(
        context: context,
        builder: (BuildContext context) {
          // Round minutes to the nearest 15-minute interval for better UX
          int initialMinute = (_startTime.minute ~/ 15) * 15;

          DateTime selectedDateTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _startTime.hour,
            initialMinute,
          );

          final bgColor =
              themeService.darkMode
                  ? CupertinoColors.systemBackground.darkColor
                  : CupertinoColors.systemBackground;
          final headerColor =
              themeService.darkMode
                  ? CupertinoColors.secondarySystemBackground.darkColor
                  : CupertinoColors.secondarySystemBackground;
          final separatorColor = themeService.getSeparatorColor();

          return Container(
            height: 300,
            color: bgColor,
            child: Column(
              children: [
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: headerColor,
                    border: Border(
                      bottom: BorderSide(color: separatorColor, width: 0.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Annuler'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop(
                            TimeOfDay(
                              hour: selectedDateTime.hour,
                              minute: selectedDateTime.minute,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Localizations.override(
                    context: context,
                    locale: const Locale('fr', 'FR'),
                    delegates: [
                      DefaultCupertinoLocalizations.delegate,
                      DefaultMaterialLocalizations.delegate,
                      DefaultWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    child: Builder(
                      builder: (BuildContext context) {
                        return CupertinoDatePicker(
                          initialDateTime: selectedDateTime,
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: true,
                          minuteInterval: 15,
                          onDateTimeChanged: (DateTime newDateTime) {
                            selectedDateTime = newDateTime;
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (picked != null && picked != _startTime) {
        setState(() {
          _startTime = picked;
          // If end time is before start time, update it to be 1 hour after start time
          if (_timeOfDayToMinutes(_endTime) < _timeOfDayToMinutes(_startTime)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        });
      }
    } catch (e) {
      // Handle any potential errors with time picker
      _showErrorSnackBar(
        'Erreur lors de la sélection de l\'heure de début: $e',
      );
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    try {
      final TimeOfDay? picked = await showCupertinoModalPopup<TimeOfDay>(
        context: context,
        builder: (BuildContext context) {
          // Round minutes to the nearest 15-minute interval for better UX
          int initialMinute = (_endTime.minute ~/ 15) * 15;

          DateTime selectedDateTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _endTime.hour,
            initialMinute,
          );

          final bgColor =
              themeService.darkMode
                  ? CupertinoColors.systemBackground.darkColor
                  : CupertinoColors.systemBackground;
          final headerColor =
              themeService.darkMode
                  ? CupertinoColors.secondarySystemBackground.darkColor
                  : CupertinoColors.secondarySystemBackground;
          final separatorColor = themeService.getSeparatorColor();

          return Container(
            height: 300,
            color: bgColor,
            child: Column(
              children: [
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: headerColor,
                    border: Border(
                      bottom: BorderSide(color: separatorColor, width: 0.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Annuler'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop(
                            TimeOfDay(
                              hour: selectedDateTime.hour,
                              minute: selectedDateTime.minute,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Localizations.override(
                    context: context,
                    locale: const Locale('fr', 'FR'),
                    delegates: [
                      DefaultCupertinoLocalizations.delegate,
                      DefaultMaterialLocalizations.delegate,
                      DefaultWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    child: Builder(
                      builder: (BuildContext context) {
                        return CupertinoDatePicker(
                          initialDateTime: selectedDateTime,
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: true,
                          minuteInterval: 15,
                          onDateTimeChanged: (DateTime newDateTime) {
                            selectedDateTime = newDateTime;
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (picked != null && picked != _endTime) {
        setState(() {
          _endTime = picked;
        });
      }
    } catch (e) {
      // Handle any potential errors with time picker
      _showErrorSnackBar('Erreur lors de la sélection de l\'heure de fin: $e');
    }
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  // Helper method to show error snackbar in a consistent way
  void _showErrorSnackBar(String message) {
    if (mounted) {
      _showToast(message, isError: true);
    }
  }

  Future<void> _submitForm() async {
    // Check if end time is after start time
    if (_timeOfDayToMinutes(_endTime) <= _timeOfDayToMinutes(_startTime)) {
      _showToast(
        'L\'heure de fin doit être après l\'heure de début',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final workHoursService = Provider.of<WorkHoursService>(
        context,
        listen: false,
      );

      // Create a temporary WorkHour object to send to the API
      // nbr_hours and amount will be calculated by the server according to user's hourly rate
      final workHour = WorkHour(
        hourId: '', // Will be assigned by the server
        date: _selectedDate,
        beginning: _formatTimeOfDay(_startTime),
        ending: _formatTimeOfDay(_endTime),
        nbrHours: '00:00', // Will be calculated by the server
        amount: 0, // Will be calculated by the server based on hourly rate
      );

      await workHoursService.addWorkHour(workHour);

      if (mounted) {
        // Reset loading state to ensure we don't get stuck
        setState(() {
          _isSubmitting = false;
        });

        // Close the dialog immediately with success result
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Erreur: ${e.toString()}', isError: true);
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Show a toast message that will display and auto-dismiss
  void _showToast(String message, {bool isError = false}) {
    // This method uses CupertinoAlertDialog with auto-dismiss instead of SnackBar
    final toastColor =
        isError
            ? (themeService.darkMode
                ? CupertinoColors.systemRed.darkColor
                : CupertinoColors.systemRed)
            : (themeService.darkMode
                ? CupertinoColors.activeGreen.darkColor
                : CupertinoColors.activeGreen);

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Auto-dismiss after 1.5 seconds
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: toastColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError
                      ? CupertinoIcons.exclamationmark_circle
                      : CupertinoIcons.check_mark_circled,
                  color: CupertinoColors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors from themeService
    final textColor = themeService.getTextColor();
    final cardColor = themeService.getCardColor();
    final backgroundColor = themeService.getBackgroundColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final separatorColor = themeService.getSeparatorColor();
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    // Wrap everything in ScaffoldMessenger for SnackBar support
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Material(
        type: MaterialType.transparency,
        child: Form(
          key: _formKey,
          child: Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rest of the UI...
                  // Header
                  Row(
                    children: [
                      Icon(CupertinoIcons.clock, color: primaryColor, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Ajouter des heures',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),

                  // Duration display
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: 14,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Durée estimée: $_estimatedDuration',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Divider(height: 1, color: separatorColor),
                  const SizedBox(height: 16),

                  // Date selector
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      onPressed: () => _selectDate(context),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.calendar,
                              color: primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'EEEE d MMMM yyyy',
                                    'fr_FR',
                                  ).format(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Time range selector
                  Row(
                    children: [
                      // Start time
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: backgroundColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.all(12),
                            onPressed: () => _selectStartTime(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Début',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.time,
                                      size: 18,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimeOfDay(_startTime),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Arrow
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          CupertinoIcons.arrow_right,
                          color: primaryColor,
                        ),
                      ),

                      // End time
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: backgroundColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.all(12),
                            onPressed: () => _selectEndTime(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fin',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.time,
                                      size: 18,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimeOfDay(_endTime),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Buttons side by side
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          borderRadius: BorderRadius.circular(12),
                          color:
                              themeService.darkMode
                                  ? const Color(
                                    0xFF3A3A3C,
                                  ) // Darker background in dark mode for better contrast
                                  : const Color(
                                    0xFFE5E5EA,
                                  ), // Lighter background in light mode
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Save Button
                      Expanded(
                        child: CupertinoButton(
                          color:
                              themeService.darkMode
                                  ? const Color(
                                    0xFF0A84FF,
                                  ) // Brighter blue in dark mode for better visibility
                                  : primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          onPressed: _isSubmitting ? null : _submitForm,
                          child:
                              _isSubmitting
                                  ? const CupertinoActivityIndicator(
                                    color: CupertinoColors.white,
                                  )
                                  : const Text(
                                    'Enregistrer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EditWorkHourDialog extends StatefulWidget {
  final WorkHour workHour;

  const EditWorkHourDialog({super.key, required this.workHour});

  @override
  State<EditWorkHourDialog> createState() => _EditWorkHourDialogState();
}

class _EditWorkHourDialogState extends State<EditWorkHourDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isSubmitting = false;

  // Create a GlobalKey for ScaffoldMessenger
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    // Initialize state with the existing work hour values
    _selectedDate = widget.workHour.date;

    // Parse beginning time (HH:MM or HH:MM:SS format)
    final beginningParts = widget.workHour.beginning.split(':');
    _startTime = TimeOfDay(
      hour: int.parse(beginningParts[0]),
      minute: int.parse(beginningParts[1]),
    );

    // Parse ending time (HH:MM or HH:MM:SS format)
    final endingParts = widget.workHour.ending.split(':');
    _endTime = TimeOfDay(
      hour: int.parse(endingParts[0]),
      minute: int.parse(endingParts[1]),
    );
  }

  // Calculate estimated duration
  String get _estimatedDuration {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    // Handle case where end time is on the next day
    final diffMinutes =
        endMinutes >= startMinutes
            ? endMinutes - startMinutes
            : (24 * 60 - startMinutes) + endMinutes;

    final hours = diffMinutes ~/ 60;
    final minutes = diffMinutes % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (BuildContext context) {
          // Allow any date, including past dates
          DateTime selectedDate = _selectedDate;

          final bgColor =
              themeService.darkMode
                  ? CupertinoColors.systemBackground.darkColor
                  : CupertinoColors.systemBackground;
          final headerColor =
              themeService.darkMode
                  ? CupertinoColors.secondarySystemBackground.darkColor
                  : CupertinoColors.secondarySystemBackground;
          final separatorColor = themeService.getSeparatorColor();
          final textColor = themeService.getTextColor();

          return Container(
            height: 300,
            color: bgColor,
            child: Column(
              children: [
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: headerColor,
                    border: Border(
                      bottom: BorderSide(color: separatorColor, width: 0.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Annuler'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop(selectedDate);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Localizations.override(
                    context: context,
                    locale: const Locale('fr', 'FR'),
                    delegates: [
                      DefaultCupertinoLocalizations.delegate,
                      DefaultMaterialLocalizations.delegate,
                      DefaultWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    child: Builder(
                      builder: (BuildContext context) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            textTheme: Theme.of(context).textTheme.copyWith(
                              bodyMedium: TextStyle(color: textColor),
                            ),
                          ),
                          child: CupertinoDatePicker(
                            initialDateTime: selectedDate,
                            // No minimum date to allow past dates
                            // Set a reasonable maximum date of 1 year in the future
                            maximumDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            mode: CupertinoDatePickerMode.date,
                            dateOrder: DatePickerDateOrder.dmy,
                            onDateTimeChanged: (DateTime newDate) {
                              selectedDate = newDate;
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    } catch (e) {
      // Handle any potential errors with date picker
      _showErrorSnackBar('Erreur lors de la sélection de la date: $e');
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    try {
      final TimeOfDay? picked = await showCupertinoModalPopup<TimeOfDay>(
        context: context,
        builder: (BuildContext context) {
          // Round minutes to the nearest 15-minute interval for better UX
          int initialMinute = (_startTime.minute ~/ 15) * 15;

          DateTime selectedDateTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _startTime.hour,
            initialMinute,
          );

          final bgColor =
              themeService.darkMode
                  ? CupertinoColors.systemBackground.darkColor
                  : CupertinoColors.systemBackground;
          final headerColor =
              themeService.darkMode
                  ? CupertinoColors.secondarySystemBackground.darkColor
                  : CupertinoColors.secondarySystemBackground;
          final separatorColor = themeService.getSeparatorColor();

          return Container(
            height: 300,
            color: bgColor,
            child: Column(
              children: [
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: headerColor,
                    border: Border(
                      bottom: BorderSide(color: separatorColor, width: 0.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Annuler'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop(
                            TimeOfDay(
                              hour: selectedDateTime.hour,
                              minute: selectedDateTime.minute,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Localizations.override(
                    context: context,
                    locale: const Locale('fr', 'FR'),
                    delegates: [
                      DefaultCupertinoLocalizations.delegate,
                      DefaultMaterialLocalizations.delegate,
                      DefaultWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    child: Builder(
                      builder: (BuildContext context) {
                        return CupertinoDatePicker(
                          initialDateTime: selectedDateTime,
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: true,
                          minuteInterval: 15,
                          onDateTimeChanged: (DateTime newDateTime) {
                            selectedDateTime = newDateTime;
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (picked != null && picked != _startTime) {
        setState(() {
          _startTime = picked;
          // If end time is before start time, update it to be 1 hour after start time
          if (_timeOfDayToMinutes(_endTime) < _timeOfDayToMinutes(_startTime)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        });
      }
    } catch (e) {
      // Handle any potential errors with time picker
      _showErrorSnackBar(
        'Erreur lors de la sélection de l\'heure de début: $e',
      );
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    try {
      final TimeOfDay? picked = await showCupertinoModalPopup<TimeOfDay>(
        context: context,
        builder: (BuildContext context) {
          // Round minutes to the nearest 15-minute interval for better UX
          int initialMinute = (_endTime.minute ~/ 15) * 15;

          DateTime selectedDateTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _endTime.hour,
            initialMinute,
          );

          final bgColor =
              themeService.darkMode
                  ? CupertinoColors.systemBackground.darkColor
                  : CupertinoColors.systemBackground;
          final headerColor =
              themeService.darkMode
                  ? CupertinoColors.secondarySystemBackground.darkColor
                  : CupertinoColors.secondarySystemBackground;
          final separatorColor = themeService.getSeparatorColor();

          return Container(
            height: 300,
            color: bgColor,
            child: Column(
              children: [
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: headerColor,
                    border: Border(
                      bottom: BorderSide(color: separatorColor, width: 0.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Annuler'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop(
                            TimeOfDay(
                              hour: selectedDateTime.hour,
                              minute: selectedDateTime.minute,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Localizations.override(
                    context: context,
                    locale: const Locale('fr', 'FR'),
                    delegates: [
                      DefaultCupertinoLocalizations.delegate,
                      DefaultMaterialLocalizations.delegate,
                      DefaultWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    child: Builder(
                      builder: (BuildContext context) {
                        return CupertinoDatePicker(
                          initialDateTime: selectedDateTime,
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: true,
                          minuteInterval: 15,
                          onDateTimeChanged: (DateTime newDateTime) {
                            selectedDateTime = newDateTime;
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (picked != null && picked != _endTime) {
        setState(() {
          _endTime = picked;
        });
      }
    } catch (e) {
      // Handle any potential errors with time picker
      _showErrorSnackBar('Erreur lors de la sélection de l\'heure de fin: $e');
    }
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  // Helper method to show error snackbar in a consistent way
  void _showErrorSnackBar(String message) {
    if (mounted) {
      _showToast(message, isError: true);
    }
  }

  Future<void> _submitForm() async {
    // Check if end time is after start time
    if (_timeOfDayToMinutes(_endTime) <= _timeOfDayToMinutes(_startTime)) {
      _showToast(
        'L\'heure de fin doit être après l\'heure de début',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final workHoursService = Provider.of<WorkHoursService>(
        context,
        listen: false,
      );

      // Create a WorkHour object with updated values but keeping the original ID
      final updatedWorkHour = WorkHour(
        hourId: widget.workHour.hourId,
        date: _selectedDate,
        beginning: _formatTimeOfDay(_startTime),
        ending: _formatTimeOfDay(_endTime),
        nbrHours:
            widget.workHour.nbrHours, // Will be recalculated by the server
        amount: widget.workHour.amount, // Will be recalculated by the server
      );

      await workHoursService.updateWorkHour(updatedWorkHour);

      if (mounted) {
        // Reset loading state to ensure we don't get stuck
        setState(() {
          _isSubmitting = false;
        });

        // Close the dialog immediately with success result
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Erreur: ${e.toString()}', isError: true);
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Show a toast message that will display and auto-dismiss
  void _showToast(String message, {bool isError = false}) {
    final toastColor =
        isError
            ? (themeService.darkMode
                ? CupertinoColors.systemRed.darkColor
                : CupertinoColors.systemRed)
            : (themeService.darkMode
                ? CupertinoColors.activeGreen.darkColor
                : CupertinoColors.activeGreen);

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Auto-dismiss after 1.5 seconds
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: toastColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError
                      ? CupertinoIcons.exclamationmark_circle
                      : CupertinoIcons.check_mark_circled,
                  color: CupertinoColors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors from themeService
    final textColor = themeService.getTextColor();
    final cardColor = themeService.getCardColor();
    final backgroundColor = themeService.getBackgroundColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final separatorColor = themeService.getSeparatorColor();
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    // Wrap everything in ScaffoldMessenger for SnackBar support
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Material(
        type: MaterialType.transparency,
        child: Form(
          key: _formKey,
          child: Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.pencil_circle,
                        color: primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Modifier des heures',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),

                  // Duration display
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: 14,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Durée estimée: $_estimatedDuration',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Divider(height: 1, color: separatorColor),
                  const SizedBox(height: 16),

                  // Date selector
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      onPressed: () => _selectDate(context),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.calendar,
                              color: primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'EEEE d MMMM yyyy',
                                    'fr_FR',
                                  ).format(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Time range selector
                  Row(
                    children: [
                      // Start time
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: backgroundColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.all(12),
                            onPressed: () => _selectStartTime(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Début',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.time,
                                      size: 18,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimeOfDay(_startTime),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Arrow
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          CupertinoIcons.arrow_right,
                          color: primaryColor,
                        ),
                      ),

                      // End time
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: backgroundColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.all(12),
                            onPressed: () => _selectEndTime(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fin',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.time,
                                      size: 18,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimeOfDay(_endTime),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Buttons side by side
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          borderRadius: BorderRadius.circular(12),
                          color:
                              themeService.darkMode
                                  ? const Color(
                                    0xFF3A3A3C,
                                  ) // Darker background in dark mode for better contrast
                                  : const Color(
                                    0xFFE5E5EA,
                                  ), // Lighter background in light mode
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Save Button
                      Expanded(
                        child: CupertinoButton(
                          color:
                              themeService.darkMode
                                  ? const Color(
                                    0xFF0A84FF,
                                  ) // Brighter blue in dark mode for better visibility
                                  : primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          onPressed: _isSubmitting ? null : _submitForm,
                          child:
                              _isSubmitting
                                  ? const CupertinoActivityIndicator(
                                    color: CupertinoColors.white,
                                  )
                                  : const Text(
                                    'Mettre à jour',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
