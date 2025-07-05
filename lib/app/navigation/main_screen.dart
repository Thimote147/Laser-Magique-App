import 'package:flutter/material.dart';
import '../../features/booking/booking.dart';
import '../../shared/shared.dart';
import '../../features/inventory/inventory.dart';
import '../../features/settings/settings.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  TabController? _tabController;

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
    _tabController = TabController(length: _screens.length, vsync: this);
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) {
        _onItemTapped(_tabController!.index);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController?.dispose();
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
      bottomNavigationBar:
          _tabController == null
              ? const SizedBox.shrink()
              : Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDark
                              ? Colors.black.withAlpha((255 * 0.3).round())
                              : Colors.black.withAlpha((255 * 0.05).round()),
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
                            ? colorScheme.surfaceContainerHighest.withAlpha(
                              (255 * 0.3).round(),
                            )
                            : colorScheme.surfaceContainerHighest.withAlpha(
                              (255 * 0.3).round(),
                            ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.primary, width: 1),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    tabs: [
                      Tab(
                        icon: Icon(Icons.calendar_today_outlined, size: 20),
                        text: 'Réservations',
                      ),
                      Tab(
                        icon: Icon(Icons.bar_chart_outlined, size: 20),
                        text: 'Statistiques',
                      ),
                      Tab(
                        icon: Icon(Icons.inventory_outlined, size: 20),
                        text: 'Stock',
                      ),
                      Tab(
                        icon: Icon(Icons.settings_outlined, size: 20),
                        text: 'Paramètres',
                      ),
                    ],
                    onTap: (index) {
                      _onItemTapped(index);
                    },
                  ),
                ),
              ),
    );
  }
}
