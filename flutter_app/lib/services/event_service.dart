import '../core/api_client.dart';

class EventService {
  /// Get available event types for the current tenant (filtered by religion)
  Future<List<Map<String, dynamic>>> getEventTypes() async {
    try {
      final response = await ApiClient.dio.get('/events/types');
      
      if (response.data['success'] == true) {
        final List<dynamic> eventTypes = response.data['event_types'] ?? [];
        return eventTypes.cast<Map<String, dynamic>>();
      }
      
      throw Exception(response.data['error'] ?? 'Failed to fetch event types');
    } catch (e) {
      print('Error fetching event types: $e');
      rethrow;
    }
  }

  /// Get organization events (tenant's created events)
  Future<List<Map<String, dynamic>>> getOrganizationEvents({int? year}) async {
    try {
      final queryParams = year != null ? '?year=$year' : '';
      final response = await ApiClient.dio.get('/events/organization-events$queryParams');
      
      if (response.data['success'] == true) {
        final List<dynamic> events = response.data['events'] ?? [];
        return events.cast<Map<String, dynamic>>();
      }
      
      throw Exception(response.data['error'] ?? 'Failed to fetch organization events');
    } catch (e) {
      print('Error fetching organization events: $e');
      rethrow;
    }
  }

  /// Create a new organization event
  Future<Map<String, dynamic>> createOrganizationEvent({
    required int eventTypeId,
    required int eventYear,
    required String startDate,
    required String endDate,
    double? targetAmount,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/events/organization-events',
        data: {
          'event_type_id': eventTypeId,
          'event_year': eventYear,
          'start_date': startDate,
          'end_date': endDate,
          if (targetAmount != null) 'target_amount': targetAmount,
        },
      );
      
      if (response.data['success'] == true) {
        return response.data['event'] ?? {};
      }
      
      throw Exception(response.data['error'] ?? 'Failed to create event');
    } catch (e) {
      print('Error creating organization event: $e');
      rethrow;
    }
  }

  /// Update organization event
  Future<Map<String, dynamic>> updateOrganizationEvent({
    required int eventId,
    double? targetAmount,
    bool? isActive,
  }) async {
    try {
      final response = await ApiClient.dio.put(
        '/events/organization-events/$eventId',
        data: {
          if (targetAmount != null) 'target_amount': targetAmount,
          if (isActive != null) 'is_active': isActive,
        },
      );
      
      if (response.data['success'] == true) {
        return response.data['event'] ?? {};
      }
      
      throw Exception(response.data['error'] ?? 'Failed to update event');
    } catch (e) {
      print('Error updating organization event: $e');
      rethrow;
    }
  }

  /// Delete organization event
  Future<void> deleteOrganizationEvent(int eventId) async {
    try {
      final response = await ApiClient.dio.delete('/events/organization-events/$eventId');
      
      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to delete event');
      }
    } catch (e) {
      print('Error deleting organization event: $e');
      rethrow;
    }
  }
}
