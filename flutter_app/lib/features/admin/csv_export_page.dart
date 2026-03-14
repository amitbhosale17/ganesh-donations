import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../services/export_service.dart';
import 'dart:io' show Platform;

class CsvExportPage extends StatefulWidget {
  const CsvExportPage({super.key});

  @override
  State<CsvExportPage> createState() => _CsvExportPageState();
}

class _CsvExportPageState extends State<CsvExportPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedMethod;
  bool _isExporting = false;

  final List<String> _paymentMethods = ['UPI', 'CASH', 'CHEQUE'];

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Build query parameters
      final startDateStr = _startDate?.toIso8601String().split('T')[0];
      final endDateStr = _endDate?.toIso8601String().split('T')[0];

      // Use the new export service
      final result = await ExportService.exportDonationsToCSV(
        startDate: startDateStr,
        endDate: endDateStr,
        method: _selectedMethod,
      );

      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        if (result['success'] == true) {
          final filePath = result['filePath'];
          final fileName = result['fileName'];

          // Show success dialog with file location
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.csvDownloadSuccess),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'File saved to:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      filePath,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You can find this file in your Downloads folder.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
                if (Platform.isAndroid || Platform.isIOS)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await OpenFile.open(filePath);
                      if (result.type != ResultType.done && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not open file: ${result.message}')),
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('OPEN FILE'),
                  ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: ${result['error'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedMethod = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.csvExport),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.filters,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_startDate != null || _endDate != null || _selectedMethod != null)
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear, size: 18),
                            label: Text(AppLocalizations.of(context)!.clearFilters),
                          ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Date Range
                    Text(
                      AppLocalizations.of(context)!.dateRange,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.startDate,
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _startDate != null
                                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                    : AppLocalizations.of(context)!.selectDate,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.endDate,
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _endDate != null
                                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                    : AppLocalizations.of(context)!.selectDate,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Method
                    Text(
                      AppLocalizations.of(context)!.paymentMethod,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: AppLocalizations.of(context)!.all,
                      ),
                      value: _selectedMethod,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(AppLocalizations.of(context)!.all),
                        ),
                        ..._paymentMethods.map((method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedMethod = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Export Button
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportCsv,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(
                _isExporting
                    ? AppLocalizations.of(context)!.exporting
                    : AppLocalizations.of(context)!.exportCsv,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            
            // Info Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.csvExportInfo,
                      style: TextStyle(color: Colors.blue.shade900),
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
}
