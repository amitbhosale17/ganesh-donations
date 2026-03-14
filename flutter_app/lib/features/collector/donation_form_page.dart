import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../l10n/app_localizations.dart';
import '../../core/api_client.dart';
import '../../data/app_db.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'upi_qr_screen.dart';
import '../receipt/receipt_page.dart';

class DonationFormPage extends StatefulWidget {
  const DonationFormPage({super.key});

  @override
  State<DonationFormPage> createState() => _DonationFormPageState();
}

class _DonationFormPageState extends State<DonationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _donorNameController = TextEditingController();
  final _donorPhoneController = TextEditingController();
  final _donorAddressController = TextEditingController();
  final _donorPanController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _paymentMethod = 'UPI';
  String _category = 'GENERAL';
  bool _isRecurringDonor = false;
  String _paymentStatus = 'PAID'; // PAID or PENDING
  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiClient.dio.get('/categories');
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response.data);
        if (_categories.isNotEmpty) {
          _category = _categories.first['name'];
        }
      });
    } catch (e) {
      print('Error loading categories: $e');
      // Use default categories if API fails
      setState(() {
        _categories = [
          {'name': 'GENERAL', 'description': AppLocalizations.of(context)!.categoryGeneral},
          {'name': 'OFFERING', 'description': AppLocalizations.of(context)!.categoryPrasad},
          {'name': 'DECORATION', 'description': AppLocalizations.of(context)!.categoryDecoration},
        ];
      });
    }
  }

  @override
  void dispose() {
    _donorNameController.dispose();
    _donorPhoneController.dispose();
    _donorAddressController.dispose();
    _donorPanController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.pleaseEnterDonorName;
    }
    return null;
  }

  String? _validateAmount(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.invalidAmount;
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return l10n.amountGreaterThanZero;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value != null && value.trim().isNotEmpty) {
      if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
        return l10n.invalidPhoneNumber;
      }
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation: PAID donations require payment method confirmation
    if (_paymentStatus == 'PAID' && _paymentMethod == 'UPI') {
      await _handleUpiPayment();
    } else if (_paymentStatus == 'PAID' && _paymentMethod == 'CASH') {
      // Show confirmation dialog for cash payment
      final confirmed = await _confirmCashPayment();
      if (confirmed) {
        await _submitDonation();
      }
    } else if (_paymentStatus == 'PAID' && _paymentMethod == 'CHEQUE') {
      // Show confirmation dialog for cheque payment
      final confirmed = await _confirmChequePayment();
      if (confirmed) {
        await _submitDonation();
      }
    } else if (_paymentStatus == 'PENDING') {
      // PENDING donations don't need payment confirmation
      await _submitDonation();
    } else {
      await _submitDonation();
    }
  }

  Future<bool> _confirmCashPayment() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmPayment),
        content: Text(
          '${AppLocalizations.of(context)!.amountRupees}: ₹${_amountController.text}\n\n${AppLocalizations.of(context)!.confirmPayment}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _confirmChequePayment() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cheque'),
        content: Text(
          'Amount: ₹${_amountController.text}\n\nPlease confirm that the cheque has been received from the donor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cheque Received'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _handleUpiPayment() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UpiQrScreen(
          amount: double.parse(_amountController.text),
          donorName: _donorNameController.text.trim(),
        ),
      ),
    );

    if (result == true && mounted) {
      await _submitDonation();
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final donationData = {
      'donor_name': _donorNameController.text.trim(),
      'donor_phone': _donorPhoneController.text.trim(),
      'amount': double.parse(_amountController.text),
      'method': _paymentMethod,
      'notes': _notesController.text.trim(),
      'category': _category,
      'is_recurring_donor': _isRecurringDonor,
      'additional_notes': _notesController.text.trim(),
      'payment_status': _paymentStatus,
    };

    try {
      // Try online submission first
      final response = await ApiClient.dio.post(
        '/donations',
        data: donationData,
      );

      if (!mounted) return;

      // Navigate to receipt page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptPage(
            receiptNo: response.data['receipt_no'],
            donorName: donationData['donor_name'] as String,
            donorPhone: donationData['donor_phone'] as String,
            amount: donationData['amount'] as double,
            method: _paymentMethod,
            dateTime: DateTime.now(),
            paymentStatus: _paymentStatus, // Pass payment status
          ),
        ),
      );
    } on DioException catch (e) {
      // Offline mode - save locally
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        await _saveOfflineDonation(donationData);
      } else {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorLabel}: ${e.response?.data['error'] ?? AppLocalizations.of(context)!.somethingWentWrong}'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveOfflineDonation(Map<String, dynamic> donationData) async {
    final tempReceiptNo = 'TEMP-${DateTime.now().millisecondsSinceEpoch}';
    
    await AppDb.insertLocalDonation({
      'donor_name': donationData['donor_name'],
      'donor_phone': donationData['donor_phone'],
      'amount': donationData['amount'],
      'method': donationData['method'],
      'status': 'SUCCESS',
      'temp_receipt_no': tempReceiptNo,
      'notes': donationData['notes'],
      'created_at': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;

    // Navigate to receipt page with provisional number
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPage(
          receiptNo: tempReceiptNo,
          donorName: donationData['donor_name'] as String,
          donorPhone: donationData['donor_phone'] as String,
          amount: donationData['amount'] as double,
          method: _paymentMethod,
          dateTime: DateTime.now(),
          isProvisional: true,
          paymentStatus: _paymentStatus, // Pass payment status
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.newDonationTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.donorInformation,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _donorNameController,
                label: AppLocalizations.of(context)!.donorNameLabel,
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _donorPhoneController,
                label: AppLocalizations.of(context)!.phoneOptional,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.amountAndPaymentMethodSection,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: AppLocalizations.of(context)!.amountRupees,
                prefixIcon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterAmount;
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return AppLocalizations.of(context)!.enterValidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.donationType,
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
                          _category = value!;
                        });
                      },
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('UPI पेमेंट'),
                      subtitle: Text(_paymentStatus == 'PENDING' 
                        ? 'Payment method (optional for pending)'
                        : 'Google Pay / PhonePe / Paytm'),
                      value: 'UPI',
                      groupValue: _paymentMethod,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _paymentMethod = value!;
                              });
                            },
                    ),
                    RadioListTile<String>(
                      title: Text(AppLocalizations.of(context)!.cash),
                      subtitle: Text(_paymentStatus == 'PENDING'
                        ? 'Payment method (optional for pending)'
                        : AppLocalizations.of(context)!.cashInHand),
                      value: 'CASH',
                      groupValue: _paymentMethod,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _paymentMethod = value!;
                              });
                            },
                    ),
                    RadioListTile<String>(
                      title: const Text('Cheque'),
                      subtitle: Text(_paymentStatus == 'PENDING'
                        ? 'Payment method (optional for pending)'
                        : 'Cheque / DD payment'),
                      value: 'CHEQUE',
                      groupValue: _paymentMethod,
                      secondary: const Icon(Icons.account_balance, color: Colors.teal),
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _paymentMethod = value!;
                              });
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(AppLocalizations.of(context)!.recurringDonor),
                subtitle: Text(AppLocalizations.of(context)!.recurringDonorDescription),
                value: _isRecurringDonor,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _isRecurringDonor = value ?? false;
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(AppLocalizations.of(context)!.paymentReceivedLabel),
                      subtitle: Text(AppLocalizations.of(context)!.amountReceivedNow),
                      value: 'PAID',
                      groupValue: _paymentStatus,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _paymentStatus = value!;
                              });
                            },
                    ),
                    RadioListTile<String>(
                      title: Text(AppLocalizations.of(context)!.paymentPendingLabel),
                      subtitle: Text(AppLocalizations.of(context)!.amountLaterReceiptNow),
                      value: 'PENDING',
                      groupValue: _paymentStatus,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _paymentStatus = value!;
                              });
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _notesController,
                label: AppLocalizations.of(context)!.notesOptional,
                prefixIcon: Icons.note,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 24),
              if (_paymentStatus == 'PENDING')
                AppButton(
                  text: _isLoading 
                    ? AppLocalizations.of(context)!.savingLabel 
                    : 'Create Pending Donation',
                  onPressed: _isLoading ? null : _handleSubmit,
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                )
              else if (_paymentMethod == 'UPI')
                AppButton(
                  text: _isLoading ? AppLocalizations.of(context)!.processingLabel : AppLocalizations.of(context)!.showQRCode,
                  onPressed: _isLoading ? null : _handleSubmit,
                  icon: Icons.qr_code,
                  color: Colors.green,
                )
              else if (_paymentMethod == 'CHEQUE')
                AppButton(
                  text: _isLoading ? AppLocalizations.of(context)!.savingLabel : 'Accept Cheque',
                  onPressed: _isLoading ? null : _handleSubmit,
                  icon: Icons.account_balance,
                  color: Colors.teal,
                )
              else
                AppButton(
                  text: _isLoading ? AppLocalizations.of(context)!.savingLabel : AppLocalizations.of(context)!.acceptCash,
                  onPressed: _isLoading ? null : _handleSubmit,
                  icon: Icons.check_circle,
                  color: Colors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
