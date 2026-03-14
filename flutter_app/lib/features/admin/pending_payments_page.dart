import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';

class PendingPaymentsPage extends StatefulWidget {
  const PendingPaymentsPage({super.key});

  @override
  State<PendingPaymentsPage> createState() => _PendingPaymentsPageState();
}

class _PendingPaymentsPageState extends State<PendingPaymentsPage> {
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
        SnackBar(content: Text('Error: ${e.toString()}')),
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
          'notes': 'Payment received',
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

  Future<void> _cancelDonation(int donationId, Map<String, dynamic> donation) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.cancelDonation),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${donation['donor_name']} - ₹${donation['amount']}'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.cancellationReason,
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.backButton),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(AppLocalizations.of(context)!.cancelButton),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    try {
      final response = await ApiClient.dio.put(
        '/donations/$donationId/cancel',
        data: {'reason': reason},
      );

      if (response.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.donationCancelled),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPendingPayments();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pendingPaymentsTitle),
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
                        AppLocalizations.of(context)!.totalPending,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '₹${_totalPending.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        '${_pendingDonations.length} ${AppLocalizations.of(context)!.donationsCount}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                            padding: const EdgeInsets.all(16),
                            itemCount: _pendingDonations.length,
                            itemBuilder: (context, index) {
                              return _buildPendingCard(_pendingDonations[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> donation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      if (donation['donor_phone'] != null &&
                          donation['donor_phone'].toString().isNotEmpty)
                        Text(
                          '📞 ${donation['donor_phone']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                Text(
                  '₹${donation['amount'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(donation['receipt_no'] ?? 'N/A'),
                  backgroundColor: Colors.blue.shade50,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(donation['category'] ?? 'GENERAL'),
                  backgroundColor: Colors.green.shade50,
                ),
                const SizedBox(width: 8),
                // Payment Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.pending,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${AppLocalizations.of(context)!.collectorLabel}: ${donation['collector_name'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '${AppLocalizations.of(context)!.date}: ${DateTime.tryParse(donation['created_at'] ?? '')?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (donation['collector_notes'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '📝 ${donation['collector_notes']}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _cancelDonation(donation['id'], donation),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: Text(AppLocalizations.of(context)!.cancelButton),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _markAsPaid(donation['id'], donation),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(AppLocalizations.of(context)!.receivedButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
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
