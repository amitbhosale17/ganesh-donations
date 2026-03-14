import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../core/api_client.dart';

/// Yearly Dashboard Page
/// 
/// Purpose:
/// - Display year-wise donation statistics for the Mandal
/// - Show total collected per year
/// - Display number of donations, collectors, unique donors
/// - Show current year's monthly breakdown
/// 
/// Edge Cases Handled:
/// - No data available (new mandals)
/// - Network failures with retry
/// - Empty years gracefully displayed
class YearlyDashboardPage extends StatefulWidget {
  const YearlyDashboardPage({super.key});

  @override
  State<YearlyDashboardPage> createState() => _YearlyDashboardPageState();
}

class _YearlyDashboardPageState extends State<YearlyDashboardPage> {
  List<Map<String, dynamic>> yearlyStats = [];
  List<Map<String, dynamic>> monthlyData = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await ApiClient.dio.get('/stats/yearly');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          yearlyStats = List<Map<String, dynamic>>.from(response.data['yearly_stats'] ?? []);
          monthlyData = List<Map<String, dynamic>>.from(response.data['current_year_monthly'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load statistics';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Yearly Dashboard'),
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorState()
              : yearlyStats.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadStats,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Header with total summary
                          _buildSummaryCard(currencyFormat),
                          const SizedBox(height: 24),
                          
                          // Yearly breakdown
                          Text(
                            'Year-wise Collection',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...yearlyStats.map((stat) => _buildYearCard(stat, currencyFormat)),
                          
                          const SizedBox(height: 24),
                          
                          // Current year monthly breakdown
                          if (monthlyData.isNotEmpty) ...[
                            Text(
                              'Current Year Monthly Breakdown',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildMonthlyChart(currencyFormat),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSummaryCard(NumberFormat currencyFormat) {
    final totalAmount = yearlyStats.fold<double>(0, (sum, stat) => sum + (stat['total_paid'] ?? 0.0));
    final totalDonations = yearlyStats.fold<int>(0, (sum, stat) => sum + ((stat['total_donations'] ?? 0) as int));
    final totalYears = yearlyStats.length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Collection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(totalAmount),
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Years', totalYears.toString(), Colors.white),
                _buildSummaryItem('Donations', totalDonations.toString(), Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildYearCard(Map<String, dynamic> stat, NumberFormat currencyFormat) {
    final year = stat['year'];
    final totalPaid = stat['total_paid'] ?? 0.0;
    final totalPending = stat['total_pending'] ?? 0.0;
    final totalDonations = stat['total_donations'] ?? 0;
    final activeCollectors = stat['active_collectors'] ?? 0;
    final uniqueDonors = stat['unique_donors'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.deepOrange, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Year $year',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currencyFormat.format(totalPaid),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.receipt_long,
                    label: 'Donations',
                    value: totalDonations.toString(),
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people,
                    label: 'Collectors',
                    value: activeCollectors.toString(),
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.person,
                    label: 'Donors',
                    value: uniqueDonors.toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            if (totalPending > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Pending: ${currencyFormat.format(totalPending)}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(NumberFormat currencyFormat) {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: monthlyData.map((data) {
            final month = data['month'] - 1;
            final amount = data['amount'] ?? 0.0;
            final count = data['count'] ?? 0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      monthNames[month],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currencyFormat.format(amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$count donations',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: amount / _getMaxAmount(),
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  double _getMaxAmount() {
    if (monthlyData.isEmpty) return 1.0;
    return monthlyData.fold<double>(0, (max, data) {
      final amount = data['amount'] ?? 0.0;
      return amount > max ? amount : max;
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No donation data yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start collecting donations to see statistics',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            error ?? 'Failed to load statistics',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
