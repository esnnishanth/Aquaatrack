import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../localization/ext.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Map<String, dynamic>? _owner;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final id = auth.currentOwnerId;
    if (id == null) return;
    final api = ApiService();
    final data = await api.getOwner(id);
    setState(() {
      _owner = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SubMeshPainter())),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Header
                    ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
                          ),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.mutedForeground),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(context.t('Subscription'),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSubscriptionCard(),
                          const SizedBox(height: 16),
                          _buildManagerLimitCard(),
                          const SizedBox(height: 16),
                          _buildInfoCard(),
                          const SizedBox(height: 16),
                          _buildSubscribeButton(),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final sub = _owner?['subscription'] as Map<String, dynamic>? ?? {};
    final plan = (sub['plan'] as String? ?? 'free').toUpperCase();
    final status = sub['status'] as String? ?? 'active';
    final startDate = sub['startDate'] as String?;
    final endDate = sub['endDate'] as String?;
    final amount = (sub['amount'] as num?)?.toDouble() ?? 0;
    final pricePerManager = (_owner?['pricePerManager'] as num?)?.toDouble() ?? 300;
    final maxM = (_owner?['maxManagers'] as num?)?.toInt() ?? 0;
    final total = pricePerManager * maxM;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration(borderRadius: 16, opacity: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: plan == 'PREMIUM'
                        ? const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF8F00)])
                        : plan == 'BASIC'
                          ? const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)])
                          : AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(plan, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'active' ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(status.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: status == 'active' ? AppTheme.success : AppTheme.warning)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _infoRow(context.t('Managers Allowed'), maxM.toString()),
              _infoRow(context.t('Price per Manager'), '₹${pricePerManager.toStringAsFixed(0)}'),
              _infoRow(context.t('Total Amount'), '₹${total.toStringAsFixed(0)}'),
              if (amount > 0) _infoRow(context.t('Amount Paid'), '₹${amount.toStringAsFixed(0)}'),
              if (startDate != null) _infoRow(context.t('Start Date'), startDate.substring(0, 10)),
              if (endDate != null) _infoRow(context.t('End Date'), endDate.substring(0, 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagerLimitCard() {
    final maxM = (_owner?['maxManagers'] as num?)?.toInt() ?? 0;
    final usedM = (_owner?['managersUsed'] as num?)?.toInt() ?? 0;
    final remaining = maxM - usedM;
    final pct = maxM > 0 ? (usedM / maxM).clamp(0.0, 1.0) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration(borderRadius: 16, opacity: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t('Manager Usage'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(context.t('Used'), '$usedM', AppTheme.primary),
                  _statItem(context.t('Limit'), '$maxM', AppTheme.mutedForeground),
                  _statItem(context.t('Remaining'), '$remaining',
                    remaining > 0 ? AppTheme.success : AppTheme.destructive),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: maxM > 0 ? pct.clamp(0.0, 1.0) : 1.0,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    usedM >= maxM ? AppTheme.destructive : AppTheme.primary),
                  minHeight: 8,
                ),
              ),
              if (usedM >= maxM) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.destructive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.destructive, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(context.t('Manager limit reached. Contact admin to upgrade.'),
                          style: TextStyle(fontSize: 13, color: AppTheme.destructive)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration(borderRadius: 16, opacity: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t('About Subscription'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
              const SizedBox(height: 12),
              Text(
                'You can add up to ${(_owner?['maxManagers'] as num?)?.toInt() ?? 0} managers at ₹${(_owner?['pricePerManager'] as num?)?.toInt() ?? 300}/- per slot. '
                'Contact your admin to adjust your plan or increase the limit.',
                style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton(
          onPressed: _showSubscribeSheet,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.subscriptions_rounded, size: 20),
              const SizedBox(width: 8),
              Text(context.t('Subscribe'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscribeSheet() {
    int selectedManagers = 1;
    String selectedPlan = 'basic';
    final pricePerManager = (_owner?['pricePerManager'] as num?)?.toInt() ?? 300;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final total = pricePerManager * selectedManagers;

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),
                    Text(context.t('Subscribe'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                    const SizedBox(height: 8),
                    Text(context.t('Choose your plan'), style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground)),
                    const SizedBox(height: 20),

                    // Plan selector
                    Row(
                      children: ['free', 'basic', 'premium'].map((p) {
                        final labels = {'free': context.t('Free'), 'basic': context.t('Basic'), 'premium': context.t('Premium')};
                        final colors = {'free': AppTheme.primaryGradient, 'basic': const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]), 'premium': const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF8F00)])};
                        final isSelected = selectedPlan == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedPlan = p),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isSelected ? colors[p] : null,
                                color: isSelected ? null : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  Text(labels[p]!, style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : AppTheme.foreground)),
                                  if (p == 'free')
                                    Text('₹0', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : AppTheme.mutedForeground)),
                                  if (p != 'free')
                                    Text('₹${p == 'basic' ? pricePerManager : pricePerManager * 2}/slot', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : AppTheme.mutedForeground)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Manager count
                    Row(
                      children: [
                        Text(context.t('Managers'), style: TextStyle(fontSize: 14, color: AppTheme.foreground)),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                          onPressed: selectedManagers > 1 ? () => setSheetState(() => selectedManagers--) : null,
                        ),
                        Text('$selectedManagers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline, color: AppTheme.primary),
                          onPressed: selectedManagers < 50 ? () => setSheetState(() => selectedManagers++) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.t('Total'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
                          Text('₹${total.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Continue button — opens UPI app selector
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _showUpiAppPicker(selectedPlan, selectedManagers, total, pricePerManager),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(context.t('Continue'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUpiAppPicker(String plan, int managerCount, int total, int pricePerManager) {
    Navigator.of(context).pop(); // close plan sheet

    final upiId = '9790558179@ptyes';
    final note = 'AquaTrack ${plan[0].toUpperCase() + plan.substring(1)} × $managerCount';
    final upiUrl = 'upi://pay?pa=$upiId&pn=AquaTrack&am=$total&cu=INR&tn=${Uri.encodeComponent(note)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          bool copied = false;

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),
                    Icon(Icons.payments_rounded, size: 48, color: AppTheme.primary),
                    const SizedBox(height: 8),
                    Text(context.t('Pay via UPI'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                    const SizedBox(height: 4),
                    Text('₹$total • $note', style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
                    const SizedBox(height: 20),

                    // UPI ID display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Text(context.t('Pay to'), style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
                          const SizedBox(height: 6),
                          Text(upiId, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.foreground, letterSpacing: 1)),
                          const SizedBox(height: 6),
                          Text('₹$total', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Open UPI App
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(upiUrl);
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
                          label: Text(context.t('Pay ₹'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Copy UPI ID
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: upiId));
                          setSheetState(() => copied = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setSheetState(() => copied = false);
                          });
                        },
                        icon: Icon(copied == true ? Icons.check_rounded : Icons.copy_rounded, size: 18),
                        label: Text(copied == true ? context.t('Copied!') : context.t('Copy UPI ID'), style: TextStyle(fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.foreground,
                          side: BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // I've Paid
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _applySubscription(plan, managerCount, total, pricePerManager);
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                        label: Text(context.t("I've Paid"), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _applySubscription(String plan, int managerCount, int total, int pricePerManager) async {
    final auth = context.read<AuthService>();
    final id = auth.currentOwnerId;
    if (id == null) return;

    setState(() => _loading = true);
    try {
      await ApiService().updateOwner(id, {
        'maxManagers': managerCount,
        'pricePerManager': pricePerManager,
        'subscription': {
          'plan': plan,
          'status': 'active',
          'amount': total,
          'startDate': DateTime.now().toIso8601String(),
        },
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscribed to $plan plan with $managerCount manager(s)!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
            backgroundColor: AppTheme.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
      ],
    );
  }
}

class _SubMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    paint.color = Colors.blue.withValues(alpha: 0.04);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.15), size.width * 0.35, paint);
    paint.color = Colors.orange.withValues(alpha: 0.04);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), size.width * 0.3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
