import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _storage = const FlutterSecureStorage();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedReport = 'summary';
  bool _isLoading = false;
  
  Map<String, dynamic>? _summaryData;
  List<Map<String, dynamic>> _dailyData = [];
  List<Map<String, dynamic>> _collectorData = [];
  List<Map<String, dynamic>> _topDonors = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  
  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadReports();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'accessToken');
      
      final startDateStr = _startDate?.toIso8601String();
      final endDateStr = _endDate?.toIso8601String();
      
      // Load all reports in parallel
      final responses = await Future.wait([
        ApiClient.dio.get(
          '/reports/summary',
          queryParameters: {
            if (startDateStr != null) 'start_date': startDateStr,
            if (endDateStr != null) 'end_date': endDateStr,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        ),
        ApiClient.dio.get(
          '/reports/daily',
          queryParameters: {
            if (startDateStr != null) 'start_date': startDateStr,
            if (endDateStr != null) 'end_date': endDateStr,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        ),
        ApiClient.dio.get(
          '/reports/by-collector',
          queryParameters: {
            if (startDateStr != null) 'start_date': startDateStr,
            if (endDateStr != null) 'end_date': endDateStr,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        ),
        ApiClient.dio.get(
          '/reports/top-donors',
          queryParameters: {
            if (startDateStr != null) 'start_date': startDateStr,
            if (endDateStr != null) 'end_date': endDateStr,
            'limit': '10',
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        ),
        ApiClient.dio.get(
          '/reports/payment-methods',
          queryParameters: {
            if (startDateStr != null) 'start_date': startDateStr,
            if (endDateStr != null) 'end_date': endDateStr,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        ),
      ]);
      
      setState(() {
        _summaryData = responses[0].data;
        _dailyData = List<Map<String, dynamic>>.from(responses[1].data);
        _collectorData = List<Map<String, dynamic>>.from(responses[2].data);
        _topDonors = List<Map<String, dynamic>>.from(responses[3].data);
        _paymentMethods = List<Map<String, dynamic>>.from(responses[4].data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReports();
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildSummaryCards() {
    if (_summaryData == null) return const SizedBox();
    
    final totalAmount   = _toDouble(_summaryData!['total_amount']);
    final upiAmount     = _toDouble(_summaryData!['upi_amount']);
    final cashAmount    = _toDouble(_summaryData!['cash_amount']);
    final chequeAmount  = _toDouble(_summaryData!['cheque_amount']);
    final expenseAmount     = _toDouble(_summaryData!['expense_amount']);
    final overallNetAmount  = _toDouble(_summaryData!['overall_net_amount']);
    final totalCount        = _summaryData!['total_donations'] ?? 0;
    final upiCount      = _summaryData!['upi_count'] ?? 0;
    final cashCount     = _summaryData!['cash_count'] ?? 0;
    final chequeCount   = _summaryData!['cheque_count'] ?? 0;
    
    return Column(
      children: [
        // Row 1: Total collected + UPI
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                AppLocalizations.of(context)!.totalDonationsCount,
                '$totalCount',
                _formatCurrency(totalAmount),
                Colors.blue,
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'UPI',
                '$upiCount',
                _formatCurrency(upiAmount),
                Colors.purple,
                Icons.qr_code,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Cash + Cheque
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                AppLocalizations.of(context)!.cashPayment,
                '$cashCount',
                _formatCurrency(cashAmount),
                Colors.orange,
                Icons.money,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Cheque',
                '$chequeCount',
                _formatCurrency(chequeAmount),
                Colors.teal,
                Icons.account_balance,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 3: Period Expenses + Overall Balance
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Period Expenses',
                '(-)',
                _formatCurrency(expenseAmount),
                Colors.red,
                Icons.remove_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Overall Balance',
                '✅',
                _formatCurrency(overallNetAmount),
                Colors.green,
                Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReport() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.dailyReport,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_dailyData.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(AppLocalizations.of(context)!.noDonationsInPeriod),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _dailyData.length,
                itemBuilder: (context, index) {
                  final day = _dailyData[index];
                  final total = _toDouble(day['total']);
                  final upi = _toDouble(day['upi_amount']);
                  final cash = _toDouble(day['cash_amount']);
                  final cheque = _toDouble(day['cheque_amount']);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '${day['count']}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    title: Text(_formatDate(day['date'])),
                    subtitle: Text(
                      'UPI: ${_formatCurrency(upi)} | Cash: ${_formatCurrency(cash)}${cheque > 0 ? ' | Cheque: ${_formatCurrency(cheque)}' : ''}',
                    ),
                    trailing: Text(
                      _formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectorReport() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.collectorPerformanceTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_collectorData.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(AppLocalizations.of(context)!.noCollectorData),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _collectorData.length,
                itemBuilder: (context, index) {
                  final collector = _collectorData[index];
                  final total       = _toDouble(collector['total_amount']);
                  final upi         = _toDouble(collector['upi_amount']);
                  final cash        = _toDouble(collector['cash_amount']);
                  final cheque      = _toDouble(collector['cheque_amount']);
                  final donCount    = collector['donation_count'] ?? 0;
                  
                  final methodParts = <String>[];
                  if (upi > 0)    methodParts.add('UPI: ${_formatCurrency(upi)}');
                  if (cash > 0)   methodParts.add('Cash: ${_formatCurrency(cash)}');
                  if (cheque > 0) methodParts.add('Cheque: ${_formatCurrency(cheque)}');

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        (collector['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(collector['name'] ?? 'Unknown'),
                    subtitle: Text(
                      '$donCount ${AppLocalizations.of(context)!.donations}'
                      '${methodParts.isNotEmpty ? '\n${methodParts.join(' | ')}' : ''}',
                    ),
                    trailing: Text(
                      _formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDonorsReport() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.topDonors,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_topDonors.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(AppLocalizations.of(context)!.noDonorData),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _topDonors.length,
                itemBuilder: (context, index) {
                  final donor = _topDonors[index];
                  final total = _toDouble(donor['total_amount']);
                  final rank = index + 1;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rank <= 3 ? Colors.amber : Colors.grey,
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(donor['donor_name'] ?? 'Anonymous'),
                    subtitle: Text(
                      '${donor['donation_count']} ${AppLocalizations.of(context)!.donations} | ${donor['donor_phone'] ?? ''}',
                    ),
                    trailing: Text(
                      _formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.paymentMethodAnalysis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_paymentMethods.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(AppLocalizations.of(context)!.noDataAvailable),
                ),
              )
            else
              Column(
                children: _paymentMethods.map((method) {
                  final total = _toDouble(method['total']);
                  final count = method['count'] ?? 0;
                  final avg = _toDouble(method['average']);
                  final rawMethod = method['method'] ?? 'OTHER';
                  final methodName = rawMethod == 'UPI'
                      ? 'UPI'
                      : rawMethod == 'CHEQUE'
                          ? 'Cheque'
                          : AppLocalizations.of(context)!.cashPayment;
                  final color = rawMethod == 'UPI'
                      ? Colors.purple
                      : rawMethod == 'CHEQUE'
                          ? Colors.teal
                          : Colors.orange;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              methodName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              _formatCurrency(total),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count ${AppLocalizations.of(context)!.donationsCount} | ${AppLocalizations.of(context)!.averageLabel}: ${_formatCurrency(avg)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: total / (_summaryData != null ? _toDouble(_summaryData!['total_amount']) : 1),
                          backgroundColor: Colors.grey[200],
                          color: color,
                          minHeight: 8,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reportsAndStats),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: AppLocalizations.of(context)!.selectDateTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: AppLocalizations.of(context)!.refreshTooltip,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range display
                    Card(
                      color: Colors.indigo[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_formatDate(_startDate?.toIso8601String())} - ${_formatDate(_endDate?.toIso8601String())}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Summary cards
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    
                    // Payment methods chart
                    _buildPaymentMethodsChart(),
                    const SizedBox(height: 24),
                    
                    // Top donors
                    _buildTopDonorsReport(),
                    const SizedBox(height: 24),
                    
                    // Collector performance
                    _buildCollectorReport(),
                    const SizedBox(height: 24),
                    
                    // Daily report
                    _buildDailyReport(),
                  ],
                ),
              ),
            ),
    );
  }
}
