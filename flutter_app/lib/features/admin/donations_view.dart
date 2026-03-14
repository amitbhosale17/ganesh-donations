import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class DonationsView extends StatefulWidget {
  const DonationsView({super.key});

  @override
  State<DonationsView> createState() => _DonationsViewState();
}

class _DonationsViewState extends State<DonationsView> {
  List<dynamic> donations = [];
  Map<String, dynamic>? stats;
  bool isLoading = true;
  
  // Filters
  String? selectedMethod;
  String? selectedCollector;
  DateTimeRange? dateRange;
  String searchQuery = '';
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDonations() async {
    setState(() => isLoading = true);
    try {
      final dio = ApiClient.dio;
      
      // Build query parameters
      final params = <String, dynamic>{};
      if (selectedMethod != null) params['method'] = selectedMethod;
      if (searchQuery.isNotEmpty) params['search'] = searchQuery;
      if (dateRange != null) {
        params['start_date'] = DateFormat('yyyy-MM-dd').format(dateRange!.start);
        params['end_date'] = DateFormat('yyyy-MM-dd').format(dateRange!.end);
      }
      
      final response = await dio.get('/donations', queryParameters: params);
      
      // Get stats
      final statsResponse = await dio.get('/donations/stats');
      
      setState(() {
        // API returns {donations: [...], total: N, ...} — extract the list
        final data = response.data;
        if (data is Map && data.containsKey('donations')) {
          donations = List<dynamic>.from(data['donations']);
        } else if (data is List) {
          donations = List<dynamic>.from(data);
        } else {
          donations = [];
        }
        stats = statsResponse.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading donations: $e')),
        );
      }
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.filterLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Payment Method Filter
            DropdownButtonFormField<String>(
              value: selectedMethod,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.paymentMethod,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.all)),
                const DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(value: 'CASH', child: Text(AppLocalizations.of(context)!.cashPayment)),
                const DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
              ],
              onChanged: (value) {
                setState(() => selectedMethod = value);
              },
            ),
            const SizedBox(height: 16),
            
            // Date Range Filter
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: dateRange,
                );
                if (picked != null) {
                  setState(() => dateRange = picked);
                }
              },
              icon: const Icon(Icons.date_range),
              label: Text(
                dateRange == null
                    ? AppLocalizations.of(context)!.selectDate
                    : '${DateFormat('dd/MM/yyyy').format(dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange!.end)}',
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedMethod = null;
                        dateRange = null;
                        searchQuery = '';
                        searchController.clear();
                      });
                      Navigator.pop(context);
                      _loadDonations();
                    },
                    child: Text(AppLocalizations.of(context)!.reset),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadDonations();
                    },
                    child: Text(AppLocalizations.of(context)!.apply),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.allDonations),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
            tooltip: AppLocalizations.of(context)!.filterLabel,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                final dio = ApiClient.dio;
                final response = await dio.get(
                  '/donations/export.csv',
                  options: Options(responseType: ResponseType.plain),
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.csvDownloadSuccess)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            tooltip: AppLocalizations.of(context)!.csvDownloadTooltip,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchByNamePhoneReceipt,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
                          _loadDonations();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                setState(() => searchQuery = value);
                _loadDonations();
              },
            ),
          ),
          
          // Stats Summary
          if (stats != null) _buildStatsSummary(),
          
          // Donations List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : donations.isEmpty
                    ? Center(child: Text(AppLocalizations.of(context)!.noDonationsFound))
                    : RefreshIndicator(
                        onRefresh: _loadDonations,
                        child: ListView.builder(
                          itemCount: donations.length,
                          itemBuilder: (context, index) {
                            final donation = donations[index];
                            return _buildDonationCard(donation);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                AppLocalizations.of(context)!.totalDonationsCount,
                stats!['total_count'].toString(),
                Icons.receipt,
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                AppLocalizations.of(context)!.totalAmountValue,
                '₹${NumberFormat('#,##,###').format(_toDouble(stats!['total_amount']))}',
                Icons.currency_rupee,
                Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final createdAt = DateTime.tryParse(donation['created_at'] ?? '');
    final dateStr = createdAt != null
        ? DateFormat('dd/MM/yyyy hh:mm a').format(createdAt)
        : '';
    
    final paymentStatus = donation['payment_status'] ?? 'PAID';
    final isPending = paymentStatus == 'PENDING';
    final isCancelled = paymentStatus == 'CANCELLED';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCancelled
              ? Colors.red.shade100
              : isPending
                  ? Colors.orange.shade100
                  : donation['method'] == 'UPI'
                      ? Colors.purple.shade100
                      : donation['method'] == 'CHEQUE'
                          ? Colors.teal.shade100
                          : Colors.green.shade100,
          child: Icon(
            isCancelled
                ? Icons.cancel
                : isPending
                    ? Icons.schedule
                    : donation['method'] == 'UPI'
                        ? Icons.qr_code
                        : donation['method'] == 'CHEQUE'
                            ? Icons.account_balance
                            : Icons.money,
            color: isCancelled
                ? Colors.red
                : isPending
                    ? Colors.orange
                    : donation['method'] == 'UPI'
                        ? Colors.purple
                        : donation['method'] == 'CHEQUE'
                            ? Colors.teal
                            : Colors.green,
          ),
        ),
        title: Text(
          donation['donor_name'] ?? AppLocalizations.of(context)!.anonymous,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLocalizations.of(context)!.receipt}: ${donation['receipt_number'] ?? donation['receipt_no'] ?? ''}'),
            if (donation['donor_phone'] != null)
              Text('${AppLocalizations.of(context)!.phoneLabel}: ${donation['donor_phone']}'),
            Text(dateStr),
            const SizedBox(height: 4),
            // Payment Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCancelled
                    ? Colors.red.shade100
                    : isPending
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCancelled
                        ? Icons.cancel
                        : isPending
                            ? Icons.schedule
                            : Icons.check_circle,
                    size: 14,
                    color: isCancelled
                        ? Colors.red
                        : isPending
                            ? Colors.orange
                            : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCancelled
                        ? AppLocalizations.of(context)!.paymentStatusCancelled
                        : isPending
                            ? AppLocalizations.of(context)!.paymentStatusPending
                            : AppLocalizations.of(context)!.paymentStatusPaid,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCancelled
                          ? Colors.red.shade700
                          : isPending
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Text(
          '₹${NumberFormat('#,##,###').format(_toDouble(donation['amount']))}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}
