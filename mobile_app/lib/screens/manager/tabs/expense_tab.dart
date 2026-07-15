import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../localization/ext.dart';
import '../../../models/models.dart';
import '../../../services/api_service.dart';
import '../../../services/report_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

class ExpenseTab extends StatelessWidget {
  const ExpenseTab({
    super.key,
    required this.manager,
    required this.selectedMonth,
    required this.selectedYear,
    required this.workers,
    required this.normalExpenses,
    required this.labourPayments,
    required this.onRefresh,
    required this.readOnly,
    this.role = 'manager',
  });

  final Manager manager;
  final int selectedMonth;
  final int selectedYear;
  final List<Worker> workers;
  final List<NormalExpense> normalExpenses;
  final List<LabourPayment> labourPayments;
  final Future<void> Function() onRefresh;
  final bool readOnly;
  final String role;

  @override
  Widget build(BuildContext context) {
    final combined = <_ExpenseItem>[];
    combined.addAll(normalExpenses
        .where((exp) => exp.date.month == selectedMonth && exp.date.year == selectedYear)
        .map((expense) => _ExpenseItem(
              id: expense.id,
              date: expense.date,
              description: expense.description,
              amount: expense.amount,
              type: 'Normal',
            )));

    combined.addAll(labourPayments
        .where((pay) => pay.date.month == selectedMonth && pay.date.year == selectedYear)
        .map((payment) {
      final worker = workers.firstWhere(
        (w) => w.id == payment.workerId,
        orElse: () => Worker(
          id: '',
          name: 'Unknown Worker',
          place: '',
          monthlySalary: 0,
          monthsWorked: 0,
          amountPaid: 0,
        ),
      );
      return _ExpenseItem(
        id: payment.id,
        date: payment.date,
        description: 'Payment to ${worker.name}',
        amount: payment.amount,
        type: 'Labour',
      );
    }));

    combined.sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.t('Expense Management'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: () => _showExpenseReportDialog(context),
              icon: const Icon(Icons.download_outlined),
              label: Text(context.t('Report')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _NormalExpenseForm(manager: manager, role: role, onRefresh: onRefresh, readOnly: readOnly),
        const SizedBox(height: 12),
        _LabourPaymentForm(manager: manager, workers: workers, role: role, onRefresh: onRefresh, readOnly: readOnly),
        const SizedBox(height: 12),
        const SizedBox(height: 20),
        Text(context.t('Expense History'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...combined.map((item) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.7),
                  child: ListTile(
                    title: Text(item.description),
                    subtitle: Text('${item.type} • ${shortDate.format(item.date)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currencyInr.format(item.amount)),
                        if (!readOnly)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(context, item),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
        if (combined.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(context.t('No expenses recorded yet.')),
          ),
      ],
    );
  }

  Future<void> _showExpenseReportDialog(BuildContext context) async {
    try {
      final manager = this.manager;

      final pickedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      );

      if (pickedRange == null) return;

      await ReportService.printExpenseReport(
        manager: manager,
        fromDate: pickedRange.start,
        toDate: pickedRange.end,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, _ExpenseItem item) async {
    final api = context.read<ApiService>();
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
                  Text(context.t('Delete Expense'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(context.t('This will remove the expense record.')),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.t('Cancel'))),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(context.t('Delete'))),
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

    if (item.type == 'Labour') {
      await api.deleteLabourPayment(managerId: manager.id, paymentId: item.id);
    } else {
      await api.deleteNormalExpense(managerId: manager.id, expenseId: item.id);
    }
    await onRefresh();
  }
}

class _NormalExpenseForm extends StatefulWidget {
  const _NormalExpenseForm({required this.manager, required this.role, required this.onRefresh, required this.readOnly});

  final Manager manager;
  final String role;
  final Future<void> Function() onRefresh;
  final bool readOnly;

  @override
  State<_NormalExpenseForm> createState() => _NormalExpenseFormState();
}

class _NormalExpenseFormState extends State<_NormalExpenseForm> {
  late final TextEditingController _descController;
  late final TextEditingController _amountController;
  String _expMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.7),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.t('Normal Expense'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: context.t('Description'),
                  filled: true,
                  fillColor: Colors.transparent,
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
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.t('Amount'),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: (double.tryParse(_amountController.text) ?? 0) > 0
                    ? Container(
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.t('Select Paid Method'), style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: 'cash',
                                        groupValue: _expMethod,
                                        onChanged: (v) => setState(() => _expMethod = v!),
                                      ),
                                      Text(context.t('Cash')),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: 'account',
                                        groupValue: _expMethod,
                                        onChanged: (v) => setState(() => _expMethod = v!),
                                      ),
                                      Text(context.t('Account')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              if (!widget.readOnly)
                ElevatedButton(
                  onPressed: () async {
                    final desc = _descController.text.trim();
                    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
                    if (desc.isEmpty || amount <= 0) return;
                    await api.addNormalExpense(managerId: widget.manager.id, description: desc, amount: amount, date: DateTime.now(), method: _expMethod, createdBy: widget.role);
                    await widget.onRefresh();
                    _descController.clear();
                    _amountController.clear();
                  },
                  child: Text(context.t('Save Expense')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabourPaymentForm extends StatefulWidget {
  const _LabourPaymentForm({required this.manager, required this.workers, required this.role, required this.onRefresh, required this.readOnly});

  final Manager manager;
  final List<Worker> workers;
  final String role;
  final Future<void> Function() onRefresh;
  final bool readOnly;

  @override
  State<_LabourPaymentForm> createState() => _LabourPaymentFormState();
}

class _LabourPaymentFormState extends State<_LabourPaymentForm> {
  Worker? _selectedWorker;
  late final TextEditingController _amountController;
  String _payMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.7),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.t('Labour Payment'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              DropdownButtonFormField<Worker>(
                value: _selectedWorker,
                items: widget.workers.map((worker) => DropdownMenuItem(value: worker, child: Text(worker.name))).toList(),
                onChanged: (value) => setState(() => _selectedWorker = value),
                decoration: InputDecoration(
                  labelText: context.t('Select Worker'),
                  filled: true,
                  fillColor: Colors.transparent,
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
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.t('Amount'),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: (double.tryParse(_amountController.text) ?? 0) > 0
                    ? Container(
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.t('Select Paid Method'), style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: 'cash',
                                        groupValue: _payMethod,
                                        onChanged: (v) => setState(() => _payMethod = v!),
                                      ),
                                      Text(context.t('Cash')),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: 'account',
                                        groupValue: _payMethod,
                                        onChanged: (v) => setState(() => _payMethod = v!),
                                      ),
                                      Text(context.t('Account')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              if (!widget.readOnly)
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedWorker == null) return;
                    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
                    if (amount <= 0) return;
                    await api.addLabourPayment(managerId: widget.manager.id, workerId: _selectedWorker!.id, amount: amount, date: DateTime.now(), method: _payMethod, createdBy: widget.role);
                    await widget.onRefresh();
                    _amountController.clear();
                  },
                  child: Text(context.t('Record Payment')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ExpenseItem {
  _ExpenseItem({required this.id, required this.date, required this.description, required this.amount, required this.type});

  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String type;
}
