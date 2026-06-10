import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/academic_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

class FeesScreen extends StatelessWidget {
  const FeesScreen({super.key});

  // Data Framework matching Admin Portal
  static const schoolMonths = [
    {'label': "April", 'code': "2026-04"},
    {'label': "May", 'code': "2026-05"},
    {'label': "June", 'code': "2026-06"},
    {'label': "July", 'code': "2026-07"},
    {'label': "August", 'code': "2026-08"},
    {'label': "September", 'code': "2026-09"},
    {'label': "October", 'code': "2026-10"},
    {'label': "November", 'code': "2026-11"},
    {'label': "December", 'code': "2026-12"},
    {'label': "January", 'code': "2027-01"},
    {'label': "February", 'code': "2027-02"},
    {'label': "March", 'code': "2027-03"},
  ];

  static const coachingInstallments = [
    {'label': "Installment 1", 'code': "inst-1"},
    {'label': "Installment 2", 'code': "inst-2"},
    {'label': "Installment 3", 'code': "inst-3"},
    {'label': "Extra / Delay", 'code': "inst-4"},
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final fees = academic.fees;

    final isCoaching = auth.currentStudent?.wing == 'coaching';
    final slots = isCoaching ? coachingInstallments : schoolMonths;

    final totalPaid = fees.where((f) => f.status.toLowerCase() == 'paid').fold(0.0, (sum, item) => sum + item.amount);
    final totalDue = fees.where((f) => f.status.toLowerCase() != 'paid').fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Fee Management'),
        elevation: 0,
        backgroundColor: AppTheme.surface,
      ),
      body: Column(
        children: [
          // Summary Header
          FadeInAnimation(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCoaching ? [Colors.blue.shade600, Colors.blue.shade900] : [Colors.green.shade600, Colors.green.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: (isCoaching ? Colors.blue : Colors.green).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isCoaching ? 'COACHING INSTALLMENTS' : 'SCHOOL ACADEMIC SESSION', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
color: AppTheme.surface.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text('${auth.currentStudent?.wing?.toUpperCase() ?? "N/A"} • ${auth.currentStudent?.id.substring(auth.currentStudent!.id.length - 4)}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Master Ledger Stats Row
                  Row(
                    children: [
                      _LedgerHeaderItem(label: 'TOTAL QUOTA', value: academic.totalFee ?? auth.currentStudent?.totalFee ?? 0),
                      _VerticalDivider(),
                      _LedgerHeaderItem(label: 'TOTAL PAID', value: totalPaid),
                      _VerticalDivider(),
                      _LedgerHeaderItem(label: 'NET BALANCE', value: (academic.totalFee ?? auth.currentStudent?.totalFee ?? 0) - totalPaid),
                    ],
                  ),
                  if (totalDue > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
color: AppTheme.surface.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amberAccent, size: 14),
                          const SizedBox(width: 8),
                          Text('MONTHLY DUES PENDING: ₹${totalDue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          Expanded(
            child: academic.isLoading && fees.isEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 5,
                  itemBuilder: (context, index) => const _FeeShimmer(),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await context.read<AcademicProvider>().refreshWithLastParams();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final feeData = fees.cast<dynamic>().firstWhere(
                        (f) => f.month == slot['code'],
                        orElse: () => null,
                      );

                      return FadeInAnimation(
                        delay: index * 50,
                        child: _FeeSlotItem(
                          label: slot['label']!,
                          code: slot['code']!,
                          fee: feeData,
                        ),
                      );
                    },
                  ),
                ),
            ),
          ],
        ),
      );
    }
  }

class _FeeSlotItem extends StatelessWidget {
  final String label;
  final String code;
  final dynamic fee;

  const _FeeSlotItem({required this.label, required this.code, this.fee});

  @override
  Widget build(BuildContext context) {
    final isPaid = fee != null && fee.status.toLowerCase() == 'paid';
    final hasAmount = fee != null && fee.amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.withOpacity(0.02) : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPaid ? Colors.green.withOpacity(0.2) : AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPaid ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPaid ? LucideIcons.checkCircle : LucideIcons.alertCircle,
              color: isPaid ? Colors.green : Colors.orange,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  isPaid 
                    ? 'Paid on ${fee.paidDate ?? "N/A"}' 
                    : hasAmount 
                      ? '₹${fee.amount.toStringAsFixed(0)} Due since ${fee.dueDate ?? "N/A"}'
                      : 'Pending for deposit',
                  style: TextStyle(fontSize: 11, color: isPaid ? Colors.green : AppTheme.textMuted),
                ),
              ],
            ),
          ),
          if (isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
              child: Text('₹${fee.amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
            )
          else if (hasAmount)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: Colors.red.withOpacity(0.3)), borderRadius: BorderRadius.circular(10)),
              child: Text('₹${fee.amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 12)),
            )
          else
            Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _LedgerHeaderItem extends StatelessWidget {
  final String label; final double value;
  const _LedgerHeaderItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text('₹${value.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 24, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 12));
  }
}

class _FeeShimmer extends StatelessWidget {
  const _FeeShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: const [
          ShimmerLoading(width: 38, height: 38, borderRadius: 14),
          SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ShimmerLoading(width: 80, height: 14), SizedBox(height: 6), ShimmerLoading(width: 120, height: 10)])),
          ShimmerLoading(width: 50, height: 24),
        ],
      ),
    );
  }
}
