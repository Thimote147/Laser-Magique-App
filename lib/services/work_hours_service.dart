import 'package:laser_magique_app/models/work_hour.dart';
import 'package:laser_magique_app/services/auth_service.dart';
import '../main.dart'; // Import to access supabase client

class WorkHoursService {
  final String baseUrl;
  final AuthService authService;

  WorkHoursService({required this.baseUrl, required this.authService});

  Future<List<WorkHour>> getPersonalHours(int month, int year) async {
    final userId = authService.currentUser?.id;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Use Supabase directly to query work_hours table
      final response = await supabase
          .from('work_hours')
          .select()
          .eq('user_id', userId)
          .gte('date', '$year-$month-01')
          .lt(
            'date',
            month == 12 ? '${year + 1}-01-01' : '$year-${month + 1}-01',
          );

      return (response as List).map((json) => WorkHour.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load work hours: $e');
    }
  }

  Future<WorkHour> addWorkHour(WorkHour workHour) async {
    final userId = authService.currentUser?.id;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Format date as 'YYYY-MM-DD'
      final dateStr =
          "${workHour.date.year}-${workHour.date.month.toString().padLeft(2, '0')}-${workHour.date.day.toString().padLeft(2, '0')}";

      // Call the PostgreSQL function through Supabase RPC
      await supabase.rpc(
        'add_work_hours',
        params: {
          'p_user_id': userId,
          'p_date': dateStr,
          'p_beginning': workHour.beginning,
          'p_ending': workHour.ending,
        },
      );

      // Return the original work hour instead of trying to fetch it back
      // This ensures we don't hang if the fetch fails
      return workHour;
    } catch (e) {
      throw Exception('Failed to add work hour: $e');
    }
  }

  Future<void> deleteWorkHour(String hourId) async {
    try {
      // Use Supabase directly to delete from work_hours table
      await supabase.from('work_hours').delete().eq('hour_id', hourId);
    } catch (e) {
      throw Exception('Failed to delete work hour: $e');
    }
  }

  Future<void> updateWorkHour(WorkHour workHour) async {
    if (workHour.hourId.isEmpty) {
      throw Exception('Hour ID is required for updating');
    }

    try {
      // Format date as 'YYYY-MM-DD'
      final dateStr =
          "${workHour.date.year}-${workHour.date.month.toString().padLeft(2, '0')}-${workHour.date.day.toString().padLeft(2, '0')}";

      // Call the PostgreSQL function through Supabase RPC
      await supabase.rpc(
        'update_work_hours',
        params: {
          'p_hour_id': workHour.hourId,
          'p_date': dateStr,
          'p_beginning': workHour.beginning,
          'p_ending': workHour.ending,
        },
      );
    } catch (e) {
      throw Exception('Failed to update work hour: $e');
    }
  }

  Future<List<WorkHour>> getAllUsersHours(int month, int year) async {
    final userId = authService.currentUser?.id;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // First, check if the current user is an admin
      final userResponse =
          await supabase
              .from('users')
              .select('role')
              .eq('user_id', userId)
              .single();

      // If not admin, throw an exception
      if (userResponse['role'] != 'admin') {
        throw Exception('Not authorized. Admin access required.');
      }

      // Call the PostgreSQL function to fetch all users' hours
      final response = await supabase.rpc(
        'get_hours_by_users',
        params: {'actual_month': month, 'actual_year': year},
      );

      // Convert response to WorkHour objects
      List<WorkHour> workHours = [];

      // Process response, filtering out null entries (users with no hours)
      for (var json in response as List) {
        // Skip users who don't have any hours logged (hour_id is null)
        if (json['hour_id'] == null) {
          // Add a placeholder entry with the user's name and zero hours/amount
          workHours.add(
            WorkHour(
              hourId: '', // Empty ID for placeholder
              date: DateTime(
                year,
                month,
                1,
              ), // First day of month as placeholder
              beginning: '00:00',
              ending: '00:00',
              nbrHours: '00:00',
              amount: 0,
              userName: json['firstname'] as String? ?? '',
            ),
          );
          continue;
        }

        // Create WorkHour objects with the firstname included
        final workHour = WorkHour.fromJson(json);
        workHour.userName = json['firstname'] as String? ?? '';
        workHours.add(workHour);
      }

      // Sort work hours by user name first, then by date
      workHours.sort((a, b) {
        // First sort by username
        int nameCompare = a.userName.compareTo(b.userName);
        if (nameCompare != 0) {
          return nameCompare;
        }

        // Special case for placeholder entries (empty hourId)
        if (a.hourId.isEmpty) return -1;
        if (b.hourId.isEmpty) return 1;

        // Then by date (descending)
        int dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) {
          return dateCompare;
        }

        // Finally by beginning time if same date
        return a.beginning.compareTo(b.beginning);
      });

      return workHours;
    } catch (e) {
      throw Exception('Failed to load all users\' hours: $e');
    }
  }

  // Checks if the current user has admin role
  Future<bool> isCurrentUserAdmin() async {
    final userId = authService.currentUser?.id;

    if (userId == null) {
      return false;
    }

    try {
      final userResponse =
          await supabase
              .from('users')
              .select('role')
              .eq('user_id', userId)
              .single();

      return userResponse['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
}
