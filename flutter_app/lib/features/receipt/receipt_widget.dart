import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptWidget extends StatelessWidget {
  final String orgName;
  final String? orgAddress;
  final String receiptNo;
  final DateTime dateTime;
  final String donorName;
  final String? donorPhone;
  final String? donorAddress;
  final String? donorPan;
  final double amount;
  final String method;
  final List<String> footerLines;

  const ReceiptWidget({
    super.key,
    required this.orgName,
    this.orgAddress,
    required this.receiptNo,
    required this.dateTime,
    required this.donorName,
    this.donorPhone,
    this.donorAddress,
    this.donorPan,
    required this.amount,
    required this.method,
    required this.footerLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          const Text(
            '🕉️',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            orgName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (orgAddress != null && orgAddress!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              orgAddress!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Receipt details
          _buildRow('पावती क्र.:', receiptNo),
          const SizedBox(height: 8),
          _buildRow(
            'तारीख:',
            DateFormat('dd MMM yyyy, HH:mm').format(dateTime),
          ),
          
          const SizedBox(height: 8),
          _buildRow('देणगीदार:', donorName),
          
          if (donorPhone != null && donorPhone!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRow('फोन:', donorPhone!),
          ],
          
          if (donorAddress != null && donorAddress!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRow('पत्ता:', donorAddress!),
          ],
          
          if (donorPan != null && donorPan!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRow('PAN:', donorPan!),
          ],
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Amount
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'रक्कम:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          _buildRow('पद्धत:', method == 'UPI' ? 'UPI पेमेंट' : 'रोख'),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Footer
          ...footerLines.map(
            (line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
