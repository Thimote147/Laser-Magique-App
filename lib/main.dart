import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this import for global localizations
import 'dart:math'; // Import for max function
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/profile_screen.dart';
import 'screens/new_booking_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/work_hours/work_hours_screen.dart';
import 'services/auth_service.dart';
import 'services/work_hours_service.dart';
import 'utils/app_strings.dart';
import 'utils/theme_service.dart';
import 'utils/protected_route.dart';
import 'pages/booking_details_page.dart';

// Global Supabase client instance
late final SupabaseClient supabase;

// Global navigation key to access navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global theme service instance
final themeService = ThemeService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr_FR', null);

  // Initialize theme service
  await themeService.initialize();

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

class LaserMagiqueApp extends StatefulWidget {
  const LaserMagiqueApp({super.key});

  @override
  LaserMagiqueAppState createState() => LaserMagiqueAppState();
}

class LaserMagiqueAppState extends State<LaserMagiqueApp> {
  // Auth service instance
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Écouter les changements de thème
    themeService.addListener(_onThemeChanged);

    // Initialize auth service
    _authService.initialize();
  }

  @override
  void dispose() {
    // Supprimer l'écouteur quand le widget est supprimé
    themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  // Méthode appelée quand le thème change
  void _onThemeChanged() {
    setState(() {}); // Forcer la reconstruction du widget avec le nouveau thème
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _authService),
        Provider<WorkHoursService>(
          create:
              (_) => WorkHoursService(
                baseUrl: dotenv.env['SUPABASE_URL'] ?? '',
                authService: _authService,
              ),
        ),
      ],
      child: CupertinoApp(
        navigatorKey: navigatorKey,
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        theme: themeService.getTheme(),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return CupertinoPageRoute(builder: (_) => const AuthWrapper());
            case '/login':
              return CupertinoPageRoute(builder: (_) => const LoginScreen());
            case '/home':
              return CupertinoPageRoute(
                builder: (_) => const ProtectedRoute(child: MainScreen()),
              );
            case '/profile':
              return CupertinoPageRoute(
                builder: (_) => const ProtectedRoute(child: ProfileScreen()),
              );
            case '/work-hours':
              return CupertinoPageRoute(
                builder: (_) => const ProtectedRoute(child: WorkHoursScreen()),
              );
            default:
              return CupertinoPageRoute(builder: (_) => const AuthWrapper());
          }
        },
      ),
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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fetch user data from the users table using the current authenticated user's UUID
  Future<void> _fetchUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return;

    try {
      // Query the users table using the auth user's UUID
      await supabase.from('users').select().eq('user_id', user.id).single();
      // Not storing response since it's not used
    } catch (e) {
      // Error handling without storing the error
    }
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
                  StockScreen(),
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
                      icon: const Icon(CupertinoIcons.cube_box),
                      label: AppStrings.stock,
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
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  bool _isDayView = false; // New state to track the current view mode

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
    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();

    return CupertinoPageScaffold(
      backgroundColor: themeService.getBackgroundColor(),
      navigationBar: CupertinoNavigationBar(
        padding: EdgeInsetsDirectional.only(start: 16, end: 8),
        middle: null,
        backgroundColor: themeService.getBackgroundColor(),
        border: null,
        leading: Text(
          AppStrings.appName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: textColor,
            fontFamily: '.SF Pro Display',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle between calendar and day view
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _isDayView = !_isDayView;
                });
              },
              child: Icon(
                _isDayView
                    ? CupertinoIcons.calendar
                    : CupertinoIcons.calendar_today,
                size: 24,
                color: CupertinoTheme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            // Add new booking
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // Add new booking
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder:
                        (context) =>
                            NewBookingScreen(initialDate: _selectedDay),
                  ),
                ).then((value) {
                  // Refresh bookings if a new booking was added
                  if (value == true) {
                    refreshBookings();
                  }
                });
              },
              child: Icon(
                CupertinoIcons.add,
                size: 28,
                color: CupertinoTheme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child:
            _isDayView
                ? _buildDayView(textColor, secondaryTextColor)
                : _buildCalendarView(textColor, secondaryTextColor),
      ),
    );
  }

  Widget _buildCalendarView(Color textColor, Color secondaryTextColor) {
    return Column(
      children: [
        // Calendar section is not scrollable
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            child: _buildBookingsList(textColor, secondaryTextColor),
          ),
        ),
      ],
    );
  }

  Widget _buildDayView(Color textColor, Color secondaryTextColor) {
    final bookingsForSelectedDay = _getBookingsForSelectedDay();
    final cardColor = themeService.getCardColor();

    return Column(
      children: [
        // Date selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: themeService.getSeparatorColor(),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _selectedDay = _selectedDay.subtract(
                          const Duration(days: 1),
                        );
                      });
                    },
                    child: Icon(
                      CupertinoIcons.chevron_left,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      // Show date picker
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDay,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2025, 12, 31),
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary:
                                    CupertinoTheme.of(context).primaryColor,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != _selectedDay) {
                        setState(() {
                          _selectedDay = picked;
                        });
                      }
                    },
                    child: Column(
                      children: [
                        Text(
                          DateFormat(
                            'EEEE',
                            'fr_FR',
                          ).format(_selectedDay).capitalize(),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'd MMMM yyyy',
                            'fr_FR',
                          ).format(_selectedDay),
                          style: TextStyle(
                            fontSize: 15,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _selectedDay = _selectedDay.add(
                          const Duration(days: 1),
                        );
                      });
                    },
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Calendar day view with time slots
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 8.0,
              left: 16.0,
              right: 16.0,
              bottom: 60.0, // Added bottom padding for the tab bar
            ),
            child: _buildDayCalendarView(
              textColor,
              secondaryTextColor,
              bookingsForSelectedDay,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCalendarView(
    Color textColor,
    Color secondaryTextColor,
    List<BookingModel> bookings,
  ) {
    final cardColor = themeService.getCardColor();
    final separatorColor = themeService.getSeparatorColor();

    // Define time range
    final startHour = 8; // 8 AM
    final endHour = 22; // 10 PM

    // Slot height in logical pixels (increased for better readability)
    final double slotHeight =
        90.0; // Increased from 60.0 to 90.0 for larger time slots
    final double halfHourHeight =
        slotHeight / 2; // Adjusted to match new slotHeight
    final double timeColumnWidth = 50.0;

    // Calculate the total height required (14 hours * 60 pixels per hour)
    final double totalHeight = (endHour - startHour + 1) * slotHeight;

    // Group overlapping bookings to handle them properly
    final Map<int, List<BookingModel>> bookingsByTimeSlot =
        _groupOverlappingBookings(bookings);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: separatorColor, blurRadius: 10, spreadRadius: 0),
        ],
      ),
      child:
          bookings.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.calendar_badge_minus,
                      size: 50,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.noBookings,
                      style: TextStyle(fontSize: 16, color: secondaryTextColor),
                    ),
                  ],
                ),
              )
              : CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: _fetchBookings),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: totalHeight,
                      child: Stack(
                        children: [
                          // Time column
                          Positioned(
                            top: 0,
                            left: 0,
                            bottom: 0,
                            width: timeColumnWidth,
                            child: Column(
                              children: List.generate(
                                (endHour - startHour + 1),
                                (index) {
                                  final hour = startHour + index;
                                  return _buildTimeLabel(
                                    hour,
                                    slotHeight,
                                    secondaryTextColor,
                                    separatorColor,
                                  );
                                },
                              ),
                            ),
                          ),

                          // Horizontal lines for each hour
                          ...List.generate(
                            (endHour - startHour + 1) * 2 +
                                1, // +1 for the last line
                            (index) {
                              return Positioned(
                                top: index * halfHourHeight,
                                left: timeColumnWidth,
                                right: 0,
                                height: 0.5,
                                child: Container(
                                  color:
                                      index % 2 == 0
                                          ? separatorColor
                                          : separatorColor.withOpacity(
                                            0.5,
                                          ), // Dimmer line for half hours
                                ),
                              );
                            },
                          ),

                          // Bookings - draw each group of overlapping bookings
                          ...bookingsByTimeSlot.entries.expand((entry) {
                            final overlappingBookings = entry.value;
                            final int bookingsCount =
                                overlappingBookings.length;

                            // Calculate available width for all bookings with additional right margin
                            final double availableWidth =
                                MediaQuery.of(context).size.width -
                                timeColumnWidth -
                                36; // Increased right margin (16 left + 20 right) to prevent overflow

                            // Define minimum width per booking card and padding between cards
                            final double minBookingWidth =
                                70.0; // Reduced minimum width
                            final double horizontalPadding = 2.0;

                            // Calculate actual booking width based on available space and number of bookings
                            double bookingWidth;

                            if (bookingsCount == 1) {
                              // For single booking, use available width minus margin
                              bookingWidth = availableWidth - 4;
                            } else {
                              // For multiple bookings, ensure no overflow by calculating width precisely
                              // Distribute available width evenly, accounting for spacing between cards
                              final double totalSpacingWidth =
                                  horizontalPadding * (bookingsCount - 1);
                              bookingWidth =
                                  (availableWidth - totalSpacingWidth) /
                                  bookingsCount;

                              // Apply minimum width if needed, but ensure total width doesn't exceed available
                              if (bookingWidth < minBookingWidth) {
                                // If we can't fit all cards at minimum width, we'll need to make them narrower
                                if (minBookingWidth * bookingsCount +
                                        totalSpacingWidth >
                                    availableWidth) {
                                  bookingWidth =
                                      (availableWidth - totalSpacingWidth) /
                                      bookingsCount;
                                } else {
                                  bookingWidth = minBookingWidth;
                                }
                              }
                            }

                            return overlappingBookings.asMap().entries.map((
                              bookingEntry,
                            ) {
                              final int bookingIndex = bookingEntry.key;
                              final BookingModel booking = bookingEntry.value;

                              // Calculate position and size of booking
                              final bookingStartMinutes =
                                  (booking.date.hour - startHour) * 60 +
                                  booking.date.minute;
                              final bookingDurationMinutes =
                                  booking.duration * booking.nbrParties;

                              // Calculate top position
                              final double top =
                                  bookingStartMinutes * (slotHeight / 60);

                              // Calculate height based on total duration (duration * nbrParties)
                              final double height =
                                  bookingDurationMinutes * (slotHeight / 60);

                              // Calculate left position based on booking index in the overlapping group
                              // Make sure even the last card stays within bounds
                              final double bookingLeft =
                                  timeColumnWidth +
                                  1 + // reduced from 2 to 1 to save space
                                  (bookingWidth + horizontalPadding) *
                                      bookingIndex;

                              return Positioned(
                                top: top,
                                left: bookingLeft,
                                width: bookingWidth,
                                height: max(
                                  height,
                                  30.0,
                                ), // Ensure minimum height
                                child: _buildCalendarBookingCard(
                                  booking,
                                  textColor,
                                  secondaryTextColor,
                                ),
                              );
                            }).toList();
                          }).toList(),

                          // Current time indicator if selected day is today
                          if (isSameDay(_selectedDay, DateTime.now()))
                            _buildCurrentTimeIndicator(
                              startHour,
                              slotHeight,
                              timeColumnWidth,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  // Helper method to group overlapping bookings
  Map<int, List<BookingModel>> _groupOverlappingBookings(
    List<BookingModel> bookings,
  ) {
    if (bookings.isEmpty) return {};

    // Sort bookings by start time
    final sortedBookings = [...bookings]
      ..sort((a, b) => a.date.compareTo(b.date));

    // Map to store groups of overlapping bookings
    // The key is a unique group identifier (incrementing integer)
    final Map<int, List<BookingModel>> bookingGroups = {};
    int groupCounter = 0;

    // For each booking, find if it overlaps with any existing group
    for (final booking in sortedBookings) {
      bool foundOverlap = false;

      // Try to add to an existing group if it overlaps
      for (final entry in bookingGroups.entries) {
        final group = entry.value;
        // Check if this booking overlaps with any booking in the group
        bool overlapsWithGroup = group.any((existingBooking) {
          return _bookingsOverlap(booking, existingBooking);
        });

        if (overlapsWithGroup) {
          // Add to existing group
          group.add(booking);
          foundOverlap = true;
          break;
        }
      }

      // If no overlap found, create a new group
      if (!foundOverlap) {
        bookingGroups[groupCounter] = [booking];
        groupCounter++;
      }
    }

    return bookingGroups;
  }

  // Helper method to check if two bookings overlap
  bool _bookingsOverlap(BookingModel a, BookingModel b) {
    // a starts before b ends AND b starts before a ends = overlap
    return a.date.isBefore(b.endTime) && b.date.isBefore(a.endTime);
  }

  Widget _buildTimeLabel(
    int hour,
    double slotHeight,
    Color secondaryTextColor,
    Color separatorColor,
  ) {
    final timeFormatted = DateFormat(
      'HH:00',
    ).format(DateTime(2023, 1, 1, hour, 0));

    return SizedBox(
      height: slotHeight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              right: 8.0,
              top: 4.0,
            ), // Added top padding for better alignment
            child: Text(
              timeFormatted,
              style: TextStyle(
                fontSize: 14, // Increased from 12 to 14
                fontWeight: FontWeight.w600, // Increased weight
                color: secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTimeIndicator(
    int startHour,
    double slotHeight,
    double timeColumnWidth,
  ) {
    final now = DateTime.now();

    // Calculate position from start of day in minutes
    final currentMinutesSinceDayStart =
        (now.hour - startHour) * 60 + now.minute;
    final double top = currentMinutesSinceDayStart * (slotHeight / 60);

    // Only show if time is in the visible range
    if (currentMinutesSinceDayStart < 0 || now.hour > 22)
      return const SizedBox.shrink();

    return Positioned(
      top: top,
      left: timeColumnWidth - 6,
      right: 0,
      child: Row(
        children: [
          // Larger indicator circle with a subtle shadow effect
          Container(
            width: 16, // Increased from 12 to 16
            height: 16, // Increased from 12 to 16
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemRed.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // Thicker line
          Expanded(
            child: Container(
              height: 2.0, // Increased from 1.5 to 2.0
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarBookingCard(
    BookingModel booking,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => _navigateToBookingDetails(booking.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        decoration: BoxDecoration(
          color:
              booking.isCancelled
                  ? CupertinoColors.systemRed.withOpacity(0.1)
                  : primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                booking.isCancelled
                    ? CupertinoColors.systemRed.withOpacity(0.5)
                    : primaryColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        // Use fit: BoxFit.fill to make sure content fills available space
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available height to properly size content
            final availableHeight = constraints.maxHeight;
            // Only show the bottom section if we have enough space
            final bool showBottomSection = availableHeight > 45;

            return Padding(
              padding: const EdgeInsets.all(
                4.0,
              ), // Reduced padding from 6.0 to 4.0
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with time - larger icon and text
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.clock,
                        size: 13, // Reduced from 14 to 13
                        color:
                            booking.isCancelled
                                ? CupertinoColors.systemRed
                                : primaryColor,
                      ),
                      const SizedBox(width: 2), // Reduced from 4 to 2
                      Flexible(
                        child: Text(
                          booking.formattedTimeRange(),
                          style: TextStyle(
                            fontSize: 12, // Reduced from 13 to 12
                            fontWeight: FontWeight.w600,
                            color:
                                booking.isCancelled
                                    ? CupertinoColors.systemRed
                                    : primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2), // Reduced from 3 to 2
                  // Client name - always show this
                  Flexible(
                    child: Text(
                      "${booking.firstName} ${booking.lastName}",
                      style: TextStyle(
                        fontSize: 13, // Reduced from 14 to 13
                        fontWeight: FontWeight.w600,
                        color:
                            booking.isCancelled
                                ? secondaryTextColor
                                : textColor,
                        decoration:
                            booking.isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  // Only show bottom details if there's enough space
                  if (showBottomSection)
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1, // Reduced from 2 to 1
                              ),
                              decoration: BoxDecoration(
                                color:
                                    booking.isCancelled
                                        ? CupertinoColors.systemGrey
                                            .withOpacity(0.1)
                                        : primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                booking.groupType,
                                style: TextStyle(
                                  fontSize: 11, // Reduced from 12 to 11
                                  fontWeight: FontWeight.w500,
                                  color:
                                      booking.isCancelled
                                          ? secondaryTextColor
                                          : primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.person_2,
                                size: 12, // Reduced from 14 to 12
                                color:
                                    booking.isCancelled
                                        ? secondaryTextColor.withOpacity(0.7)
                                        : secondaryTextColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${booking.nbrPers}',
                                style: TextStyle(
                                  fontSize: 11, // Reduced from 12 to 11
                                  fontWeight: FontWeight.w500,
                                  color:
                                      booking.isCancelled
                                          ? secondaryTextColor.withOpacity(0.7)
                                          : secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final calendarBackgroundColor = themeService.getCardColor();
    final textColor = themeService.getTextColor();

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        color: calendarBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: themeService.getSeparatorColor(),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        // Wrap TableCalendar with Material widget
        child: Material(
          color: Colors.transparent, // Make it transparent to keep your styling
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
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF Pro Display',
                color: textColor,
              ),
              leftChevronIcon: Icon(
                CupertinoIcons.chevron_left,
                color: CupertinoTheme.of(context).primaryColor,
              ),
              rightChevronIcon: Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoTheme.of(context).primaryColor,
              ),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: textColor),
              weekendTextStyle: TextStyle(
                color:
                    themeService.darkMode
                        ? CupertinoColors.systemRed.darkColor
                        : CupertinoColors.systemRed,
              ),
              outsideTextStyle: TextStyle(
                color: themeService.getSecondaryTextColor().withOpacity(
                  0.6,
                ), // Replaced withAlpha with withOpacity
              ),
              todayDecoration: BoxDecoration(
                color: CupertinoColors.systemGrey3.withOpacity(
                  0.3,
                ), // Replaced withAlpha with withOpacity
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: CupertinoTheme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.bold,
              ),
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: CupertinoTheme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color:
                    themeService.darkMode
                        ? CupertinoColors.systemRed.darkColor
                        : CupertinoColors.systemRed,
                fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildBookingsList(Color textColor, Color secondaryTextColor) {
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: themeService.getCardColor(),
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
                              Icon(
                                CupertinoIcons.calendar_badge_minus,
                                size: 50,
                                color: secondaryTextColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${AppStrings.noBookings} ${DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDay)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: secondaryTextColor,
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
                                Divider(
                                  height: 0.5,
                                  color: themeService.getSeparatorColor(),
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
      // Check if booking was deleted, cancelled or updated
      if (result == true) {
        _fetchBookings(); // Simple refresh for updates
      } else if (result is Map && result['refreshCalendar'] == true) {
        // This handles both deletion and cancellation
        _fetchBookings();
      }
    });
  }
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

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
    // Add theme change listener
    themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    // Remove theme change listener
    themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  // Force UI update when theme changes
  void _onThemeChanged() {
    setState(() {});
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textColor = themeService.getTextColor();
    final backgroundColor = themeService.getBackgroundColor();

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
        middle: null,
        backgroundColor: backgroundColor,
        border: null,
        leading: Text(
          'Statistiques',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: textColor,
            fontFamily: '.SF Pro Display',
          ),
        ),
      ),
      child: SafeArea(
        child:
            _isLoading && _bookings.isEmpty
                ? const Center(child: CupertinoActivityIndicator())
                : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: _fetchAnalyticsData,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildSummaryCards(),
                            const SizedBox(height: 20),
                            _buildPopularServicesList(),
                            const SizedBox(height: 20),
                            _buildRecentBookingsList(),
                            const SizedBox(height: 20),
                          ],
                        ),
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
            value: '${_totalRevenue.toStringAsFixed(2)}€',
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
    final cardColor = themeService.getCardColor();
    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final separatorColor = themeService.getSeparatorColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: separatorColor,
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
                  color: color.withOpacity(
                    0.1,
                  ), // Changed from withAlpha(25) to withOpacity(0.1)
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServicesList() {
    final cardColor = themeService.getCardColor();
    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final separatorColor = themeService.getSeparatorColor();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: separatorColor,
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
            Row(
              children: [
                const Icon(
                  CupertinoIcons.star_fill,
                  color: CupertinoColors.systemYellow,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Activités populaires',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_topServices.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Aucune donnée disponible',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
              )
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _topServices.length > 5 ? 5 : _topServices.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(height: 1, color: separatorColor),
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
                          child: const Text(
                            '●',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} réservations',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
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
    final cardColor = themeService.getCardColor();
    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final separatorColor = themeService.getSeparatorColor();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: separatorColor,
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
            Row(
              children: [
                Icon(
                  CupertinoIcons.time,
                  color:
                      themeService.darkMode
                          ? CupertinoColors.systemIndigo.darkColor
                          : CupertinoColors.systemIndigo,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Réservations récentes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentBookings.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Aucune réservation récente',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
              )
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: recentBookings.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(height: 1, color: separatorColor),
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
                            color: _getStatusColor(booking.status).withOpacity(
                              0.1,
                            ), // Replaced withAlpha with withOpacity
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
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.service,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '0.00€',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CupertinoTheme.of(context).primaryColor,
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
    // Use theme-aware colors that respect dark/light mode
    switch (status.toLowerCase()) {
      case 'confirmed':
        return themeService.darkMode
            ? CupertinoColors.activeGreen.darkColor
            : CupertinoColors.activeGreen;
      case 'cancelled':
        return themeService.darkMode
            ? CupertinoColors.systemRed.darkColor
            : CupertinoColors.systemRed;
      case 'completed':
        return themeService.darkMode
            ? CupertinoColors.activeBlue.darkColor
            : CupertinoColors.activeBlue;
      default:
        return themeService.darkMode
            ? CupertinoColors.systemOrange.darkColor
            : CupertinoColors.systemOrange;
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

    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final cardColor = themeService.getCardColor();

    // Different styling for cancelled bookings
    final TextStyle nameStyle = TextStyle(
      fontSize: 16,
      fontWeight: booking.isCancelled ? FontWeight.normal : FontWeight.w600,
      color: booking.isCancelled ? secondaryTextColor : textColor,
      decoration: booking.isCancelled ? TextDecoration.lineThrough : null,
    );

    final TextStyle infoStyle = TextStyle(
      fontSize: 13,
      color:
          booking.isCancelled
              ? secondaryTextColor.withOpacity(0.7)
              : secondaryTextColor,
    );

    // Background color based on booking status
    final Color backgroundColor =
        booking.isCancelled
            ? cardColor.withOpacity(
              0.7,
            ) // Slightly transparent in cancelled state
            : cardColor;

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
                      ? CupertinoColors.systemRed.withOpacity(
                        0.5,
                      ) // Replaced withAlpha with withOpacity
                      : CupertinoTheme.of(context).primaryColor.withOpacity(
                        0.7,
                      ), // Replaced withAlpha with withOpacity
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
                        ? CupertinoColors.systemRed.withOpacity(
                          0.1,
                        ) // Replaced withAlpha with withOpacity
                        : CupertinoTheme.of(context).primaryColor.withOpacity(
                          0.1,
                        ), // Replaced withAlpha with withOpacity
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
                                    ? secondaryTextColor
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
            Icon(
              CupertinoIcons.chevron_right,
              color: secondaryTextColor,
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
        // Silently handle parsing errors
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

// Extension method to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
