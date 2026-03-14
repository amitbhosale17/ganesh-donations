import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import 'upi_qr_screen.dart';
import '../receipt/receipt_page.dart';

class CollectorPendingPaymentsPage extends StatefulWidget {
  const CollectorPendingPaymentsPage({super.key});

  @override
  State<CollectorPendingPaymentsPage> createState() => _CollectorPendingPaymentsPageState();
}

class _CollectorPendingPaymentsPageState extends State<CollectorPendingPaymentsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingDonations = [];
  double _totalPending = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPendingPayments();
  }

  Future<void> _loadPendingPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiClient.dio.get('/donations/pending');

      if (response.data['success'] == true) {
        setState(() {
          _pendingDonations = List<Map<String, dynamic>>.from(
            response.data['pending_donations'] ?? [],
          );
          _totalPending = (response.data['total_pending_amount'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorLabel}: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsPaid(int donationId, Map<String, dynamic> donation) async {
    String? selectedMethod = donation['method']; // Default to original method
    final tenant = AuthService.getCurrentTenant();
    final qrUrl = tenant?['upi_qr_url'];
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        String currentMethod = selectedMethod ?? 'CASH';
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.paymentReceivedQuestion),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${donation['donor_name']} - ₹${donation['amount']}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.selectPaymentMethod,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('UPI'),
                      value: 'UPI',
                      groupValue: currentMethod,
                      secondary: const Icon(Icons.qr_code, color: Colors.purple),
                      onChanged: (value) => setState(() => currentMethod = value!),
                    ),
                    RadioListTile<String>(
                      title: Text(AppLocalizations.of(context)!.cash),
                      value: 'CASH',
                      groupValue: currentMethod,
                      secondary: const Icon(Icons.money, color: Colors.green),
                      onChanged: (value) => setState(() => currentMethod = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Cheque'),
                      value: 'CHEQUE',
                      groupValue: currentMethod,
                      secondary: const Icon(Icons.account_balance, color: Colors.teal),
                      onChanged: (value) => setState(() => currentMethod = value!),
                    ),
                    if (currentMethod == 'UPI' && qrUrl != null && qrUrl.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.scanQrToPay,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.network(
                                qrUrl,
                                width: 150,
                                height: 150,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.qr_code, size: 100, color: Colors.grey);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.no),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, {'confirmed': true, 'method': currentMethod}),
                  child: Text(AppLocalizations.of(context)!.yesReceived),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result['confirmed'] != true) return;

    try {
      final response = await ApiClient.dio.put(
        '/donations/$donationId/mark-paid',
        data: {
          'payment_date': DateTime.now().toIso8601String(),
          'notes': 'Payment received by collector',
          'method': result['method'], // Update payment method
        },
      );

      if (response.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${AppLocalizations.of(context)!.paymentMarkedReceived}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingPayments();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorLabel}: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myPendingPayments),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingPayments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.shade50,
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.totalPendingAmount,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '₹${NumberFormat('#,##,###').format(_totalPending)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        '${_pendingDonations.length} ${AppLocalizations.of(context)!.pendingPayments}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _pendingDonations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 64, color: Colors.green),
                              SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.noPendingPayments,
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPendingPayments,
                          child: ListView.builder(
                            itemCount: _pendingDonations.length,
                            itemBuilder: (context, index) {
                              final donation = _pendingDonations[index];
                              return _buildDonationCard(donation);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final createdAt = DateTime.tryParse(donation['created_at'] ?? '');
    final dateStr = createdAt != null
        ? DateFormat('dd/MM/yyyy hh:mm a').format(createdAt)
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigate to receipt page to view/reprint
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReceiptPage(
                receiptNo: donation['receipt_no'] ?? '',
                donorName: donation['donor_name'] ?? 'Anonymous',
                donorPhone: donation['donor_phone'],
                donorAddress: donation['donor_address'],
                donorPan: donation['donor_pan'],
                amount: (donation['amount'] as num).toDouble(),
                method: donation['method'] ?? 'CASH',
                dateTime: createdAt ?? DateTime.now(),
                paymentStatus: 'PENDING',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donation['donor_name'] ?? AppLocalizations.of(context)!.unknown,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (donation['donor_phone'] != null)
                          Text(
                            '📞 ${donation['donor_phone']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${NumberFormat('#,##,###').format(donation['amount'])}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    donation['method'] == 'UPI' ? Icons.qr_code : Icons.money,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    donation['method'] ?? 'CASH',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.receipt, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    donation['receipt_no'] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${AppLocalizations.of(context)!.collectorLabel}: ${donation['collector_name'] ?? 'Unknown'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (donation['category'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  donation['category'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsPaid(donation['id'], donation),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text(AppLocalizations.of(context)!.receivedButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
