import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../login/login_page.dart';
import 'tenant_users_page.dart';
import 'tenant_donations_page.dart';

class SuperAdminHome extends StatefulWidget {
  const SuperAdminHome({super.key});

  @override
  State<SuperAdminHome> createState() => _SuperAdminHomeState();
}

class _SuperAdminHomeState extends State<SuperAdminHome> {
  List<dynamic> _tenants = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _searchQuery;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        ApiClient.dio.get('/superadmin/tenants'),
        ApiClient.dio.get('/superadmin/stats'),
      ]);

      setState(() {
        _tenants = responses[0].data;
        _stats = responses[1].data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
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

  Future<void> _showCreateTenantDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final prefixController = TextEditingController();
    final presidentController = TextEditingController();
    final regNoController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Mandal'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: nameController,
                  label: 'Mandal Name *',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: addressController,
                  label: 'Address *',
                  maxLines: 2,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: phoneController,
                  label: 'Contact Phone',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: prefixController,
                  label: 'Receipt Prefix *',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: presidentController,
                  label: 'President Name',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: regNoController,
                  label: 'Registration No',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ApiClient.dio.post('/superadmin/tenants', data: {
          'name': nameController.text,
          'address': addressController.text,
          'contact_phone': phoneController.text,
          'receipt_prefix': prefixController.text.toUpperCase(),
          'president_name': presidentController.text,
          'registration_no': regNoController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mandal created successfully!')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create mandal: $e')),
          );
        }
      }
    }

    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    prefixController.dispose();
    presidentController.dispose();
    regNoController.dispose();
  }

  Future<void> _showEditTenantDialog(Map<String, dynamic> tenant) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: tenant['name']);
    final addressController = TextEditingController(text: tenant['address']);
    final phoneController = TextEditingController(text: tenant['contact_phone'] ?? '');
    final prefixController = TextEditingController(text: tenant['receipt_prefix']);
    final presidentController = TextEditingController(text: tenant['president_name'] ?? '');
    final vicePresidentController = TextEditingController(text: tenant['vice_president_name'] ?? '');
    final secretaryController = TextEditingController(text: tenant['secretary_name'] ?? '');
    final treasurerController = TextEditingController(text: tenant['treasurer_name'] ?? '');
    final regNoController = TextEditingController(text: tenant['registration_no'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Mandal'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: nameController,
                  label: 'Mandal Name *',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: addressController,
                  label: 'Address *',
                  maxLines: 2,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: phoneController,
                  label: 'Contact Phone',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: prefixController,
                  label: 'Receipt Prefix *',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: presidentController,
                  label: 'President Name',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: vicePresidentController,
                  label: 'Vice President Name',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: secretaryController,
                  label: 'Secretary Name',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: treasurerController,
                  label: 'Treasurer Name',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: regNoController,
                  label: 'Registration No',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ApiClient.dio.put('/superadmin/tenants/${tenant['id']}', data: {
          'name': nameController.text,
          'address': addressController.text,
          'contact_phone': phoneController.text,
          'receipt_prefix': prefixController.text.toUpperCase(),
          'president_name': presidentController.text,
          'vice_president_name': vicePresidentController.text,
          'secretary_name': secretaryController.text,
          'treasurer_name': treasurerController.text,
          'registration_no': regNoController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mandal updated successfully!')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update mandal: $e')),
          );
        }
      }
    }

    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    prefixController.dispose();
    presidentController.dispose();
    vicePresidentController.dispose();
    secretaryController.dispose();
    treasurerController.dispose();
    regNoController.dispose();
  }

  Future<void> _toggleTenantStatus(Map<String, dynamic> tenant) async {
    final currentStatus = tenant['status'] ?? 'ACTIVE';
    final newStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final action = newStatus == 'ACTIVE' ? 'activate' : 'deactivate';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.toUpperCase()} Mandal?'),
        content: Text('Are you sure you want to $action ${tenant['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'ACTIVE' ? Colors.green : Colors.red,
            ),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (newStatus == 'INACTIVE') {
          await ApiClient.dio.delete('/superadmin/tenants/${tenant['id']}');
        } else {
          await ApiClient.dio.put('/superadmin/tenants/${tenant['id']}', data: {
            'status': 'ACTIVE',
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mandal ${action}d successfully!')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to $action mandal: $e')),
          );
        }
      }
    }
  }

  Future<void> _showCreateAdminDialog(int tenantId, String tenantName) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: 'Admin');
    final phoneController = TextEditingController();
    final passwordController = TextEditingController(text: 'Admin@123');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Admin for $tenantName'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: nameController,
                label: 'Name *',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: phoneController,
                label: 'Phone *',
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: passwordController,
                label: 'Password *',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create Admin'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ApiClient.dio.post('/superadmin/tenants/$tenantId/users', data: {
          'name': nameController.text,
          'phone': phoneController.text,
          'role': 'ADMIN',
          'password': passwordController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Admin created!\nPhone: ${phoneController.text}\nPassword: ${passwordController.text}',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create admin: $e')),
          );
        }
      }
    }

    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
  }

  List<dynamic> get _filteredTenants {
    var filtered = _tenants;

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered = filtered.where((t) {
        final name = (t['name'] ?? '').toString().toLowerCase();
        final prefix = (t['receipt_prefix'] ?? '').toString().toLowerCase();
        final address = (t['address'] ?? '').toString().toLowerCase();
        final query = _searchQuery!.toLowerCase();
        return name.contains(query) || prefix.contains(query) || address.contains(query);
      }).toList();
    }

    if (_statusFilter != null) {
      filtered = filtered.where((t) => (t['status'] ?? 'ACTIVE') == _statusFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredTenants;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 SuperAdmin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Mandals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showCreateTenantDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('New Mandal'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 16),
                  if (filteredList.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No mandals found'),
                      ),
                    )
                  else
                    ...filteredList.map((tenant) => _buildTenantCard(tenant)),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search mandals by name, prefix, or address...',
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: InputDecoration(
                  labelText: 'Status Filter',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Mandals')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active Only')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive Only')),
                ],
                onChanged: (value) {
                  setState(() => _statusFilter = value);
                },
              ),
            ),
            if (_searchQuery != null || _statusFilter != null) ...[
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = null;
                    _statusFilter = null;
                  });
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Mandals',
                  _stats!['total_tenants'].toString(),
                  Icons.temple_hindu,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Users',
                  _stats!['total_users'].toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Donations',
                  _stats!['total_donations'].toString(),
                  Icons.volunteer_activism,
                  Colors.green,
                ),
                _buildStatItem(
                  'Total Amount',
                  '₹${_formatAmount(_stats!['total_amount'])}',
                  Icons.currency_rupee,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    final status = tenant['status'] ?? 'ACTIVE';
    final isActive = status == 'ACTIVE';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isActive ? null : Colors.grey.shade100,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.orange : Colors.grey,
          child: Text(
            tenant['receipt_prefix'] ?? '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                tenant['name'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black : Colors.grey,
                ),
              ),
            ),
            _buildBadge(status, isActive ? Colors.green : Colors.grey),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tenant['address'] ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip('${tenant['user_count']} users', Colors.blue),
                const SizedBox(width: 8),
                _buildChip('${tenant['donation_count']} donations', Colors.green),
                const SizedBox(width: 8),
                _buildChip('₹${_formatAmount(tenant['total_amount'])}', Colors.purple),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tenant['president_name'] != null)
                  Text('President: ${tenant['president_name']}'),
                if (tenant['registration_no'] != null)
                  Text('Reg No: ${tenant['registration_no']}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showEditTenantDialog(tenant),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _toggleTenantStatus(tenant),
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        size: 16,
                      ),
                      label: Text(isActive ? 'Deactivate' : 'Activate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isActive ? Colors.red : Colors.green,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateAdminDialog(
                        tenant['id'],
                        tenant['name'],
                      ),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Admin'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TenantUsersPage(
                              tenantId: tenant['id'],
                              tenantName: tenant['name'],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people, size: 16),
                      label: const Text('View Users'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TenantDonationsPage(
                              tenantId: tenant['id'],
                              tenantName: tenant['name'],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt, size: 16),
                      label: const Text('Donations'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
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
