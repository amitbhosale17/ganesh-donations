import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/api_client.dart';
import 'dart:async';

class DonorSearchPage extends StatefulWidget {
  const DonorSearchPage({super.key});

  @override
  State<DonorSearchPage> createState() => _DonorSearchPageState();
}

class _DonorSearchPageState extends State<DonorSearchPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchDonors(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await ApiClient.dio.get(
        '/donors/search',
        queryParameters: {'q': query.trim()},
      );

      if (response.data['success'] == true) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(
            response.data['donors'] ?? [],
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchDonors(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.donorSearch),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterNameOrPhone,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!_hasSearched)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.enterNamePhoneToSearch,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (_searchResults.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noResultsFound,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return _buildDonorCard(_searchResults[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDonorCard(Map<String, dynamic> donor) {
    final totalAmount = donor['total_amount'] ?? 0.0;
    final totalDonations = donor['total_donations'] ?? 0;
    final isRecurring = donor['is_recurring'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRecurring ? Colors.green : Colors.blue,
          child: Icon(
            isRecurring ? Icons.star : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          donor['donor_name'] ?? AppLocalizations.of(context)!.unknown,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (donor['donor_phone'] != null && donor['donor_phone'].isNotEmpty)
              Text('📞 ${donor['donor_phone']}'),
            Text(
              '₹${totalAmount.toStringAsFixed(2)} • $totalDonations ${AppLocalizations.of(context)!.donationsCount}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DonorHistoryPage(
                donorName: donor['donor_name'],
                donorPhone: donor['donor_phone'],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DonorHistoryPage extends StatefulWidget {
  final String? donorName;
  final String? donorPhone;

  const DonorHistoryPage({
    super.key,
    this.donorName,
    this.donorPhone,
  });

  @override
  State<DonorHistoryPage> createState() => _DonorHistoryPageState();
}

class _DonorHistoryPageState extends State<DonorHistoryPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _donorData;
  List<Map<String, dynamic>> _donations = [];

  @override
  void initState() {
    super.initState();
    _loadDonorHistory();
  }

  Future<void> _loadDonorHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final queryParams = <String, String>{};
      if (widget.donorPhone != null && widget.donorPhone!.isNotEmpty) {
        queryParams['phone'] = widget.donorPhone!;
      } else if (widget.donorName != null) {
        queryParams['name'] = widget.donorName!;
      }

      final response = await ApiClient.dio.get(
        '/donors/history',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        setState(() {
          _donorData = {
            'donor': response.data['donor'],
            'summary': response.data['summary'],
          };
          _donations = List<Map<String, dynamic>>.from(
            response.data['donations'] ?? [],
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loading error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final donor = _donorData?['donor'] as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(
        title: Text(donor?['name'] ?? widget.donorName ?? AppLocalizations.of(context)!.donor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDonorHistory,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.donationHistory,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._donations.map((donation) => _buildDonationCard(donation)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _donorData?['summary'] ?? {};
    final totalAmount = summary['total_amount'] ?? 0.0;
    final paidAmount = summary['paid_amount'] ?? 0.0;
    final pendingAmount = summary['pending_amount'] ?? 0.0;
    final totalDonations = summary['total_donations'] ?? 0;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Text(
                    (_donorData?['name'] ?? 'D')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _donorData?['name'] ?? AppLocalizations.of(context)!.unknown,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_donorData?['phone'] != null)
                        Text(
                          '📞 ${_donorData!['phone']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (_donorData?['is_recurring'] == true)
                        Chip(
                          label: Text(AppLocalizations.of(context)!.recurringDonor),
                          backgroundColor: Colors.green,
                          labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(AppLocalizations.of(context)!.totalAmount, '₹${totalAmount.toStringAsFixed(0)}'),
                _buildStat(AppLocalizations.of(context)!.paid, '₹${paidAmount.toStringAsFixed(0)}'),
                if (pendingAmount > 0)
                  _buildStat(AppLocalizations.of(context)!.pending, '₹${pendingAmount.toStringAsFixed(0)}',
                      color: Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${AppLocalizations.of(context)!.totalDonationsCount}: $totalDonations',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final paymentStatus = donation['payment_status'] ?? 'PAID';
    final isPending = paymentStatus == 'PENDING';
    final isCancelled = paymentStatus == 'CANCELLED';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCancelled
              ? Colors.red
              : isPending
                  ? Colors.orange
                  : Colors.green,
          child: Icon(
            isCancelled
                ? Icons.cancel
                : isPending
                    ? Icons.schedule
                    : Icons.check,
            color: Colors.white,
          ),
        ),
        title: Text(
          donation['receipt_no'] ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${donation['category']} • ${donation['method']}'),
            Text(
              DateTime.tryParse(donation['created_at'] ?? '')
                      ?.toLocal()
                      .toString()
                      .split('.')[0] ??
                  '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
                        ? AppLocalizations.of(context)!.cancelledStatus
                        : isPending
                            ? AppLocalizations.of(context)!.pending
                            : AppLocalizations.of(context)!.paid,
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
          '₹${donation['amount'].toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isCancelled ? Colors.grey : Colors.green,
            decoration: isCancelled ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
