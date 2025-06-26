import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../profile/profile.dart';
import '../../../work_hours/work_hours.dart';
import 'settings_profile_stat.dart';

class SettingsProfilePreview extends StatelessWidget {
  const SettingsProfilePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<EmployeeProfileViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isDark ? 1 : 2,
      shadowColor: colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withOpacity(0.1),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          profileVM.initials,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileVM.fullName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (profileVM.role == UserRole.admin
                                      ? colorScheme.error
                                      : colorScheme.primary)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (profileVM.role == UserRole.admin
                                        ? colorScheme.error
                                        : colorScheme.primary)
                                    .withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              profileVM.roleString,
                              style: TextStyle(
                                color: profileVM.role == UserRole.admin
                                    ? colorScheme.error
                                    : colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WorkHoursScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SettingsProfileStat(
                            label: 'Taux horaire',
                            value: '${profileVM.hourlyRate.toStringAsFixed(2)}€',
                            icon: Icons.euro_rounded,
                          ),
                          VerticalDivider(
                            thickness: 1,
                            width: 1,
                            indent: 8,
                            endIndent: 8,
                            color: colorScheme.outlineVariant.withOpacity(0.2),
                          ),
                          SettingsProfileStat(
                            label: 'Heures travaillées',
                            value: _formatHoursToHourMinutes(
                              _calculateTotalHours(profileVM),
                            ),
                            icon: Icons.access_time_rounded,
                          ),
                          VerticalDivider(
                            thickness: 1,
                            width: 1,
                            indent: 8,
                            endIndent: 8,
                            color: colorScheme.outlineVariant.withOpacity(0.2),
                          ),
                          SettingsProfileStat(
                            label: 'Revenus du mois',
                            value: '${profileVM.getCurrentMonthEarnings().toStringAsFixed(2)}€',
                            icon: Icons.payments_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalHours(EmployeeProfileViewModel profileVM) {
    return profileVM.workDays.fold(0, (sum, day) => sum + day.hours);
  }

  String _formatHoursToHourMinutes(double hours) {
    int fullHours = hours.floor();
    int minutes = ((hours - fullHours) * 60).round();

    if (minutes == 0) {
      return '${fullHours}h00';
    } else {
      return minutes < 10 ? '${fullHours}h0$minutes' : '${fullHours}h$minutes';
    }
  }
}