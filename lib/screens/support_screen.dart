import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/premium_widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _category = 'Academic';
  String _description = "";
  bool _isLoading = false;
  String? _error;
  List<dynamic> _tickets = [];

  final List<String> _categories = [
    'Academic',
    'Administrative',
    'Infrastructure',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentStudent?.userId == null) return;
    
    try {
      final api = ApiService();
      final token = auth.token ?? "";
      final res = await api.getRequest('/api/student/complaints?studentId=${auth.currentStudent!.userId}', token);
      if (res is List) {
        setState(() => _tickets = res);
      }
    } catch (e) {
      debugPrint("Error fetching tickets: $e");
    }
  }

  Future<void> _submitTicket() async {
    if (_description.trim().isEmpty) {
      setState(() => _error = "Please describe your issue.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final api = ApiService();
      final response = await api.postRequest('/api/student/complaints', {
        "studentId": auth.currentStudent?.userId,
        "studentName": auth.currentStudent?.name,
        "classId": auth.currentStudent?.classId,
        "category": _category,
        "description": _description,
      }, auth.token ?? "");

      if (response != null && !response.containsKey('error')) {
        setState(() {
          _description = "";
          _tickets.insert(0, response);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Ticket created successfully!"),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        setState(() => _error = response?['error'] ?? "Failed to submit ticket");
      }
    } catch (e) {
      setState(() => _error = "An unexpected error occurred.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBrandHeader(wingMode: auth.activeWingMode),
            const SizedBox(height: 4),
            Text(
              'Help & Complain',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textBase,
              ),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: null,
        elevation: 0,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textBase,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Submission Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("LODGE A COMPLAINT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Describe your issue in detail...",
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 5,
                    onChanged: (val) => _description = val,
                  ),
                  
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Submit Ticket", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text("PREVIOUS TICKETS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            
            if (_tickets.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text("No tickets found.", style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            else
              ..._tickets.map((t) => _buildTicketCard(t)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final isResolved = ticket['status'] == 'Resolved';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isResolved ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isResolved ? Icons.check_circle : Icons.access_time,
              color: isResolved ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${ticket['category']} Issue", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      ticket['status'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isResolved ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(ticket['description'], style: TextStyle(color: AppTheme.textBase, fontSize: 13)),
                if (ticket['adminReply'] != null && (ticket['adminReply'] as String).isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("MANAGEMENT REPLY", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(ticket['adminReply'], style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textBase)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  DateTime.fromMillisecondsSinceEpoch(ticket['createdAt']).toString().split(' ')[0],
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
