import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/ext.dart';
import '../../models/models.dart';
import '../../providers/manager_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import 'manager_detail_screen.dart';
import 'subscription_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});
  static const routeName = '/owner';

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  String get _ownerId => context.read<AuthService>().currentOwnerId ?? '';

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ownerId.isNotEmpty) {
        context.read<ManagerProvider>().fetchAllManagers(ownerId: _ownerId);
      }
    });
  }

  @override
  void dispose() { _floatController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    if (!mounted) return;
    if (_ownerId.isNotEmpty) {
      await context.read<ManagerProvider>().fetchAllManagers(ownerId: _ownerId);
    }
  }

  Future<String> _getOwnerName() async {
    final auth = context.read<AuthService>();
    final name = auth.currentOwnerName;
    if (name != null && name.isNotEmpty) return name;
    final uid = auth.currentOwnerId;
    if (uid == null) return 'Owner';
    final data = await ApiService().getOwner(uid);
    if (data == null) return 'Owner';
    return data['name'] as String? ?? 'Owner';
  }

  void _showProfileSheet() {
    final auth = context.read<AuthService>();
    final email = auth.currentOwnerEmail ?? 'No email';
    final managersCount = context.read<ManagerProvider>().managers.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<String>(
        future: _getOwnerName(),
        builder: (context, snapshot) {
          final name = snapshot.data ?? 'Owner';
          final brightness = Theme.of(context).brightness;
          final glassColor = brightness == Brightness.dark ? const Color(0xFF1C2333) : Colors.white;
          final borderColor = brightness == Brightness.dark ? const Color(0xFF333344) : Colors.white;
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: glassColor.withValues(alpha: 0.85),
                  border: Border(top: BorderSide(color: borderColor.withValues(alpha: 0.5))),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white))),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                      const SizedBox(height: 4),
                      Text(email, style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground)),
                      const SizedBox(height: 24),
                      _SubscriptionCard(managersCount: managersCount),
                      const SizedBox(height: 12),
                      _SpinCard(),
                      const SizedBox(height: 12),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.muted.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(themeProvider.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                size: 20, color: AppTheme.foreground),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(context.t('Dark Mode'),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
                              ),
                              Switch(
                                value: themeProvider.isDark,
                                onChanged: (v) => themeProvider.setDarkMode(v),
                                activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
                                activeThumbColor: AppTheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Consumer<LanguageProvider>(
                        builder: (context, langProvider, _) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.muted.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.language_rounded,
                                size: 20, color: AppTheme.foreground),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(context.t('Language'),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
                              ),
                              DropdownButton<String>(
                                value: langProvider.locale,
                                dropdownColor: brightness == Brightness.dark ? AppTheme.darkCard : Colors.white,
                                underline: const SizedBox(),
                                style: TextStyle(fontSize: 14, color: AppTheme.foreground),
                                items: const [
                                  DropdownMenuItem(value: 'en', child: Text('English')),
                                  DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                                  DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                                ],
                                onChanged: (v) {
                                  if (v != null) langProvider.setLocale(v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity, height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.destructive.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => _GlassConfirmDialog(
                                title: context.t('Delete Account'),
                                message: context.t('This action is permanent. Are you sure?'),
                                confirmLabel: context.t('Delete'),
                                destructive: true,
                              ),
                            );
                            if (confirmed != true) return;
                            try {
                              final auth = context.read<AuthService>();
                              final ownerId = auth.currentOwnerId;
                              if (ownerId != null) {
                                await ApiService().deleteOwner(ownerId);
                              }
                              await auth.deleteAccount();
                              if (context.mounted) {
                                Navigator.of(context).pushReplacementNamed('/login');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'),
                                    backgroundColor: AppTheme.destructive,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.delete_outline, color: AppTheme.destructive, size: 18),
                          label: Text(context.t('Delete Account'), style: TextStyle(color: AppTheme.destructive)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerProvider>();
    final managers = provider.managers;
    final isLoading = provider.isLoading;
    final brightness = Theme.of(context).brightness;
    final glassColor = brightness == Brightness.dark ? const Color(0xFF1C2333) : Colors.white;
    final borderColor = brightness == Brightness.dark ? const Color(0xFF333344) : Colors.white;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) => CustomPaint(
                painter: _OwnerMeshPainter(shift: _floatController.value),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Glass App Bar ──
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: glassColor.withValues(alpha: 0.6),
                        border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.3))),
                      ),
                      child: Row(
                        children: [
                          Text('Owner Dashboard',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: glassColor.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.settings_outlined, size: 20, color: AppTheme.mutedForeground),
                              onPressed: _showProfileSheet,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: glassColor.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.logout_rounded, size: 20, color: AppTheme.mutedForeground),
                              onPressed: () async {
                                await context.read<AuthService>().signOut();
                                await StorageService.clearKeepOwnerSignedIn();
                                if (!context.mounted) return;
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Content ──
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // ── Header ──
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: AppTheme.glassDecoration(borderRadius: 16, opacity: 0.6, brightness: brightness),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${managers.length} Managers',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.foreground)),
                                        Text(context.t('Tap a manager to view details'),
                                          style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                                      onPressed: () => _showManagerDialog(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (isLoading) const LinearProgressIndicator(),

                        // ── Manager list ──
                        ...managers.map((manager) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ManagerGlassCard(
                            manager: manager,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ManagerDetailScreen(managerId: manager.id, managerName: manager.name),
                                ),
                              );
                            },
                            onEdit: () => _showManagerDialog(manager: manager),
                            onDelete: () => _handleManagerDelete(manager),
                          ),
                        )),

                        if (managers.isEmpty && !isLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.person_off_outlined, size: 64, color: AppTheme.mutedForeground.withValues(alpha: 0.3)),
                                  const SizedBox(height: 12),
                                  Text(context.t('No managers added yet'), style: TextStyle(color: AppTheme.mutedForeground, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text(context.t('Tap + to add your first manager'), style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleManagerDelete(Manager manager) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _GlassConfirmDialog(
        title: context.t('Delete Manager'),
        message: 'Are you sure you want to delete ${manager.name}?',
        confirmLabel: context.t('Delete'),
        destructive: true,
      ),
    );
    if (confirmed != true) return;
    try {
      await context.read<ManagerProvider>().deleteManager(manager.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('Manager deleted successfully!')),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
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

  Future<void> _showManagerDialog({Manager? manager}) async {
    final provider = context.read<ManagerProvider>();
    final nameController = TextEditingController(text: manager?.name ?? '');
    final vehicleController = TextEditingController(text: manager?.vehicleNumber ?? '');
    final passwordController = TextEditingController(text: manager?.password ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final b = Theme.of(ctx).brightness;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: AppTheme.glassDecoration(borderRadius: 24, opacity: 0.85, brightness: b),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(manager == null ? context.t('Add Manager') : context.t('Edit Manager'),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                    const SizedBox(height: 20),
                    _GlassInput(controller: nameController, hint: context.t('Name'), icon: Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    _GlassInput(controller: vehicleController, hint: context.t('Vehicle Number'), icon: Icons.local_shipping),
                    const SizedBox(height: 12),
                    _GlassInput(controller: passwordController, hint: context.t('Password'), icon: Icons.lock_outline_rounded, obscure: true),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.foreground,
                              side: BorderSide(color: AppTheme.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(context.t('Cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(context.t('Save')),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    );

    if (confirmed != true) return;

    final vehicleNum = vehicleController.text.trim().toUpperCase();

    try {
      final existing = await context.read<ApiService>().findManagerByVehicleNumber(vehicleNum);
      if (existing != null && existing.id != manager?.id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('This vehicle number is already used by another manager')),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
      if (manager == null) {
        await provider.createManager(
          name: nameController.text.trim(),
          vehicleNumber: vehicleNum,
          password: passwordController.text.trim(),
          ownerId: _ownerId.isNotEmpty ? _ownerId : null,
        );
      } else {
        await provider.updateManager(
          managerId: manager.id,
          name: nameController.text.trim(),
          vehicleNumber: vehicleNum,
          password: passwordController.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(manager == null ? context.t('Manager created!') : context.t('Manager updated!')),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
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
}

// ── Manager glass card ─────────────────────────────────────────────────────
class _ManagerGlassCard extends StatelessWidget {
  const _ManagerGlassCard({required this.manager, required this.onTap, required this.onEdit, required this.onDelete});

  final Manager manager;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.6, brightness: brightness),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: manager.locked ? null : onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Center(child: Text(manager.name.isNotEmpty ? manager.name[0].toUpperCase() : 'M',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(manager.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.foreground))),
                              if (manager.locked) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.lock_rounded, size: 16, color: Color(0xFFC62828)),
                                const SizedBox(width: 3),
                                Text(context.t('Locked'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFC62828))),
                              ] else if (manager.frozen) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF57C00)),
                                const SizedBox(width: 3),
                                Text(context.t('Frozen'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFF57C00))),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.local_shipping, size: 12, color: AppTheme.mutedForeground),
                              const SizedBox(width: 4),
                              Text(manager.vehicleNumber, style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
                            ],
                          ),
                        ],
                      ),
                    ),
    if (manager.locked)
      Icon(Icons.lock_rounded, size: 18, color: Color(0xFFC62828))
    else if (manager.frozen)
      PopupMenuButton<String>(
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.border),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(value: 'edit', child: ListTile(
            leading: Icon(Icons.edit_outlined, size: 18), title: Text(context.t('Edit')),
            dense: true, contentPadding: EdgeInsets.zero)),
          PopupMenuItem(value: 'delete', child: ListTile(
            leading: Icon(Icons.delete_outline, size: 18, color: AppTheme.destructive),
            title: Text(context.t('Delete'), style: TextStyle(color: AppTheme.destructive)),
            dense: true, contentPadding: EdgeInsets.zero)),
        ],
      )
    else
      PopupMenuButton<String>(
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.border),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(value: 'edit', child: ListTile(
            leading: Icon(Icons.edit_outlined, size: 18), title: Text(context.t('Edit')),
            dense: true, contentPadding: EdgeInsets.zero)),
          PopupMenuItem(value: 'delete', child: ListTile(
            leading: Icon(Icons.delete_outline, size: 18, color: AppTheme.destructive),
            title: Text(context.t('Delete'), style: TextStyle(color: AppTheme.destructive)),
            dense: true, contentPadding: EdgeInsets.zero)),
        ],
      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Subscription Card ─────────────────────────────────────────────────────
class _SubscriptionCard extends StatefulWidget {
  const _SubscriptionCard({required this.managersCount});
  final int managersCount;
  @override
  State<_SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<_SubscriptionCard> {
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
    try {
      final data = await ApiService().getOwner(id);
      if (mounted) setState(() { _owner = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final disabled = _owner?['subscriptionDisabled'] as bool? ?? false;
    final max = _owner?['maxManagers'] as int? ?? 0;
    final used = _owner?['managersUsed'] as int? ?? widget.managersCount;
    final sub = _owner?['subscription'] as Map<String, dynamic>? ?? {};
    final plan = (sub['plan'] as String? ?? 'free');
    final subStatus = (sub['status'] as String? ?? 'active');
    final isExpired = subStatus == 'expired';
    final isFree = plan == 'free';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.6, brightness: brightness),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: disabled ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: disabled
                            ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600])
                            : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: disabled ? [] : [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Icon(disabled ? Icons.block_rounded : Icons.subscriptions_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.t('Subscription'),
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: disabled ? AppTheme.mutedForeground : AppTheme.foreground)),
                          const SizedBox(height: 2),
                          Text(
                            disabled
                                ? 'Contact support to reactivate'
                                : (isFree
                                    ? 'Free plan | $used/$max managers'
                                    : '${plan[0].toUpperCase()}${plan.substring(1)} plan | $used/$max managers'),
                            style: TextStyle(fontSize: 11, color: disabled ? AppTheme.mutedForeground : (isExpired ? AppTheme.destructive : AppTheme.mutedForeground)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: disabled
                            ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600])
                            : (isExpired
                                ? LinearGradient(colors: [AppTheme.destructive, AppTheme.destructive.withValues(alpha: 0.7)])
                                : AppTheme.primaryGradient),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(disabled ? 'Disabled' : (isExpired ? context.t('Expired') : context.t('Active')),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    if (!disabled) const SizedBox(width: 4),
                    if (!disabled) Icon(Icons.chevron_right, color: AppTheme.mutedForeground, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── SPIN Card ──────────────────────────────────────────────────────────────
class _SpinCard extends StatefulWidget {
  const _SpinCard();
  @override
  State<_SpinCard> createState() => _SpinCardState();
}

class _SpinCardState extends State<_SpinCard> {
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
    try {
      final data = await ApiService().getOwner(id);
      if (mounted) setState(() { _owner = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _setSpin() async {
    final oldSpin = _owner?['spin'] as String? ?? '';
    final controller = TextEditingController(text: oldSpin);
    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final b = Theme.of(ctx).brightness;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            String error = '';
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: AppTheme.glassDecoration(borderRadius: 24, opacity: 0.85, brightness: b),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: const Color(0xFF6A11CB).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 16),
                      Text(context.t('Set SPIN'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                      const SizedBox(height: 6),
                      Text(context.t('Enter a 4-digit security PIN'), style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: controller,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.foreground, letterSpacing: 8),
                        cursorColor: AppTheme.primary,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: error.isNotEmpty ? AppTheme.destructive : AppTheme.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
                          errorText: error.isNotEmpty ? error : null,
                        ),
                        onChanged: (_) => setDialogState(() => error = ''),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(null),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.foreground,
                                side: BorderSide(color: AppTheme.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(context.t('Cancel')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  final val = controller.text.trim();
                                  if (val.length != 4 || int.tryParse(val) == null) {
                                    setDialogState(() => error = context.t('Enter a valid 4-digit PIN'));
                                    return;
                                  }
                                  Navigator.of(ctx).pop(val);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(context.t('Save')),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
    );

    if (pin == null || pin.length != 4) return;
    final auth = context.read<AuthService>();
    final id = auth.currentOwnerId;
    if (id == null) return;
    try {
      await ApiService().updateOwner(id, {'spin': pin});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('SPIN saved!')),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      _load();
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final brightness = Theme.of(context).brightness;
    final hasSpin = (_owner?['spin'] as String?)?.isNotEmpty == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.6, brightness: brightness),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _setSpin,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: const Color(0xFF6A11CB).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Icon(hasSpin ? Icons.lock_rounded : Icons.lock_open_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.t('SPIN'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                          const SizedBox(height: 2),
                          Text(hasSpin ? context.t('Tap to change SPIN') : context.t('Tap to set SPIN'),
                            style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasSpin ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(hasSpin ? context.t('Set') : context.t('Not Set'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: hasSpin ? AppTheme.success : AppTheme.warning)),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: AppTheme.mutedForeground, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass input for dialog ─────────────────────────────────────────────────
class _GlassInput extends StatefulWidget {
  const _GlassInput({required this.controller, required this.hint, required this.icon, this.obscure = false});
  final TextEditingController controller; final String hint; final IconData icon; final bool obscure;
  @override
  State<_GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<_GlassInput> {
  bool _hidden = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscure ? _hidden : false,
      style: TextStyle(color: AppTheme.foreground, fontSize: 14),
      cursorColor: AppTheme.primary,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: AppTheme.mutedForeground),
        prefixIcon: Icon(widget.icon, color: AppTheme.mutedForeground, size: 19),
        suffixIcon: widget.obscure
            ? IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.mutedForeground, size: 19),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
      ),
    );
  }
}

// ── Mesh painter ───────────────────────────────────────────────────────────
class _OwnerMeshPainter extends CustomPainter {
  _OwnerMeshPainter({required this.shift});
  final double shift;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    paint.color = AppTheme.meshColors[0].withValues(alpha: 0.06 + shift * 0.03);
    canvas.drawCircle(Offset(size.width * 0.2 + shift * 10, size.height * 0.15), size.width * 0.35, paint);
    paint.color = AppTheme.meshColors[3].withValues(alpha: 0.05 + (1 - shift) * 0.03);
    canvas.drawCircle(Offset(size.width * 0.8 - shift * 10, size.height * 0.7), size.width * 0.3, paint);
  }
  @override
  bool shouldRepaint(_OwnerMeshPainter old) => old.shift != shift;
}

// ── Glass confirm dialog ───────────────────────────────────────────────────
class _GlassConfirmDialog extends StatelessWidget {
  const _GlassConfirmDialog({required this.title, required this.message, required this.confirmLabel, this.destructive = false});

  final String title; final String message; final String confirmLabel; final bool destructive;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: AppTheme.glassDecoration(borderRadius: 24, opacity: 0.85, brightness: brightness),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(destructive ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                  size: 48, color: destructive ? AppTheme.destructive : AppTheme.primary),
                const SizedBox(height: 16),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.foreground,
                          side: BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(context.t('Cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: destructive
                              ? LinearGradient(colors: [AppTheme.destructive, AppTheme.destructive])
                              : AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(confirmLabel),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
