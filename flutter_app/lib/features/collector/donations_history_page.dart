import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../l10n/app_localizations.dart';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../receipt/receipt_page.dart';

class DonationsHistoryPage extends StatefulWidget {
  const DonationsHistoryPage({super.key});

  @override
  State<DonationsHistoryPage> createState() => _DonationsHistoryPageState();
}

class _DonationsHistoryPageState extends State<DonationsHistoryPage> {
  List<Map<String, dynamic>> donations = [];
  List<Map<String, dynamic>> filteredDonations = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? selectedStatus;
  String? selectedMethod;
  DateTime? startDate;
  DateTime? endDate;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDonations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Debounce search to avoid too many API calls
  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadDonations();
    });
  }

  Timer? _searchDebounce;

  Future<void> _loadDonations() async {
    setState(() => isLoading = true);
    try {
      // Build query parameters for API filtering
      final queryParams = <String, dynamic>{};
      
      if (_searchController.text.isNotEmpty) {
        queryParams['search'] = _searchController.text;
      }
      if (selectedStatus != null) {
        queryParams['payment_status'] = selectedStatus;
      }
      if (selectedMethod != null) {
        queryParams['method'] = selectedMethod;
      }
      if (startDate != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate!);
      }
      if (endDate != null) {
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate!);
      }
      
      final response = await ApiClient.dio.get('/donations', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          if (data is Map && data.containsKey('donations')) {
            // New API format with pagination info
            donations = List<Map<String, dynamic>>.from(data['donations']);
            filteredDonations = donations;
            totalCount = data['total'] ?? donations.length;
          } else {
            // Old API format (backwards compatible)
            donations = List<Map<String, dynamic>>.from(data);
            filteredDonations = donations;
            totalCount = donations.length;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading donations: $e')),
        );
      }
    }
  }

  void _filterDonations() {
    // Now filtering is done server-side, just reload
    _loadDonations();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      selectedStatus = null;
      selectedMethod = null;
      startDate = null;
      endDate = null;
    });
    _loadDonations();
  }

  double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is num) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allDonations),
        actions: [
          if (selectedStatus != null || selectedMethod != null || 
              _searchController.text.isNotEmpty || startDate != null || endDate != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: l10n.clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDonations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '${l10n.searchByName}, ${l10n.phone}, ${l10n.receiptNo}',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: l10n.status,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.all)),
                          DropdownMenuItem(value: 'PAID', child: Text(l10n.paymentStatusPaid)),
                          DropdownMenuItem(value: 'PENDING', child: Text(l10n.paymentStatusPending)),
                          DropdownMenuItem(value: 'CANCELLED', child: Text(l10n.paymentStatusCancelled)),
                        ],
                        onChanged: (value) {
                          setState(() => selectedStatus = value);
                          _filterDonations();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMethod,
                        decoration: InputDecoration(
                          labelText: l10n.method,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.all)),
                          const DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                          const DropdownMenuItem(value: 'CASH', child: Text('CASH')),
                          const DropdownMenuItem(value: 'CHEQUE', child: Text('CHEQUE')),
                        ],
                        onChanged: (value) {
                          setState(() => selectedMethod = value);
                          _filterDonations();
                        },
                      ),
                    ),
                  ],
                ),                const SizedBox(height: 12),
                // Date Range Filter
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => startDate = picked);
                            _filterDonations();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          startDate == null
                              ? 'Start Date'
                              : DateFormat('dd/MM/yyyy').format(startDate!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('to', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => endDate = picked);
                            _filterDonations();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          endDate == null
                              ? 'End Date'
                              : DateFormat('dd/MM/yyyy').format(endDate!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                      ),
                    ),
                    if (startDate != null || endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            startDate = null;
                            endDate = null;
                          });
                          _filterDonations();
                        },
                        tooltip: 'Clear dates',
                      ),
                  ],
                ),              ],
            ),
          ),
          // Results Count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${l10n.totalRecords}: ${filteredDonations.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${l10n.totalAmount}: ₹${_calculateTotal()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Donations List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDonations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noDonationsFound,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredDonations.length,
                        itemBuilder: (context, index) {
                          final donation = filteredDonations[index];
                          return _buildDonationCard(donation);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _calculateTotal() {
    double total = 0;
    for (var donation in filteredDonations) {
      if (donation['payment_status'] != 'CANCELLED') {
        total += _parseAmount(donation['amount']);
      }
    }
    return NumberFormat('#,##,###.##').format(total);
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation['donor_name'] ?? AppLocalizations.of(context)!.anonymous,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (donation['donor_phone'] != null)
                        Text(
                          '📞 ${donation['donor_phone']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      Text(
                        donation['receipt_no'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                      Text(
                        '₹${NumberFormat('#,##,###').format(_parseAmount(donation['amount']))}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCancelled ? Colors.grey : Colors.green,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    Text(
                      donation['method'] ?? 'CASH',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
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
                const SizedBox(width: 8),
                if (donation['collector_name'] != null) ...[
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    donation['collector_name'],
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
                dateStr,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            if (donation['notes'] != null && donation['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    donation['notes'],
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isCancelled ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReceiptPage(
                              receiptNo: donation['receipt_no'] ?? '',
                              donorName: donation['donor_name'] ?? 'Anonymous',
                              donorPhone: donation['donor_phone'],
                              donorAddress: donation['donor_address'],
                              donorPan: donation['donor_pan'],
                              amount: _parseAmount(donation['amount']),
                              method: donation['method'] ?? 'CASH',
                              dateTime: createdAt ?? DateTime.now(),
                              paymentStatus: paymentStatus,
                            ),
                          ),
                        );
                      },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: Text(AppLocalizations.of(context)!.viewReceipt),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isCancelled ? Colors.grey : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isCancelled ? null : () async {
                        await AuthService.refreshTenant();
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReceiptPage(
                              receiptNo: donation['receipt_no'] ?? '',
                              donorName: donation['donor_name'] ?? 'Anonymous',
                              donorPhone: donation['donor_phone'],
                              donorAddress: donation['donor_address'],
                              donorPan: donation['donor_pan'],
                              amount: _parseAmount(donation['amount']),
                              method: donation['method'] ?? 'CASH',
                              dateTime: createdAt ?? DateTime.now(),
                              paymentStatus: paymentStatus,
                              autoPrint: true,
                            ),
                          ),
                        );
                      },
                    icon: const Icon(Icons.print, size: 18),
                    label: Text(AppLocalizations.of(context)!.printReceipt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCancelled ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
