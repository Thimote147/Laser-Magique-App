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
      final response = await supabase.rpc(
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
}
