import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/api_client.dart';

class BulkDonationPage extends StatefulWidget {
  const BulkDonationPage({super.key});

  @override
  State<BulkDonationPage> createState() => _BulkDonationPageState();
}

class _BulkDonationPageState extends State<BulkDonationPage> {
  final _formKey = GlobalKey<FormState>();
  final List<DonationEntry> _donations = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _addDonationRow();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiClient.dio.get('/categories');
      if (response.data['success'] == true) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response.data['categories']);
        });
      }
    } catch (e) {
      // Use default categories if API fails
      setState(() {
        _categories = [
          {'name': 'GENERAL'},
          {'name': 'PRASAD'},
          {'name': 'DECORATION'},
        ];
      });
    }
  }

  void _addDonationRow() {
    setState(() {
      _donations.add(DonationEntry(
        category: _categories.isNotEmpty ? _categories.first['name'] as String : 'GENERAL',
      ));
    });
  }

  void _removeDonationRow(int index) {
    setState(() {
      _donations.removeAt(index);
    });
  }

  Future<void> _submitBulkDonations() async {
    if (!_formKey.currentState!.validate()) return;

    if (_donations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseAddAtLeastOneDonation)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final donationsList = _donations.map((d) => {
        'donor_name': d.nameController.text.trim(),
        'donor_phone': d.phoneController.text.trim(),
        'amount': double.parse(d.amountController.text),
        'method': d.paymentMethod,
        'category': d.category,
        'is_recurring_donor': d.isRecurringDonor,
        'additional_notes': d.notesController.text.trim(),
      }).toList();

      final response = await ApiClient.dio.post(
        '/donations/bulk',
        data: {'donations': donationsList},
      );

      if (!mounted) return;

      if (response.data['success'] == true) {
        final created = response.data['created'] as int;
        final failed = response.data['failed'] as int;
        
        String message = '${AppLocalizations.of(context)!.successfullyAdded}: $created ${AppLocalizations.of(context)!.donationsCountFormat}';
        if (failed > 0) {
          message += ', ${AppLocalizations.of(context)!.failedCount}: $failed';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: failed > 0 ? Colors.orange : Colors.green,
          ),
        );

        if (failed == 0) {
          Navigator.pop(context, true);
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bulkDonationEntry),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isLoading ? null : _addDonationRow,
            tooltip: AppLocalizations.of(context)!.addNewDonation,
          ),
        ],
      ),
      body: _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _donations.length,
                      itemBuilder: (context, index) {
                        return _buildDonationCard(index);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'एकूण देणग्या: ${_donations.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitBulkDonations,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(AppLocalizations.of(context)!.saveAllDonations),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDonationCard(int index) {
    final donation = _donations[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.donationNumberFormat} #${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_donations.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _isLoading ? null : () => _removeDonationRow(index),
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            TextFormField(
              controller: donation.nameController,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.donorName} *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.nameIsRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: donation.phoneController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.phoneNumber,
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: donation.amountController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.amountRupeesRequired,
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'आवश्यक';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return AppLocalizations.of(context)!.validAmount;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: donation.category,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.typeLabel,
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat['name'] as String,
                        child: Text(cat['name'] as String),
                      );
                    }).toList(),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              donation.category = value!;
                            });
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: donation.paymentMethod,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.paymentMethodRequired,
                prefixIcon: Icon(Icons.payment),
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(value: 'CASH', child: Text(AppLocalizations.of(context)!.cash)),
                const DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
              ],
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        donation.paymentMethod = value!;
                      });
                    },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: Text(AppLocalizations.of(context)!.recurringDonor),
              value: donation.isRecurringDonor,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        donation.isRecurringDonor = value ?? false;
                      });
                    },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            TextFormField(
              controller: donation.notesController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.notes,
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              enabled: !_isLoading,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var donation in _donations) {
      donation.dispose();
    }
    super.dispose();
  }
}

class DonationEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String paymentMethod = 'CASH';
  String category;
  bool isRecurringDonor = false;

  DonationEntry({required this.category});

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    amountController.dispose();
    notesController.dispose();
  }
}
