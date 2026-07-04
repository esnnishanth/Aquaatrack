import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/ext.dart';
import '../../providers/manager_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/formatters.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_view.dart';
import 'tabs/live_tab.dart';
import 'tabs/bore_tab.dart';
import 'tabs/agent_tab.dart';
import 'tabs/expense_tab.dart';
import 'tabs/income_tab.dart';
import 'tabs/labour_tab.dart';
import 'tabs/pipe_tab.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});
  static const routeName = '/manager';

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _floatController;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerProvider>();

    if (provider.isLoading) {
      return Scaffold(body: LoadingView(message: context.t('Loading manager data...')));
    }

    final manager = provider.manager;
    if (manager == null) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: AppTheme.glassDecoration(borderRadius: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 48, color: AppTheme.mutedForeground),
                        const SizedBox(height: 16),
                        Text(context.t('No manager session found.'), style: TextStyle(color: AppTheme.foreground, fontSize: 16)),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(context.t('Go to Login')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Future<void> refresh() async {
      await provider.fetchManager(manager.id);
    }

    final brightness = Theme.of(context).brightness;
    final glassColor = brightness == Brightness.dark ? const Color(0xFF1C2333) : Colors.white;
    final borderColor = brightness == Brightness.dark ? const Color(0xFF333344) : Colors.white;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),

          // ── Safe content ──
          SafeArea(
            child: Column(
              children: [
                // ── Glass App Bar ──
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: glassColor.withValues(alpha: 0.6),
                        border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.3))),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('Welcome, ${manager.name}',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: glassColor.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.settings_outlined, size: 20, color: AppTheme.mutedForeground),
                                    onPressed: () => _showSettings(context),
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
                                      await provider.logout();
                                      if (!context.mounted) return;
                                      Navigator.of(context).pushReplacementNamed('/login');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: AppTheme.foreground,
                            unselectedLabelColor: AppTheme.mutedForeground,
                            indicatorColor: Colors.transparent,
                            indicatorWeight: 0,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: glassColor.withValues(alpha: 0.5),
                              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            tabs: [
                              Tab(text: context.t('Live')), Tab(text: context.t('Labour')), Tab(text: context.t('Bore')),
                              Tab(text: context.t('Income')), Tab(text: context.t('Expense')), Tab(text: context.t('Pipe')), Tab(text: context.t('Agents')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Glass filter bar ──
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: glassColor.withValues(alpha: 0.3),
                        border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.2))),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list_rounded, size: 16, color: AppTheme.mutedForeground),
                          const SizedBox(width: 8),
                          Text(context.t('Filter:'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: glassColor.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                            ),
                            child: DropdownButton<int>(
                              value: _selectedMonth,
                              underline: const SizedBox(),
                              isDense: true,
                              style: TextStyle(fontSize: 12, color: AppTheme.foreground),
                              items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(context.t(_months[i]), style: TextStyle(fontSize: 12)))),
                              onChanged: (v) => setState(() => _selectedMonth = v!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: glassColor.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                            ),
                            child: DropdownButton<int>(
                              value: _selectedYear,
                              underline: const SizedBox(),
                              isDense: true,
                              style: TextStyle(fontSize: 12, color: AppTheme.foreground),
                              items: List.generate(10, (i) {
                                final y = DateTime.now().year - 5 + i;
                                return DropdownMenuItem(value: y, child: Text(y.toString(), style: TextStyle(fontSize: 12)));
                              }),
                              onChanged: (v) => setState(() => _selectedYear = v!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Tabs content ──
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      LiveTab(manager: manager, selectedMonth: _selectedMonth, selectedYear: _selectedYear,
                        normalExpenses: manager.data.normalExpenses, labourPayments: manager.data.labourPayments, readOnly: false),
                      LabourTab(manager: manager, selectedMonth: _selectedMonth, selectedYear: _selectedYear,
                        workers: manager.data.workers, onRefresh: refresh, readOnly: false),
                      BoreTab(managerId: manager.id, managerName: manager.name,
                        selectedMonth: _selectedMonth, selectedYear: _selectedYear,
                        bores: manager.data.bores, pipeStock: manager.data.pipeStock,
                        agents: manager.data.agents, onRefresh: refresh, readOnly: false),
                      IncomeTab(managerId: manager.id, selectedMonth: _selectedMonth, selectedYear: _selectedYear,
                        bores: manager.data.bores, onRefresh: refresh, readOnly: false),
                      ExpenseTab(manager: manager, selectedMonth: _selectedMonth, selectedYear: _selectedYear,
                        workers: manager.data.workers, normalExpenses: manager.data.normalExpenses,
                        labourPayments: manager.data.labourPayments, onRefresh: refresh, readOnly: false),
                      PipeTab(managerId: manager.id, pipeStock: manager.data.pipeStock, onRefresh: refresh, readOnly: false),
                      AgentTab(manager: manager, agents: manager.data.agents, bores: manager.data.bores, onRefresh: refresh, readOnly: false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Loading overlay ──
          if (provider.isLoading)
            Positioned(
              top: 0, left: 0, right: 0,
              child: const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 3,
              ),
            ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: glassColor.withValues(alpha: 0.6),
              border: Border(top: BorderSide(color: borderColor.withValues(alpha: 0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Manager: ${manager.name}', style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
                Text('Last update: ${shortDate.format(DateTime.now())}', style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final b = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                  Text(context.t('Settings'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                  const SizedBox(height: 20),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      final bg = b == Brightness.dark ? AppTheme.darkMuted : AppTheme.muted;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: bg.withValues(alpha: 0.3),
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
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Consumer<LanguageProvider>(
                    builder: (context, langProvider, _) {
                      final bg = b == Brightness.dark ? AppTheme.darkMuted : AppTheme.muted;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: bg.withValues(alpha: 0.3),
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
                              dropdownColor: b == Brightness.dark ? AppTheme.darkCard : Colors.white,
                              underline: const SizedBox(),
                              style: TextStyle(fontSize: 14, color: AppTheme.foreground),
                              items: [
                                DropdownMenuItem(value: 'en', child: Text(context.t('English'))),
                                const DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                                const DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                              ],
                              onChanged: (v) {
                                if (v != null) langProvider.setLocale(v);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(context.t('Close')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) => CustomPaint(
        painter: _DashMeshPainter(shift: _floatController.value),
      ),
    );
  }
}

class _DashMeshPainter extends CustomPainter {
  _DashMeshPainter({required this.shift});
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    final c1 = AppTheme.meshColors[0].withValues(alpha: 0.08 + shift * 0.03);
    final c2 = AppTheme.meshColors[2].withValues(alpha: 0.06 + (1 - shift) * 0.03);
    paint.color = c1;
    canvas.drawCircle(Offset(size.width * 0.3 + shift * 15, size.height * 0.15), size.width * 0.35, paint);
    paint.color = c2;
    canvas.drawCircle(Offset(size.width * 0.7 - shift * 15, size.height * 0.85), size.width * 0.3, paint);
  }

  @override
  bool shouldRepaint(_DashMeshPainter old) => old.shift != shift;
}
