import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../localization/ext.dart';
import '../../../models/models.dart';
import '../../../services/api_service.dart';
import '../../../services/report_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/bore_details_dialog.dart';

class AgentTab extends StatelessWidget {
  const AgentTab({
    super.key,
    required this.manager,
    required this.agents,
    required this.bores,
    required this.onRefresh,
    required this.readOnly,
  });

  final Manager manager;
  String get managerId => manager.id;
  final List<Agent> agents;
  final List<Bore> bores;
  final Future<void> Function() onRefresh;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.t('Agents'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!readOnly)
                    TextButton.icon(
                      onPressed: () => _showAgentDialog(context),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text(context.t('Add')),
                    ),
                  TextButton.icon(
                    onPressed: () => _showCommissionReportDialog(context),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(context.t('Report')),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...agents.map(
          (agent) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.7),
                child: ListTile(
                  title: Text(agent.name),
                  subtitle: Text(_boreCountLabel(agent.name)),
                  onTap: () => _showAgentBores(context, agent.name),
                  trailing: !readOnly
                      ? PopupMenuButton<String>(
                          onSelected: (value) => _handleAction(context, value, agent),
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'edit', child: Text(context.t('Edit'))),
                            PopupMenuItem(value: 'delete', child: Text(context.t('Delete'))),
                          ],
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        if (agents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(context.t('No agents added yet.')),
          ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    String action,
    Agent agent,
  ) async {
    if (action == 'edit') {
      await _showAgentDialog(context, agent: agent);
      return;
    }
    if (action == 'delete') {
      final api = context.read<ApiService>();
      await api.deleteAgent(managerId: managerId, agentId: agent.id);
      await onRefresh();
    }
  }

  Future<void> _showAgentDialog(BuildContext context, {Agent? agent}) async {
    final api = context.read<ApiService>();
    final controller = TextEditingController(text: agent?.name ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: AppTheme.glassDecoration(borderRadius: 24, opacity: 0.85),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    agent == null ? context.t('Add Agent') : context.t('Edit Agent'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: context.t('Agent Name'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(context.t('Cancel')),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(context.t('Save')),
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

    if (confirmed != true) return;

    final name = controller.text.trim();
    if (name.isEmpty) return;

    if (agent == null) {
      await api.addAgent(managerId: managerId, name: name);
    } else {
      await api.updateAgent(
        managerId: managerId,
        agentId: agent.id,
        name: name,
      );
    }

    await onRefresh();
  }

  Future<void> _showCommissionReportDialog(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTimeRange? selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    Agent? selectedAgent = agents.isNotEmpty ? agents.first : null;
    bool simulateSettlement = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: AppTheme.glassDecoration(borderRadius: 24, opacity: 0.85),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('Download Report'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Agent>(
                      initialValue: selectedAgent,
                      decoration: InputDecoration(
                        labelText: context.t('Agent'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                      ),
                      items: agents
                          .map(
                            (agent) => DropdownMenuItem(
                              value: agent,
                              child: Text(agent.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedAgent = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          initialDateRange: selectedRange,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedRange = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        selectedRange == null
                            ? context.t('Select From and To Date')
                            : '${shortDate.format(selectedRange!.start)} - ${shortDate.format(selectedRange!.end)}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.t('Settlement Mode')),
                      value: simulateSettlement,
                      activeThumbColor: AppTheme.success,
                      onChanged: (val) {
                        setState(() => simulateSettlement = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(context.t('Cancel')),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(context.t('Download')),
                        ),
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

    if (confirmed != true || selectedRange == null || selectedAgent == null) {
      return;
    }

    await ReportService.printAgentCommissionReport(
      manager: manager,
      agent: selectedAgent!,
      fromDate: selectedRange!.start,
      toDate: selectedRange!.end,
      simulateSettlement: simulateSettlement,
    );
  }

  String _boreCountLabel(String agentName) {
    final count = bores.where((bore) => bore.agentName == agentName).length;
    return '$count bores';
  }

  Future<void> _showAgentBores(BuildContext context, String agentName) async {
    final allAgentBores =
        bores.where((bore) => bore.agentName == agentName).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final agentBores = allAgentBores.where((bore) {
      final comm = (bore.totalFeet * bore.agentCommissionPerFeet) +
          (bore.pipesUsed.fold<double>(0, (s, p) => s + p.length) * bore.agentCommissionPerPipeFoot) +
          (bore.steelFeet * bore.steelAgentCommission);
      return bore.commissionSettled < comm;
    }).toList();

    double paid(Bore b) => b.payments.fold<double>(0, (s, p) => s + p.amount);
    double originalBalance(Bore b) => b.totalBill - paid(b);
    double boreTotalCommission(Bore b) {
      final totalPipeLength = b.pipesUsed.fold<double>(
        0,
        (sum, pipe) => sum + pipe.length,
      );
      return (b.totalFeet * b.agentCommissionPerFeet) +
          (totalPipeLength * b.agentCommissionPerPipeFoot) +
          (b.steelFeet * b.steelAgentCommission);
    }

    bool simulateSettlement = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double totalOrigBal = 0;
          double totalOrigComm = 0;

          for (final bore in agentBores) {
            totalOrigBal += originalBalance(bore);
            totalOrigComm += boreTotalCommission(bore);
          }

          double totalDisplayBal = totalOrigBal;
          double totalDisplayComm = totalOrigComm;
          double settlementAmount = 0;

          if (simulateSettlement) {
            if (totalOrigBal > 0 && totalOrigComm > 0) {
              settlementAmount = totalOrigBal < totalOrigComm
                  ? totalOrigBal
                  : totalOrigComm;
              totalDisplayBal = totalOrigBal - settlementAmount;
              totalDisplayComm = totalOrigComm - settlementAmount;
            } else if (totalOrigBal <= 0 && totalOrigComm > 0) {
              settlementAmount = totalOrigComm;
              totalDisplayBal = 0;
              totalDisplayComm = 0;
            }
          }

          final lastCommissionExpense = manager.data.normalExpenses
              .where((e) => e.description.toLowerCase() == 'commission')
              .fold<NormalExpense?>(null, (latest, e) {
                if (latest == null || e.date.isAfter(latest.date)) return e;
                return latest;
              });

          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: AppTheme.glassDecoration(borderRadius: 24, opacity: 0.85),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: 500,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          children: [
                            Text(
                              '$agentName • Bores',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            if (lastCommissionExpense != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Last settled: ${shortDate.format(lastCommissionExpense.date)} at ${lastCommissionExpense.date.hour.toString().padLeft(2, '0')}:${lastCommissionExpense.date.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.t('Settle Commissions'),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Switch(
                              value: simulateSettlement,
                              activeThumbColor: AppTheme.success,
                              onChanged: (val) {
                                setState(() => simulateSettlement = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: agentBores.map((bore) {
                            final origBal = originalBalance(bore);
                            final origComm = boreTotalCommission(bore);

                            double displayBal = origBal;
                            double displayComm = origComm;

                            if (simulateSettlement && origBal > 0 && origComm > 0) {
                              final s = origBal < origComm ? origBal : origComm;
                              displayBal = origBal - s;
                              displayComm = origComm - s;
                            }

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.7),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => showBoreDetailsDialog(context, bore, managerName: manager.name),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                bore.boreNumber,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                shortDate.format(bore.date),
                                                style: TextStyle(
                                                  color: AppTheme.mutedForeground,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              _statChip(
                                                context.t('Total Feet'),
                                                '${bore.totalFeet} ft',
                                              ),
                                              const SizedBox(width: 8),
                                              _statChip(
                                                context.t('Total Bill'),
                                                currencyInr.format(bore.totalBill),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _statChip(
                                                context.t('Balance'),
                                                currencyInr.format(displayBal),
                                                valueColor: displayBal > 0
                                                    ? AppTheme.destructive
                                                    : AppTheme.success,
                                              ),
                                              const SizedBox(width: 8),
                                              _statChip(
                                                context.t('Commission'),
                                                currencyInr.format(displayComm),
                                                valueColor: AppTheme.accent,
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
                          }).toList(),
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.t('Total Balance:'),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  currencyInr.format(totalDisplayBal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: totalDisplayBal > 0
                                        ? AppTheme.destructive
                                        : AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.t('Total Commission:'),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  currencyInr.format(totalDisplayComm),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (simulateSettlement) ...[
                              Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accent.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final api = context.read<ApiService>();
                                      if (totalOrigBal <= 0 && totalOrigComm <= 0) return;

                                    final ownerId = manager.ownerId;
                                    if (ownerId == null || ownerId.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(context.t('Owner not linked. Cannot settle.')),
                                          backgroundColor: AppTheme.destructive,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                        ),
                                      );
                                      return;
                                    }

                                    final spinController = TextEditingController();
                                    String? spinError;
                                    final spinConfirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => StatefulBuilder(
                                        builder: (ctx, setSpinState) => Dialog(
                                          backgroundColor: Colors.transparent,
                                          elevation: 0,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(24),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                              child: Container(
                                                padding: const EdgeInsets.all(28),
                                                decoration: AppTheme.glassDecoration(borderRadius: 24, opacity: 0.85),
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
                                                    Text(context.t('Enter SPIN'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                                                    const SizedBox(height: 6),
                                                    Text(context.t('Enter 4-digit security PIN to confirm settlement'), style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
                                                    const SizedBox(height: 20),
                                                    TextField(
                                                      controller: spinController,
                                                      maxLength: 4,
                                                      keyboardType: TextInputType.number,
                                                      textAlign: TextAlign.center,
                                                      obscureText: true,
                                                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.foreground, letterSpacing: 8),
                                                      cursorColor: AppTheme.primary,
                                                      decoration: InputDecoration(
                                                        counterText: '',
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: spinError != null ? AppTheme.destructive : AppTheme.border)),
                                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.border)),
                                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
                                                        errorText: spinError,
                                                      ),
                                                      onChanged: (_) => setSpinState(() => spinError = null),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: OutlinedButton(
                                                            onPressed: () => Navigator.of(ctx).pop(false),
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
                                                              onPressed: () => Navigator.of(ctx).pop(true),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: Colors.transparent,
                                                                foregroundColor: Colors.white,
                                                                elevation: 0,
                                                                shadowColor: Colors.transparent,
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                              ),
                                                              child: Text(context.t('Verify')),
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
                                      ),
                                    );

                                    if (spinConfirmed != true) return;

                                    final spin = spinController.text.trim();
                                    if (spin.length != 4) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(context.t('Invalid SPIN')),
                                          backgroundColor: AppTheme.destructive,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                        ),
                                      );
                                      return;
                                    }

                                    final verify = await api.verifySpin(ownerId, spin);
                                    if (verify['valid'] != true) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(verify['error'] as String? ?? context.t('Invalid SPIN')),
                                          backgroundColor: AppTheme.destructive,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                        ),
                                      );
                                      return;
                                    }

                                    for (final bore in agentBores) {
                                      final bal = originalBalance(bore);
                                      if (bal > 0) {
                                        await api.addPayment(
                                          managerId: managerId,
                                          boreId: bore.id,
                                          amount: bal,
                                          date: DateTime.now(),
                                        );
                                      }
                                    }
                                    for (final bore in agentBores) {
                                      final comm = boreTotalCommission(bore);
                                      if (bore.commissionSettled < comm) {
                                        await api.settleCommission(managerId: managerId, boreId: bore.id);
                                      }
                                    }
                                    if (settlementAmount > 0) {
                                      await api.addNormalExpense(
                                        managerId: managerId,
                                        description: 'commission',
                                        amount: settlementAmount,
                                        date: DateTime.now(),
                                      );
                                    }
                                    Navigator.of(context).pop();
                                    await onRefresh();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.transparent,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: Text(context.t('Settle')),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(context.t('Close')),
                            ),
                          ],
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

  Widget _statChip(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
