import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/event_service.dart';

class OrganizationEventsPage extends StatefulWidget {
  const OrganizationEventsPage({Key? key}) : super(key: key);

  @override
  State<OrganizationEventsPage> createState() => _OrganizationEventsPageState();
}

class _OrganizationEventsPageState extends State<OrganizationEventsPage> {
  final _eventService = EventService();
  
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _eventTypes = [];
  bool _isLoading = true;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final events = await _eventService.getOrganizationEvents(year: _selectedYear);
      final eventTypes = await _eventService.getEventTypes();
      
      setState(() {
        _events = events;
        _eventTypes = eventTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  void _showCreateEventDialog() {
    int? selectedEventTypeId;
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final targetAmountController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedEventTypeId,
                  items: _eventTypes.map((type) {
                    return DropdownMenuItem<int>(
                      value: type['id'],
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: _parseColor(type['color']),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(child: Text(type['name'])),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedEventTypeId = value);
                  },
                ),
                const SizedBox(height: 16),
                
                // Start Date
                TextFormField(
                  controller: startDateController,
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime(_selectedYear!),
                          firstDate: DateTime(_selectedYear!),
                          lastDate: DateTime(_selectedYear!, 12, 31),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
                            startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                
                // End Date
                TextFormField(
                  controller: endDateController,
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? startDate ?? DateTime(_selectedYear!),
                          firstDate: startDate ?? DateTime(_selectedYear!),
                          lastDate: DateTime(_selectedYear!, 12, 31),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endDate = picked;
                            endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                
                // Target Amount
                TextField(
                  controller: targetAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (Optional)',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedEventTypeId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an event type')),
                  );
                  return;
                }
                
                if (startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select start and end dates')),
                  );
                  return;
                }

                try {
                  await _eventService.createOrganizationEvent(
                    eventTypeId: selectedEventTypeId!,
                    eventYear: _selectedYear!,
                    startDate: DateFormat('yyyy-MM-dd').format(startDate!),
                    endDate: DateFormat('yyyy-MM-dd').format(endDate!),
                    targetAmount: targetAmountController.text.isNotEmpty
                        ? double.parse(targetAmountController.text)
                        : null,
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event created successfully')),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.grey;
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Events'),
        actions: [
          // Year Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<int>(
              value: _selectedYear,
              dropdownColor: Colors.deepPurple,
              style: const TextStyle(color: Colors.white),
              underline: Container(),
              items: List.generate(5, (index) {
                final year = DateTime.now().year - 2 + index;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (year) {
                setState(() => _selectedYear = year);
                _loadData();
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No events for $_selectedYear',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create an event',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        final eventType = event['event_type'] ?? {};
                        final progress = event['progress_percentage'] ?? 0.0;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _parseColor(eventType['color']),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        eventType['name'] ?? 'Unknown Event',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        event['is_active'] == true ? 'Active' : 'Inactive',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: event['is_active'] == true
                                          ? Colors.green[100]
                                          : Colors.grey[300],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Date Range
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${event['start_date']} to ${event['end_date']}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Stats
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn(
                                      'Donations',
                                      event['donation_count']?.toString() ?? '0',
                                      Icons.volunteer_activism,
                                    ),
                                    _buildStatColumn(
                                      'Collected',
                                      '₹${NumberFormat('#,##,###').format(event['collected_amount'] ?? 0)}',
                                      Icons.payments,
                                    ),
                                    if (event['target_amount'] != null)
                                      _buildStatColumn(
                                        'Target',
                                        '₹${NumberFormat('#,##,###').format(event['target_amount'])}',
                                        Icons.flag,
                                      ),
                                  ],
                                ),
                                
                                // Progress Bar
                                if (event['target_amount'] != null && event['target_amount'] > 0) ...[
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress / 100,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _parseColor(eventType['color']),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${progress.toStringAsFixed(1)}% of target',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
