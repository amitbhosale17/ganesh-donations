import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/subscription_service.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionManagementPage> createState() => _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState extends State<SubscriptionManagementPage> {
  final _subscriptionService = SubscriptionService();
  
  List<Map<String, dynamic>> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    
    try {
      final subscriptions = await _subscriptionService.getSubscriptions();
      
      setState(() {
        _subscriptions = subscriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscriptions: $e')),
        );
      }
    }
  }

  void _showRenewDialog() {
    final yearController = TextEditingController(
      text: (DateTime.now().year + 1).toString(),
    );
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renew Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: yearController,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final year = int.tryParse(yearController.text);
              final amount = double.tryParse(amountController.text);

              if (year == null || amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid year and amount')),
                );
                return;
              }

              try {
                await _subscriptionService.renewSubscription(
                  year: year,
                  amount: amount,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subscription created. Complete payment to activate.')),
                  );
                  _loadSubscriptions();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Renew'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> subscription) {
    String? selectedMethod;
    final transactionIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Year: ${subscription['year']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Amount: ₹${NumberFormat('#,##,###').format(subscription['amount'])}'),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                value: selectedMethod,
                items: const [
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                  DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
                ],
                onChanged: (value) {
                  setDialogState(() => selectedMethod = value);
                },
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: transactionIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedMethod == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select payment method')),
                  );
                  return;
                }

                try {
                  await _subscriptionService.updatePaymentStatus(
                    subscriptionId: subscription['id'],
                    paymentStatus: 'PAID',
                    paymentMethod: selectedMethod,
                    transactionId: transactionIdController.text.isNotEmpty
                        ? transactionIdController.text
                        : null,
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment updated successfully')),
                    );
                    _loadSubscriptions();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Mark as Paid'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PAID':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'EXPIRED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PAID':
        return Icons.check_circle;
      case 'PENDING':
        return Icons.pending;
      case 'EXPIRED':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSubscriptions,
              child: _subscriptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.subscriptions, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No subscriptions yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to renew subscription',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _subscriptions.length,
                      itemBuilder: (context, index) {
                        final subscription = _subscriptions[index];
                        final status = subscription['payment_status'] ?? 'PENDING';
                        final isExpired = subscription['is_expired'] == true;
                        final isCurrent = subscription['is_current'] == true;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: isCurrent ? 4 : 1,
                          color: isCurrent ? Colors.blue[50] : null,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(status).withOpacity(0.2),
                              child: Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  'Year ${subscription['year']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: const Text('Current', style: TextStyle(fontSize: 10)),
                                    backgroundColor: Colors.blue,
                                    labelStyle: const TextStyle(color: Colors.white),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text('Amount: ₹${NumberFormat('#,##,###').format(subscription['amount'])}'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('Status: '),
                                    Chip(
                                      label: Text(
                                        status,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: _getStatusColor(status).withOpacity(0.2),
                                      labelStyle: TextStyle(color: _getStatusColor(status)),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                if (subscription['payment_date'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Paid on: ${subscription['payment_date']}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                                if (isExpired) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Expired',
                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                            trailing: status == 'PENDING'
                                ? ElevatedButton.icon(
                                    onPressed: () => _showPaymentDialog(subscription),
                                    icon: const Icon(Icons.payment, size: 16),
                                    label: const Text('Pay'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRenewDialog,
        icon: const Icon(Icons.add),
        label: const Text('Renew'),
      ),
    );
  }
}
