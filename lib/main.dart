import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'screens/new_booking_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/booking_details_screen.dart';

// Global Supabase client instance
late final SupabaseClient supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return MaterialApp(
      title: 'Laser Magique',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF007AFF), // iOS blue
        scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS light background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF2F2F7),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF007AFF)),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        fontFamily: 'SF Pro Display', // iOS default font
        cardTheme: CardTheme(
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF007AFF), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase.rpc('get_bookings_list');

      final bookings = (response as List)
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

  List<BookingModel> _getBookingsForSelectedDay() {
    return _bookings.where((booking) {
      return booking.date.year == _selectedDay.year &&
          booking.date.month == _selectedDay.month &&
          booking.date.day == _selectedDay.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildCalendarPage(),
          const NewBookingScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildCalendarPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laser Magique'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _fetchBookings,
          ),
        ],
      ),
      body: Column(
        children: [_buildCalendar(), Expanded(child: _buildBookingsList())],
      ),
      // Add a FAB for directly adding new bookings from calendar view
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
        onPressed: () {
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2025, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
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
            ),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          eventLoader: (day) {
            return _bookings.where((booking) {
              return booking.date.year == day.year &&
                  booking.date.month == day.month &&
                  booking.date.day == day.day;
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    final bookingsForSelectedDay = _getBookingsForSelectedDay();

    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (bookingsForSelectedDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.calendar_badge_minus,
              size: 50,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings for ${DateFormat('EEEE, MMMM d').format(_selectedDay)}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(CupertinoIcons.add),
              label: const Text('Add New Booking'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: bookingsForSelectedDay.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final booking = bookingsForSelectedDay[index];
          return BookingListItem(
            booking: booking, 
            onTap: () => _navigateToBookingDetails(booking.id),
          );
        },
      ),
    );
  }

  void _navigateToBookingDetails(int bookingId) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BookingDetailsScreen(bookingId: bookingId),
      ),
    ).then((result) {
      // If booking was deleted or updated, refresh the bookings list
      if (result == true) {
        _fetchBookings();
      }
    });
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.calendar),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.plus_square),
          label: 'New Booking',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.settings),
          label: 'Settings',
        ),
      ],
    );
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
    // Determine status color
    Color statusColor;
    switch (booking.status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: const Icon(CupertinoIcons.person_fill, color: Color(0xFF007AFF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.customerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.service,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('h:mm a').format(booking.date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '€${booking.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Colors.grey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class BookingModel {
  final int id;
  final String customerName;
  final String service;
  final DateTime date;
  final double price;
  final String status;

  BookingModel({
    required this.id,
    required this.customerName,
    required this.service,
    required this.date,
    required this.price,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: _parseId(json['id']),
      customerName: json['customer_name']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      date: _parseDateTime(json['date']),
      price: _parsePrice(json['price']),
      status: json['status']?.toString() ?? 'pending',
    );
  }

  // Helper methods for safe parsing
  static int _parseId(dynamic value) {
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

  static double _parsePrice(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
