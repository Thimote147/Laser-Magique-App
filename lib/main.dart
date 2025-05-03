import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/new_booking_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/booking_details_screen.dart';
import 'screens/clients_screen.dart';
import 'utils/app_strings.dart';
import 'models/booking.dart';
import 'pages/booking_details_page.dart'; // Ajout de cette importation

// Global Supabase client instance
late final SupabaseClient supabase;

// Global navigation key to access navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr_FR', null);

  // Load environment variables
  await dotenv.load();

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  supabase = Supabase.instance.client;

  runApp(const LaserMagiqueApp());
}

class LaserMagiqueApp extends StatelessWidget {
  const LaserMagiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      navigatorKey: navigatorKey,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      theme: const CupertinoThemeData(
        primaryColor: Color(0xFF007AFF),
        brightness: Brightness.light,
        barBackgroundColor: CupertinoColors.systemGroupedBackground,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
            fontFamily: '.SF Pro Text',
            inherit: true, // Ensure consistent inherit value
          ),
          navLargeTitleTextStyle: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.black,
            fontFamily: '.SF Pro Display',
            inherit: true, // Ensure consistent inherit value
          ),
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 16,
            color: CupertinoColors.black,
            inherit: true, // Ensure consistent inherit value
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Make this static so it can be accessed from anywhere
  static final MainScreenState _instance = MainScreenState._internal();
  factory MainScreenState() => _instance;
  MainScreenState._internal();

  // Getter to access the PageController
  static PageController get pageController => _instance._pageController;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false, // Don't apply bottom safe area to avoid extra space
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: const [
                  HomePage(),
                  AnalyticsPage(),
                  ClientsScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 8.0),
                child: CupertinoTabBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  backgroundColor: CupertinoColors.systemBackground,
                  border: const Border(
                    top: BorderSide(
                      color: CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                  activeColor: CupertinoTheme.of(context).primaryColor,
                  inactiveColor: CupertinoColors.systemGrey,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(CupertinoIcons.calendar),
                      label: AppStrings.calendar,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(CupertinoIcons.chart_bar_alt_fill),
                      label: AppStrings.analytics,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(CupertinoIcons.person_2_fill),
                      label: AppStrings.clients,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(CupertinoIcons.settings),
                      label: AppStrings.settings,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final color =
        isSelected
            ? CupertinoTheme.of(context).primaryColor
            : CupertinoColors.systemGrey;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: Container(
        width: 80,
        height: 50,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddClientSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();

    return CupertinoActionSheet(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.person_add, size: 28),
          const SizedBox(width: 8),
          Text(
            AppStrings.addNewClient,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      message: const Text(
        "Veuillez saisir les informations du client",
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        CupertinoTheme(
          data: CupertinoThemeData(
            brightness: Brightness.light,
            primaryColor: CupertinoTheme.of(context).primaryColor,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                CupertinoTextField(
                  controller: nameController,
                  padding: const EdgeInsets.all(12),
                  placeholder: AppStrings.fullName,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: emailController,
                  padding: const EdgeInsets.all(12),
                  placeholder: AppStrings.email,
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      CupertinoIcons.mail_solid,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: phoneController,
                  padding: const EdgeInsets.all(12),
                  placeholder: AppStrings.phoneNumber,
                  keyboardType: TextInputType.phone,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      CupertinoIcons.phone_fill,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: notesController,
                  padding: const EdgeInsets.all(12),
                  placeholder: AppStrings.notes,
                  maxLines: 3,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8, top: 10),
                    child: Icon(
                      CupertinoIcons.text_bubble_fill,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    borderRadius: BorderRadius.circular(10),
                    onPressed: () {
                      // In a real app, you'd save to Supabase here
                      Navigator.pop(context);

                      // Show success banner
                      _showSuccessBanner(
                        context,
                        AppStrings.clientAddedSuccess,
                      );
                    },
                    child: Text(AppStrings.saveClient),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        isDefaultAction: true,
        child: Text(AppStrings.cancel),
      ),
    );
  }

  void _showSuccessBanner(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text("Succès"),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final GlobalKey<HomePageState> _key = GlobalKey();
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<BookingModel> _bookings = [];
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase.rpc('get_bookings_list');

      final bookings =
          (response as List)
              .map((booking) => BookingModel.fromJson(booking))
              .toList();

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void refreshBookings() {
    _fetchBookings();
  }

  List<BookingModel> _getBookingsForSelectedDay() {
    List<BookingModel> bookings =
        _bookings.where((booking) {
          return booking.date.year == _selectedDay.year &&
              booking.date.month == _selectedDay.month &&
              booking.date.day == _selectedDay.day;
        }).toList();

    // Sort bookings by date and time (earliest first), then by firstname
    bookings.sort((a, b) {
      // First sort by date and time
      int dateTimeCompare = a.date.compareTo(b.date);
      if (dateTimeCompare != 0) {
        return dateTimeCompare;
      }

      // If date/time are the same, sort by firstname
      return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
    });

    return bookings;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        padding: EdgeInsetsDirectional.only(start: 16, end: 8),
        middle: null,
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
        leading: Text(
          AppStrings.appName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: CupertinoColors.black,
            fontFamily: '.SF Pro Display',
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // Add new booking
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const NewBookingScreen(),
              ),
            ).then((value) {
              // Refresh bookings if a new booking was added
              if (value == true) {
                refreshBookings();
              }
            });
          },
          child: Icon(CupertinoIcons.add, size: 28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Calendar section is not scrollable
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: _buildCalendar(),
            ),

            // Only bookings list is scrollable
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom:
                      60.0, // Added bottom padding to account for the tab bar height
                ),
                child: _buildBookingsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2025, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday, // Start week on Monday
          locale: 'fr_FR', // Use French locale
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: 'SF Pro Display',
            ),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: CupertinoColors.systemGrey3.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(
              color: CupertinoColors.black,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: BoxDecoration(
              color: CupertinoTheme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: CupertinoTheme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          eventLoader: (day) {
            // Use Set to eliminate duplicates, then convert back to List
            final bookingsForDay =
                _bookings.where((booking) {
                  return booking.date.year == day.year &&
                      booking.date.month == day.month &&
                      booking.date.day == day.day;
                }).toList();

            // Return at most 1 event per day to show only one dot
            return bookingsForDay.isEmpty ? [] : [bookingsForDay.first];
          },
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    final bookingsForSelectedDay = _getBookingsForSelectedDay();

    // iOS-style bookings list with grouped look and pull-to-refresh
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          child: Text(
            DateFormat(
              'EEEE d MMMM',
              'fr_FR',
            ).format(_selectedDay).toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: const BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: _fetchBookings),
                  _isLoading && bookingsForSelectedDay.isEmpty
                      ? SliverFillRemaining(
                        child: const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      )
                      : bookingsForSelectedDay.isEmpty
                      ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.calendar_badge_minus,
                                size: 50,
                                color: CupertinoColors.systemGrey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${AppStrings.noBookings} ${DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDay)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              CupertinoButton.filled(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder:
                                          (context) => const NewBookingScreen(),
                                    ),
                                  ).then((value) {
                                    if (value == true) {
                                      _fetchBookings();
                                    }
                                  });
                                },
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(CupertinoIcons.add, size: 18),
                                    const SizedBox(width: 8),
                                    Text(AppStrings.addNewBooking),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index >= bookingsForSelectedDay.length) {
                            return null;
                          }

                          final booking = bookingsForSelectedDay[index];

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BookingListItem(
                                booking: booking,
                                onTap:
                                    () => _navigateToBookingDetails(booking.id),
                              ),
                              if (index < bookingsForSelectedDay.length - 1)
                                const Divider(
                                  height: 0.5,
                                  color: CupertinoColors.systemGrey5,
                                ),
                            ],
                          );
                        }, childCount: bookingsForSelectedDay.length),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToBookingDetails(String bookingId) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BookingDetailsPage(bookingId: bookingId),
      ),
    ).then((result) {
      // If booking was deleted or updated, refresh the bookings list
      if (result == true) {
        _fetchBookings();
      }
    });
  }
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  AnalyticsPageState createState() => AnalyticsPageState();
}

class AnalyticsPageState extends State<AnalyticsPage>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  List<BookingModel> _bookings = [];

  // Analytics data
  int _totalBookings = 0;
  double _totalRevenue = 0.0;
  Map<String, int> _bookingsByService = {};
  List<MapEntry<String, int>> _topServices = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase.rpc('get_bookings_list');

      final bookings =
          (response as List)
              .map((booking) => BookingModel.fromJson(booking))
              .toList();

      // Calculate analytics
      _totalBookings = bookings.length;
      _totalRevenue = bookings.fold(0, (sum, booking) => sum + 0.0);

      // Group bookings by service
      _bookingsByService = {};
      for (var booking in bookings) {
        _bookingsByService[booking.service] =
            (_bookingsByService[booking.service] ?? 0) + 1;
      }

      // Sort services by popularity
      _topServices =
          _bookingsByService.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching analytics data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
        middle: null,
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
        leading: const Text(
          'Analytiques',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: CupertinoColors.black,
            fontFamily: '.SF Pro Display',
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _fetchAnalyticsData,
        ),
      ),
      child: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCards(),
                          const SizedBox(height: 20),
                          _buildPopularServicesList(),
                          const SizedBox(height: 20),
                          _buildRecentBookingsList(),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Réservations',
            value: _totalBookings.toString(),
            icon: CupertinoIcons.calendar_badge_plus,
            color: CupertinoColors.activeBlue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Revenus',
            value: '€${_totalRevenue.toStringAsFixed(2)}',
            icon: CupertinoIcons.money_euro_circle,
            color: CupertinoColors.activeGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServicesList() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  CupertinoIcons.star_fill,
                  color: CupertinoColors.systemYellow,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Services populaires',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_topServices.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Aucune donnée disponible',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                ),
              )
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _topServices.length > 5 ? 5 : _topServices.length,
                separatorBuilder:
                    (context, index) => const Divider(
                      height: 1,
                      color: CupertinoColors.systemGrey5,
                    ),
                itemBuilder: (context, index) {
                  final entry = _topServices[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: CupertinoTheme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.black,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} réservations',
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.systemGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookingsList() {
    final sortedBookings = [..._bookings]
      ..sort((a, b) => b.date.compareTo(a.date));

    final recentBookings = sortedBookings.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  CupertinoIcons.time,
                  color: CupertinoColors.systemIndigo,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Réservations récentes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentBookings.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Aucune réservation récente',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                ),
              )
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: recentBookings.length,
                separatorBuilder:
                    (context, index) => const Divider(
                      height: 1,
                      color: CupertinoColors.systemGrey5,
                    ),
                itemBuilder: (context, index) {
                  final booking = recentBookings[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              booking.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _getStatusIcon(booking.status),
                            color: _getStatusColor(booking.status),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.customerName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.service,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(booking.date),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '0.00€',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return CupertinoColors.activeGreen;
      case 'cancelled':
        return CupertinoColors.destructiveRed;
      case 'completed':
        return CupertinoColors.activeBlue;
      default:
        return CupertinoColors.systemOrange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return CupertinoIcons.check_mark_circled;
      case 'cancelled':
        return CupertinoIcons.xmark_circle;
      case 'completed':
        return CupertinoIcons.checkmark_seal;
      default:
        return CupertinoIcons.time;
    }
  }
}

class BookingListItem extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const BookingListItem({
    super.key,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format time using the booking's duration
    final formattedTime = DateFormat('HH:mm').format(booking.date);
    final formattedEndTime = DateFormat('HH:mm').format(booking.endTime);

    // Different styling for cancelled bookings
    final TextStyle nameStyle = TextStyle(
      fontSize: 16,
      fontWeight: booking.isCancelled ? FontWeight.normal : FontWeight.w600,
      color:
          booking.isCancelled
              ? CupertinoColors.systemGrey
              : CupertinoColors.black,
      decoration: booking.isCancelled ? TextDecoration.lineThrough : null,
    );

    final TextStyle infoStyle = TextStyle(
      fontSize: 13,
      color:
          booking.isCancelled
              ? CupertinoColors.systemGrey3
              : CupertinoColors.systemGrey,
    );

    // Background color based on booking status
    final Color backgroundColor =
        booking.isCancelled
            ? CupertinoColors.systemGrey6
            : CupertinoColors.white;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            left: BorderSide(
              color:
                  booking.isCancelled
                      ? CupertinoColors.systemRed.withOpacity(0.5)
                      : CupertinoTheme.of(
                        context,
                      ).primaryColor.withOpacity(0.7),
              width: 4.0,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Time column with colored background
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color:
                    booking.isCancelled
                        ? CupertinoColors.systemRed.withOpacity(0.1)
                        : CupertinoTheme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          booking.isCancelled
                              ? CupertinoColors.systemRed.withOpacity(0.8)
                              : CupertinoTheme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedEndTime,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          booking.isCancelled
                              ? CupertinoColors.systemRed.withOpacity(0.6)
                              : CupertinoTheme.of(
                                context,
                              ).primaryColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Main content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      Text(booking.firstName, style: nameStyle),
                      const SizedBox(width: 4),
                      Text(
                        booking.lastName,
                        style: nameStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (booking.isCancelled) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Annulé',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.systemRed,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Group type and persons info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoTheme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          booking.groupType,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color:
                                booking.isCancelled
                                    ? CupertinoColors.systemGrey
                                    : CupertinoTheme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.person_2,
                            size: 12,
                            color: infoStyle.color,
                          ),
                          const SizedBox(width: 2),
                          Text('${booking.nbrPers}', style: infoStyle),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.game_controller,
                            size: 12,
                            color: infoStyle.color,
                          ),
                          const SizedBox(width: 2),
                          Text('${booking.nbrParties}', style: infoStyle),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey3,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class BookingModel {
  final String id; // UUID
  final String firstName;
  final String lastName;
  final DateTime date;
  final String groupType; // activity_type
  final int nbrPers;
  final int duration;
  final int nbrParties;
  final bool isCancelled; // Added is_cancelled field

  // Computed properties
  String get customerName => '$firstName $lastName';
  String get service =>
      groupType; // Map groupType to service for backward compatibility
  String get status =>
      isCancelled ? 'cancelled' : 'confirmed'; // Update based on isCancelled

  BookingModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.date,
    required this.groupType,
    required this.nbrPers,
    required this.duration,
    required this.nbrParties,
    this.isCancelled = false, // Default to false if not provided
  });

  // Computed property to get end time based on duration and number of parties
  DateTime get endTime => date.add(Duration(minutes: duration * nbrParties));

  // Formatted time string
  String formattedTimeRange() {
    final formatter = DateFormat('HH:mm');
    return '${formatter.format(date)} - ${formatter.format(endTime)}';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstname']?.toString() ?? '',
      lastName: json['lastname']?.toString() ?? '',
      date: _parseDateTime(json['date']),
      groupType: json['group_type']?.toString() ?? '',
      nbrPers: _parseInt(json['nbr_pers']),
      duration: _parseInt(json['duration']),
      nbrParties: _parseInt(json['nbr_parties']),
      isCancelled: json['is_cancelled'] == true, // Parse is_cancelled field
    );
  }

  // Helper methods for safe parsing
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
    return DateTime.now();
  }
}
