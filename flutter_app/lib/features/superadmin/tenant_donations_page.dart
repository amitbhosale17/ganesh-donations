import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';

class TenantDonationsPage extends StatefulWidget {
  final int tenantId;
  final String tenantName;

  const TenantDonationsPage({
    super.key,
    required this.tenantId,
    required this.tenantName,
  });

  @override
  State<TenantDonationsPage> createState() => _TenantDonationsPageState();
}

class _TenantDonationsPageState extends State<TenantDonationsPage> {
  List<dynamic> _donations = [];
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  String? _searchQuery;
  String? _statusFilter;
  String? _methodFilter;

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    setState(() => _isLoading = true);
    try {
      // Note: We need to add tenantId filter to the donations API
      // For now, we'll fetch all and filter client-side
      final response = await ApiClient.dio.get('/donations');
      
      final allDonations = response.data as List;
      final tenantDonations = allDonations.where((d) => 
        d['tenant_id'] == widget.tenantId
      ).toList();

      // Calculate stats
      final totalAmount = tenantDonations.fold<double>(
        0, 
        (sum, d) => sum + _parseAmount(d['amount'])
      );
      final paidCount = tenantDonations.where((d) => 
        d['payment_status'] == 'PAID'
      ).length;
      final pendingCount = tenantDonations.where((d) => 
        d['payment_status'] == 'PENDING'
      ).length;

      setState(() {
        _donations = tenantDonations;
        _stats = {
          'total_amount': totalAmount,
          'total_donations': tenantDonations.length,
          'paid_count': paidCount,
          'pending_count': pendingCount,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading donations: $e')),
        );
      }
    }
  }

  double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is num) return amount.toDouble();
    return double.tryParse(amount.toString()) ?? 0.0;
  }

  List<dynamic> get _filteredDonations {
    var filtered = _donations;

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered = filtered.where((d) {
        final name = (d['donor_name'] ?? '').toString().toLowerCase();
        final phone = (d['donor_phone'] ?? '').toString();
        final receipt = (d['receipt_no'] ?? '').toString();
        final query = _searchQuery!.toLowerCase();
        return name.contains(query) || phone.contains(query) || receipt.contains(query);
      }).toList();
    }

    if (_statusFilter != null) {
      filtered = filtered.where((d) => d['payment_status'] == _statusFilter).toList();
    }

    if (_methodFilter != null) {
      filtered = filtered.where((d) => d['method'] == _methodFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredDonations;

    return Scaffold(
      appBar: AppBar(
        title: Text('Donations - ${widget.tenantName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDonations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_stats != null) _buildStatsCard(),
                _buildFilters(),
                Expanded(
                  child: filteredList.isEmpty
                      ? const Center(child: Text('No donations found'))
                      : RefreshIndicator(
                          onRefresh: _loadDonations,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildDonationCard(filteredList[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total',
              _stats!['total_donations'].toString(),
              Icons.receipt_long,
              Colors.blue,
            ),
            _buildStatItem(
              'Paid',
              _stats!['paid_count'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatItem(
              'Pending',
              _stats!['pending_count'].toString(),
              Icons.pending,
              Colors.orange,
            ),
            _buildStatItem(
              'Amount',
              '₹${_formatAmount(_stats!['total_amount'])}',
              Icons.currency_rupee,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, phone, or receipt...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _searchQuery = null);
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                    DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                  ],
                  onChanged: (value) {
                    setState(() => _statusFilter = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _methodFilter,
                  decoration: const InputDecoration(
                    labelText: 'Method',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                  ],
                  onChanged: (value) {
                    setState(() => _methodFilter = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final amount = _parseAmount(donation['amount']);
    final paymentStatus = donation['payment_status'] ?? 'PAID';
    final method = donation['method'] ?? 'CASH';
    
    DateTime? createdAt;
    try {
      createdAt = DateTime.parse(donation['created_at']);
    } catch (e) {
      createdAt = DateTime.now();
    }

    Color statusColor;
    switch (paymentStatus) {
      case 'PAID':
        statusColor = Colors.green;
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            method == 'UPI' ? Icons.qr_code : Icons.money,
            color: statusColor,
          ),
        ),
        title: Text(
          donation['donor_name'] ?? 'Anonymous',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (donation['donor_phone'] != null)
              Text('📞 ${donation['donor_phone']}'),
            Text('Receipt: ${donation['receipt_no']}'),
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge(paymentStatus, statusColor),
                const SizedBox(width: 8),
                _buildBadge(method, Colors.blue),
              ],
            ),
          ],
        ),
        trailing: Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num = double.tryParse(amount.toString()) ?? 0;
    if (num >= 100000) {
      return '${(num / 100000).toStringAsFixed(1)}L';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toStringAsFixed(0);
  }
}
