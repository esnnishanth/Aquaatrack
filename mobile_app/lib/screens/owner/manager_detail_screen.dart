import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/ext.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_view.dart';
import '../manager/tabs/live_tab.dart';
import '../manager/tabs/bore_tab.dart';
import '../manager/tabs/agent_tab.dart';
import '../manager/tabs/expense_tab.dart';
import '../manager/tabs/income_tab.dart';
import '../manager/tabs/labour_tab.dart';
import '../manager/tabs/pipe_tab.dart';

class ManagerDetailScreen extends StatefulWidget {
  const ManagerDetailScreen({super.key, required this.managerId, required this.managerName});
  final String managerId;
  final String managerName;

  @override
  State<ManagerDetailScreen> createState() => _ManagerDetailScreenState();
}

class _ManagerDetailScreenState extends State<ManagerDetailScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _floatController;
  Manager? _manager;
  bool _loading = true;
  StreamSubscription<Manager?>? _sub;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);
    _loadManager();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _loadManager() async {
    final api = context.read<ApiService>();
    if (_manager == null) setState(() => _loading = true);
    try { _manager = await api.fetchManager(widget.managerId); }
    finally { if (mounted) setState(() => _loading = false); }
    _sub?.cancel();
    _sub = api.watchManager(widget.managerId).listen((manager) {
      if (mounted && manager != null) setState(() => _manager = manager);
    });
  }

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            Center(child: LoadingView(message: context.t('Loading manager...'))),
          ],
        ),
      );
    }

    if (_manager == null) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: AppTheme.mutedForeground.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(context.t('Manager not found.'), style: TextStyle(color: AppTheme.foreground, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final manager = _manager!;
    final brightness = Theme.of(context).brightness;
    final glassColor = brightness == Brightness.dark ? const Color(0xFF1C2333) : Colors.white;
    final borderColor = brightness == Brightness.dark ? const Color(0xFF333344) : Colors.white;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
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
                                Container(
                                  decoration: BoxDecoration(
                                    color: glassColor.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.foreground),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(child: Text('${manager.name} Dashboard',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground))),
                                      if (manager.frozen) ...[
                                        const SizedBox(width: 6),
                                        Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF57C00)),
                                        const SizedBox(width: 3),
                                        Text(context.t('Frozen'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFF57C00))),
                                      ],
                                    ],
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

                // ── Filter bar ──
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
                              color: glassColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border)),
                            child: DropdownButton<int>(
                              value: _selectedMonth, underline: const SizedBox(), isDense: true,
                              style: TextStyle(fontSize: 12, color: AppTheme.foreground),
                              items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(context.t(_months[i]), style: TextStyle(fontSize: 12)))),
                              onChanged: (v) => setState(() => _selectedMonth = v!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: glassColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border)),
                            child: DropdownButton<int>(
                              value: _selectedYear, underline: const SizedBox(), isDense: true,
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

                // ── Tabs ──
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      LiveTab(manager: manager, selectedMonth: _selectedMonth, selectedYear: _selectedYear,
                        normalExpenses: manager.data.normalExpenses, labourPayments: manager.data.labourPayments, readOnly: manager.frozen),
                      LabourTab(manager: manager, selectedMonth: _selectedMonth, selectedYear: _selectedYear,
                        workers: manager.data.workers, onRefresh: _loadManager, readOnly: manager.frozen),
                      BoreTab(managerId: manager.id, managerName: manager.name,
                        selectedMonth: _selectedMonth, selectedYear: _selectedYear,
                        bores: manager.data.bores, pipeStock: manager.data.pipeStock,
                        agents: manager.data.agents, onRefresh: _loadManager, readOnly: manager.frozen),
                      IncomeTab(managerId: manager.id, selectedMonth: _selectedMonth, selectedYear: _selectedYear,
                        bores: manager.data.bores, onRefresh: _loadManager, readOnly: manager.frozen),
                      ExpenseTab(manager: manager, selectedMonth: _selectedMonth, selectedYear: _selectedYear,
                        workers: manager.data.workers, normalExpenses: manager.data.normalExpenses,
                        labourPayments: manager.data.labourPayments, onRefresh: _loadManager, role: 'owner', readOnly: manager.frozen),
                      PipeTab(managerId: manager.id, pipeStock: manager.data.pipeStock, onRefresh: _loadManager, readOnly: manager.frozen),
                      AgentTab(manager: manager, agents: manager.data.agents, bores: manager.data.bores, onRefresh: _loadManager, readOnly: manager.frozen),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_loading)
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
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) => CustomPaint(
        painter: _DetailMeshPainter(shift: _floatController.value),
      ),
    );
  }
}

class _DetailMeshPainter extends CustomPainter {
  _DetailMeshPainter({required this.shift});
  final double shift;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    paint.color = AppTheme.meshColors[1].withValues(alpha: 0.07 + shift * 0.03);
    canvas.drawCircle(Offset(size.width * 0.25 + shift * 12, size.height * 0.2), size.width * 0.3, paint);
    paint.color = AppTheme.meshColors[2].withValues(alpha: 0.05 + (1 - shift) * 0.03);
    canvas.drawCircle(Offset(size.width * 0.75 - shift * 12, size.height * 0.8), size.width * 0.25, paint);
  }
  @override
  bool shouldRepaint(_DetailMeshPainter old) => old.shift != shift;
}
