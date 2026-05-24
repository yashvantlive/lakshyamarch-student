import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_widgets.dart';
import 'subject_selection_screen.dart';

class ClassSelectionScreen extends StatefulWidget {
  final String type; // NCERT, DPP, Notes

  const ClassSelectionScreen({super.key, required this.type});

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  List<dynamic> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final api = ApiService();
      final data = await api.getClasses(auth.token ?? '');
      setState(() {
        _classes = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    const appBarHeight = 120.0;
    final gridHeight = screenHeight - appBarHeight - MediaQuery.of(context).padding.top - 40;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCenteredAppBar(auth.activeWingMode),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: (MediaQuery.of(context).size.width / 2) / (gridHeight / 4.2),
                    ),
                    itemCount: _classes.length,
                    itemBuilder: (context, index) {
                      final c = _classes[index];
                      return _buildClassTile(context, c);
                    },
                  ),
            ),
            const SizedBox(height: 20),
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
          Text(
            'Universal ${widget.type} Library',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textBase.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Access all classes instantly',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTile(BuildContext context, dynamic classObj) {
    return _FAANGClassTile(
      className: '${classObj['name']} (${classObj['wing']})',
      onTap: () => _navigateTo(
        context,
        SubjectSelectionScreen(
          classId: classObj['_id'],
          className: classObj['name'],
          materialType: widget.type,
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(Tween(begin: const Offset(0, 0.05), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutQuart))),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class _FAANGClassTile extends StatefulWidget {
  final String className;
  final VoidCallback onTap;

  const _FAANGClassTile({required this.className, required this.onTap});

  @override
  State<_FAANGClassTile> createState() => _FAANGClassTileState();
}

class _FAANGClassTileState extends State<_FAANGClassTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) => _controller.reverse(),
            onTapCancel: () => _controller.reverse(),
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.graduationCap, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.className,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textBase,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
