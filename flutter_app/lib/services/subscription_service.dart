import '../core/api_client.dart';

class SubscriptionService {
  /// Get all subscriptions for the tenant
  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    try {
      final response = await ApiClient.dio.get('/subscriptions');
      
      if (response.data['success'] == true) {
        final List<dynamic> subscriptions = response.data['subscriptions'] ?? [];
        return subscriptions.cast<Map<String, dynamic>>();
      }
      
      throw Exception(response.data['error'] ?? 'Failed to fetch subscriptions');
    } catch (e) {
      print('Error fetching subscriptions: $e');
      rethrow;
    }
  }

  /// Get subscription for a specific year
  Future<Map<String, dynamic>> getSubscriptionByYear(int year) async {
    try {
      final response = await ApiClient.dio.get('/subscriptions/$year');
      
      if (response.data['success'] == true) {
        return response.data['subscription'] ?? {};
      }
      
      throw Exception(response.data['error'] ?? 'Failed to fetch subscription');
    } catch (e) {
      print('Error fetching subscription for year $year: $e');
      rethrow;
    }
  }

  /// Renew subscription for a year
  Future<Map<String, dynamic>> renewSubscription({
    required int year,
    required double amount,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/subscriptions/renew',
        data: {
          'year': year,
          'amount': amount,
        },
      );
      
      if (response.data['success'] == true) {
        return response.data['subscription'] ?? {};
      }
      
      throw Exception(response.data['error'] ?? 'Failed to renew subscription');
    } catch (e) {
      print('Error renewing subscription: $e');
      rethrow;
    }
  }

  /// Update payment status for a subscription
  Future<Map<String, dynamic>> updatePaymentStatus({
    required int subscriptionId,
    required String paymentStatus,
    String? paymentMethod,
    String? transactionId,
  }) async {
    try {
      final response = await ApiClient.dio.put(
        '/subscriptions/$subscriptionId/payment',
        data: {
          'payment_status': paymentStatus,
          if (paymentMethod != null) 'payment_method': paymentMethod,
          if (transactionId != null) 'transaction_id': transactionId,
        },
      );
      
      if (response.data['success'] == true) {
        return response.data['subscription'] ?? {};
      }
      
      throw Exception(response.data['error'] ?? 'Failed to update payment status');
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }

  /// Get available years (only PAID subscriptions)
  Future<List<int>> getAvailableYears() async {
    try {
      final response = await ApiClient.dio.get('/subscriptions/available-years');
      
      if (response.data['success'] == true) {
        final List<dynamic> years = response.data['years'] ?? [];
        return years.map((y) => y['year'] as int).toList();
      }
      
      throw Exception(response.data['error'] ?? 'Failed to fetch available years');
    } catch (e) {
      print('Error fetching available years: $e');
      rethrow;
    }
  }
}
