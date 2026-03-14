import 'package:flutter/material.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../login/login_page.dart';
import 'settings_page.dart';
import 'donations_view.dart';
import 'user_management_page.dart';
import 'reports_page.dart';
import 'bulk_donation_page.dart';
import 'donor_search_page.dart';
import 'pending_payments_page.dart';
import 'csv_export_page.dart';
import 'yearly_dashboard_page.dart';
import '../expenses/expense_page.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final user = AuthService.getCurrentUser();
  final tenant = AuthService.getCurrentTenant();

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
        title: Text(tenant?['name'] ?? 'Organization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: AppLocalizations.of(context)!.logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.adminPanel,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${AppLocalizations.of(context)!.hello}, ${user?['name'] ?? 'Admin'}!',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    label: AppLocalizations.of(context)!.mandalSettings,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long,
                    label: AppLocalizations.of(context)!.viewAllDonations,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DonationsView()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.people,
                    label: AppLocalizations.of(context)!.userManagement,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserManagementPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bar_chart,
                    label: AppLocalizations.of(context)!.reportsAndStats,
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.analytics,
                    label: 'Yearly Dashboard',
                    color: Colors.amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const YearlyDashboardPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.playlist_add,
                    label: AppLocalizations.of(context)!.bulkDonationEntry,
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BulkDonationPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_search,
                    label: AppLocalizations.of(context)!.searchDonorMenu,
                    color: Colors.cyan,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DonorSearchPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.pending_actions,
                    label: AppLocalizations.of(context)!.pendingPaymentsMenu,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PendingPaymentsPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.remove_circle,
                    label: 'Expenses',
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExpensePage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.file_download,
                    label: AppLocalizations.of(context)!.csvExport,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CsvExportPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.upload,
                    label: AppLocalizations.of(context)!.logoQrUpload,
                    color: Colors.orange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.comingSoon)),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.print,
                    label: AppLocalizations.of(context)!.printerTest,
                    color: Colors.indigo,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.comingSoon)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                  fontSize: 14,
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
