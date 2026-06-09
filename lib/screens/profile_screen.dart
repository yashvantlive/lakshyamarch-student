import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../providers/academic_provider.dart';
import '../models/student.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'login_screen.dart';
import 'fees_screen.dart';
import 'change_password_screen.dart';
import 'main_navigator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _showAccountSwitcher(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final academic = context.read<AcademicProvider>();
    final wingColor = AppTheme.getWingColor(auth.activeWingMode);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textBase, letterSpacing: -0.5)),
            const SizedBox(height: 20),
            
            // Siblings
            if (auth.allStudents.length > 1) ...[
              Text('Linked Students', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              ...auth.allStudents.map((s) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: auth.currentStudent?.id == s.id ? wingColor : AppTheme.background,
                  child: Icon(LucideIcons.user, color: auth.currentStudent?.id == s.id ? Colors.white : AppTheme.textMuted, size: 20),
                ),
                title: Text(s.name, style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textBase, fontSize: 15)),
                subtitle: Text('Class ${s.className} • Roll ${s.rollNo}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                trailing: auth.currentStudent?.id == s.id ? Icon(LucideIcons.checkCircle2, color: wingColor) : null,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  auth.switchStudent(s);
                  Navigator.pop(context);
                },
              )).toList(),
              const Divider(height: 24),
            ],

            // Saved Accounts
            Text('Saved Accounts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            ...auth.savedAccounts.map((acc) {
              final isCurrent = auth.user != null && acc['user']['uid'] == auth.user!['uid'];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: isCurrent ? wingColor.withOpacity(0.1) : AppTheme.background,
                  child: Icon(LucideIcons.smartphone, color: isCurrent ? wingColor : AppTheme.textMuted, size: 20),
                ),
                title: Text(acc['user']['name'] ?? 'Account', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textBase, fontSize: 15)),
                subtitle: Text(acc['user']['phone'] ?? 'Parent Account', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                trailing: isCurrent ? Icon(LucideIcons.checkCircle2, color: wingColor) : null,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  if (!isCurrent) {
                    academic.clear();
                    await auth.switchAccount(acc['user']['uid']);
                  }
                },
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
            // Add Account Button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(isAddAccountMode: true)));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.plus, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text('Add another account', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final student = auth.currentStudent;
    final wingColor = AppTheme.getWingColor(auth.activeWingMode);
    final wingGradient = AppTheme.getWingGradient(auth.activeWingMode);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCenteredAppBar(auth.activeWingMode),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildStaggered(0, _buildProfileHeaderCard(auth, wingColor, wingGradient)),
                    const SizedBox(height: 32),
                    _buildStaggered(1, _SectionHeader(title: 'Academic Details', icon: LucideIcons.graduationCap, wingColor: wingColor)),
                    const SizedBox(height: 16),
                    _buildStaggered(2, _buildAcademicInfoGrid(student, wingColor)),
                    const SizedBox(height: 32),
                    _buildStaggered(3, _SectionHeader(title: 'Admission Info', icon: LucideIcons.info, wingColor: wingColor)),
                    const SizedBox(height: 16),
                    _buildStaggered(4, _DetailCard(children: [
                      _DetailRow(label: 'Father\'s Name', value: student?.fatherName ?? 'N/A'),
                      _DetailRow(label: 'Parent Contact', value: student?.fatherPhone ?? 'N/A', isLink: true, wingColor: wingColor),
                      _DetailRow(label: 'Date of Birth', value: student?.dob ?? 'N/A'),
                      _DetailRow(label: 'Admission Date', value: student?.admissionDate ?? 'N/A', isLast: true),
                    ])),
                    const SizedBox(height: 32),
                    _buildStaggered(5, _SectionHeader(title: 'Preferences', icon: LucideIcons.settings, wingColor: wingColor)),
                    const SizedBox(height: 16),
                    _buildStaggered(6, _DetailCard(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.moon, size: 18, color: AppTheme.textMuted),
                              const SizedBox(width: 12),
                              Text(
                                'Dark Mode',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textBase,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: auth.isDarkMode,
                            activeColor: wingColor,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              auth.toggleTheme();
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.shieldCheck, size: 18, color: wingColor),
                                const SizedBox(width: 12),
                                Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textBase,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Icon(LucideIcons.chevronRight, size: 18, color: AppTheme.textMuted),
                          ],
                        ),
                      ),
                    ])),
                    const SizedBox(height: 32),
                    _buildStaggered(7, _SectionHeader(title: 'Finance Hub', icon: LucideIcons.wallet, wingColor: wingColor)),
                    const SizedBox(height: 16),
                    _buildStaggered(8, _FeeDueCard(academic: academic, wingColor: wingColor)),
                    const SizedBox(height: 40),
                    _buildStaggered(9, _buildLogoutButton(auth)),
                    const SizedBox(height: 24),
                    Text('LakshyaMarch Student • v1.5.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredAppBar(String? wingMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      child: Column(
        children: [
          AnimatedBrandHeader(wingMode: wingMode),
          const SizedBox(height: 8),
          Text('My Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBase)),
        ],
      ),
    );
  }

  Widget _buildStaggered(int index, Widget child) {
    final animation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval((index / 10).clamp(0, 0.5), 1.0, curve: Curves.easeOutQuart),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, 30 * (1 - animation.value)),
        child: Opacity(opacity: animation.value, child: child),
      ),
    );
  }

  Widget _buildProfileHeaderCard(AuthProvider auth, Color wingColor, LinearGradient wingGradient) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          _buildAvatarStack(auth, wingColor, wingGradient),
          const SizedBox(height: 20),
          Text(auth.user?['name'] ?? 'Student Name', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textBase, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          _buildStatusBadges(auth, wingColor),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(AuthProvider auth, Color wingColor, LinearGradient wingGradient) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: wingGradient),
          child: CircleAvatar(radius: 44, backgroundColor: AppTheme.surface, child: Icon(LucideIcons.user, size: 40, color: wingColor)),
        ),
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: () => _showAccountSwitcher(context),
            child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: wingColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(LucideIcons.refreshCw, size: 14, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadges(AuthProvider auth, Color wingColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Badge(label: auth.activeWingMode?.toUpperCase() ?? 'N/A', color: wingColor),
        const SizedBox(width: 10),
        _Badge(label: 'ACTIVE', color: AppTheme.success),
      ],
    );
  }

  Widget _buildAcademicInfoGrid(Student? student, Color wingColor) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _CompactInfo(label: 'Admission No', value: student?.admissionNo ?? '---', color: wingColor),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _CompactInfo(label: 'Class', value: student?.className ?? '---', color: wingColor)),
            const SizedBox(width: 12),
            Expanded(child: _CompactInfo(label: 'Roll No', value: student?.rollNo ?? '---', color: wingColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoutButton(AuthProvider auth) {
    return ElevatedButton.icon(
      onPressed: () async {
        HapticFeedback.heavyImpact();
        await auth.logout();
        if (auth.isAuthenticated) {
          // It just logged out of one account but switched to another
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => MainNavigator()), (route) => false);
        } else {
          // Completely logged out
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
        }
      },
      icon: const Icon(LucideIcons.logOut, size: 18),
      label: const Text('Logout Session', style: TextStyle(fontWeight: FontWeight.w900)),
      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger.withOpacity(0.08), foregroundColor: AppTheme.danger, elevation: 0, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title; final IconData icon; final Color wingColor;
  const _SectionHeader({required this.title, required this.icon, required this.wingColor});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 18, color: wingColor), const SizedBox(width: 10), Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textBase, letterSpacing: -0.3))]);
  }
}

class _CompactInfo extends StatelessWidget {
  final String label; final String value; final Color color;
  const _CompactInfo({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
color: AppTheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2)),
      child: Column(children: [Text(label.toUpperCase(), style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w900, letterSpacing: 0.5)), const SizedBox(height: 8), Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color))]),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
color: AppTheme.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2)), child: Column(children: children));
  }
}

class _DetailRow extends StatelessWidget {
  final String label; final String value; final bool isLink; final bool isLast; final Color? wingColor;
  const _DetailRow({required this.label, required this.value, this.isLink = false, this.isLast = false, this.wingColor});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: 14, color: AppTheme.textMuted, fontWeight: FontWeight.bold)), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isLink ? (wingColor ?? AppTheme.primary) : AppTheme.textBase))]));
  }
}

class _FeeDueCard extends StatelessWidget {
  final AcademicProvider academic; final Color wingColor;
  const _FeeDueCard({required this.academic, required this.wingColor});
  @override
  Widget build(BuildContext context) {
    if (academic.isLoading) return Container(height: 120, decoration: BoxDecoration(
color: AppTheme.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppTheme.border)), child: const Center(child: CircularProgressIndicator()));
    
    final auth = context.watch<AuthProvider>();
    final student = auth.currentStudent;
    
    final totalPaid = academic.fees.where((f) => f.status.toLowerCase() == 'paid').fold(0.0, (sum, f) => sum + f.amount);
    final totalQuota = academic.totalFee ?? student?.totalFee ?? 0.0;
    final netBalance = totalQuota - totalPaid;
    
    final hasRecords = academic.fees.isNotEmpty;
    final hasDue = netBalance > 0;
    
    Color statusColor = hasDue ? Colors.orange : (hasRecords ? AppTheme.success : AppTheme.textMuted);
    String statusLabel = hasDue ? 'DUE AMOUNT' : (hasRecords ? 'FEE STATUS' : 'SYSTEM STATUS');
    String statusValue = hasDue ? '₹${netBalance.toStringAsFixed(0)}' : (hasRecords ? 'FULLY PAID' : 'NO RECORDS');

    return Container(
      decoration: BoxDecoration(
color: AppTheme.surface, 
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5), 
        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(children: [
        Container(
          width: double.infinity, 
          padding: const EdgeInsets.all(24), 
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasDue 
                ? [Colors.orange.shade700, Colors.orange.shade500] 
                : hasRecords 
                  ? [AppTheme.success, const Color(0xFF34D399)]
                  : [Colors.grey.shade600, Colors.grey.shade400]
            ), 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26))
          ), 
          child: Row(children: [
            Icon(hasDue ? LucideIcons.alertCircle : (hasRecords ? LucideIcons.checkCircle2 : LucideIcons.database), color: Colors.white, size: 28), 
            const SizedBox(width: 16), 
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(statusLabel, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)), 
              const SizedBox(height: 4), 
              Text(statusValue, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))
            ])
          ])
        ),
        
        // Ledger Details Section (Mirroring Admin Table)
        if (totalQuota > 0) ...[
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: _LedgerItem(label: 'TOTAL PACKAGE', value: totalQuota, color: Colors.blue.shade700)),
                Container(width: 1, height: 30, color: AppTheme.border, margin: const EdgeInsets.symmetric(horizontal: 10)),
                Expanded(child: _LedgerItem(label: 'TOTAL PAID', value: totalPaid, color: AppTheme.success)),
              ],
            ),
          ),
          if (academic.feeRemarks != null && academic.feeRemarks!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Note: ${academic.feeRemarks}',
                style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
        ],
        
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen())), icon: const Icon(LucideIcons.externalLink, size: 14), label: const Text('View Detailed Statement'), style: TextButton.styleFrom(foregroundColor: wingColor, textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))))
      ]),
    );
  }
}

class _LedgerItem extends StatelessWidget {
  final String label; final double value; final Color color;
  const _LedgerItem({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text('₹${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
