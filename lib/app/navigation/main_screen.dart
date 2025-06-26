import 'package:flutter/material.dart';
import '../../features/booking/booking.dart';
import '../../shared/shared.dart';
import '../../features/inventory/inventory.dart';
import '../../features/settings/settings.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatisticsScreen(),
    const StockScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
        _controller.reset();
        _controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FadeTransition(
        opacity: _animation,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color:
                isDark
                    ? colorScheme.surfaceVariant.withOpacity(0.3)
                    : colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.calendar_today_outlined,
                selectedIcon: Icons.calendar_today,
                label: 'Réservations',
                index: 0,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: 'Statistiques',
                index: 1,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.inventory_outlined,
                selectedIcon: Icons.inventory_rounded,
                label: 'Stock',
                index: 2,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Paramètres',
                index: 3,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? (isDark
                          ? colorScheme.primaryContainer.withOpacity(0.3)
                          : colorScheme.primaryContainer)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border:
                  isSelected
                      ? Border.all(
                        color: colorScheme.primary.withOpacity(
                          isDark ? 0.5 : 1,
                        ),
                        width: 1,
                      )
                      : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 20,
                  color:
                      isSelected
                          ? colorScheme.primary
                          : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected
                            ? colorScheme.primary
                            : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
