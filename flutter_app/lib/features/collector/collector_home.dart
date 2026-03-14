import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/auth_service.dart';
import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import 'donation_form_page.dart';
import 'collector_pending_payments_page.dart';
import 'donations_history_page.dart';
import '../receipt/receipt_page.dart';
import '../login/login_page.dart';
import '../expenses/expense_page.dart';

class CollectorHome extends StatefulWidget {
  const CollectorHome({super.key});

  @override
  State<CollectorHome> createState() => _CollectorHomeState();
}

class _CollectorHomeState extends State<CollectorHome> {
  final user = AuthService.getCurrentUser();
  final tenant = AuthService.getCurrentTenant();
  
  Map<String, dynamic>? stats;
  List<dynamic>? recentDonations;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadStats() async {
    setState(() => isLoading = true);
    try {
      final dio = ApiClient.dio;
      
      final statsResponse = await dio.get('/stats/today');
      final recentResponse = await dio.get('/stats/recent');
      
      setState(() {
        stats = statsResponse.data;
        recentDonations = recentResponse.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(AppLocalizations.of(context)!.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.yes),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.logout();
      
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tenant?['name'] ?? 'गणेश मंडळ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: AppLocalizations.of(context)!.logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.hello}, ${user?['name'] ?? AppLocalizations.of(context)!.collector}!',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.startCollectingDonations,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Today's Stats
                    Text(
                      AppLocalizations.of(context)!.todaysCollection,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildTodayStats(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      AppLocalizations.of(context)!.actions,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.add_circle,
                          label: AppLocalizations.of(context)!.newDonationButton,
                          color: Colors.green,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                          builder: (_) => const DonationFormPage(),
                        ),
                      );
                      _loadStats(); // Refresh stats after adding donation
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.schedule,
                    label: AppLocalizations.of(context)!.myPendingPayments,
                    color: Colors.orange,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CollectorPendingPaymentsPage(),
                        ),
                      );
                      _loadStats();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    label: AppLocalizations.of(context)!.allDonations,
                    color: Colors.purple,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DonationsHistoryPage(),
                        ),
                      );
                      _loadStats();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.remove_circle,
                    label: 'Expenses',
                    color: Colors.red,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExpensePage(),
                        ),
                      );
                      _loadStats();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long,
                    label: AppLocalizations.of(context)!.overallCollection,
                    color: Colors.blue,
                    onTap: () {
                      _showOverallStats();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Donations
              Text(
                AppLocalizations.of(context)!.recentTransactions,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildRecentDonations(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    final today = stats?['today'];
    if (today == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(AppLocalizations.of(context)!.noInfoAvailable),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context)!.todayDonations,
                today['count'].toString(),
                Icons.receipt,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context)!.todayAmount,
                '₹${NumberFormat('#,##,###').format(_toDouble(today['total_amount']))}',
                Icons.currency_rupee,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'UPI',
                '₹${NumberFormat('#,##,###').format(_toDouble(today['upi_amount']))}',
                Icons.qr_code,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context)!.cashPayment,
                '₹${NumberFormat('#,##,###').format(_toDouble(today['cash_amount']))}',
                Icons.money,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Cheque',
                '₹${NumberFormat('#,##,###').format(_toDouble(today['cheque_amount']))}',
                Icons.account_balance,
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Today Expenses',
                '₹${NumberFormat('#,##,###').format(_toDouble(today['expense_amount']))}',
                Icons.remove_circle,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Overall Balance',
                '₹${NumberFormat('#,##,###').format(_toDouble(stats?['overall']?['net_amount'] ?? 0))}',
                Icons.account_balance_wallet,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDonations() {
    if (recentDonations == null || recentDonations!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text(AppLocalizations.of(context)!.noDonationsYet)),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentDonations!.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final donation = recentDonations![index];
          
          // Parse created_at - handle various date formats
          DateTime? createdAt;
          try {
            if (donation['created_at'] is String) {
              createdAt = DateTime.parse(donation['created_at']);
            }
          } catch (e) {
            // If parsing fails, use current time
            createdAt = DateTime.now();
          }
          
          final timeStr = createdAt != null 
              ? DateFormat('hh:mm a').format(createdAt)
              : '';
          
          final paymentStatus = donation['payment_status'] ?? 'PAID';
          final isPending = paymentStatus == 'PENDING';
          final isCancelled = paymentStatus == 'CANCELLED';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '$timeStr${donation['receipt_no'] != null ? ' • ${donation['receipt_no']}' : ''}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            Text(
                              '${AppLocalizations.of(context)!.collectorLabel}: ${donation['collector_name'] ?? 'Unknown'}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${NumberFormat('#,##,###').format(_toDouble(donation['amount']))}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCancelled ? Colors.grey : Colors.green,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (isCancelled || isPending) ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReceiptPage(
                                  receiptNo: donation['receipt_no'] ?? '',
                                  donorName: donation['donor_name'] ?? 'Anonymous',
                                  donorPhone: donation['donor_phone'],
                                  donorAddress: donation['donor_address'],
                                  donorPan: donation['donor_pan'],
                                  amount: _toDouble(donation['amount']),
                                  method: donation['method'] ?? 'CASH',
                                  dateTime: createdAt ?? DateTime.now(),
                                  paymentStatus: paymentStatus,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: Text(AppLocalizations.of(context)!.viewReceipt, style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: (isCancelled || isPending) ? Colors.grey : Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (isCancelled || isPending) ? null : () async {
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
                                  amount: _toDouble(donation['amount']),
                                  method: donation['method'] ?? 'CASH',
                                  dateTime: createdAt ?? DateTime.now(),
                                  paymentStatus: paymentStatus,
                                  autoPrint: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.print, size: 16),
                          label: Text(AppLocalizations.of(context)!.printReceipt, style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (isCancelled || isPending) ? Colors.grey : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOverallStats() {
    final overall = stats?['overall'];
    if (overall == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.overallCollection),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogStat(AppLocalizations.of(context)!.totalDonationsCount, overall['count'].toString()),
            const SizedBox(height: 12),
            _buildDialogStat(
              AppLocalizations.of(context)!.totalAmountValue,
              '₹${NumberFormat('#,##,###').format(_toDouble(overall['amount']))}',
            ),
            const SizedBox(height: 12),
            _buildDialogStat(
              'Total Expenses',
              '₹${NumberFormat('#,##,###').format(_toDouble(overall['expense_amount']))}',
            ),
            const Divider(height: 24),
            _buildDialogStat(
              'Overall Balance',
              '₹${NumberFormat('#,##,###').format(_toDouble(overall['net_amount']))}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.closeButton),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
