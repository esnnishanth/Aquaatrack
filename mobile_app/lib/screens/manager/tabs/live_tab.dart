import 'package:flutter/material.dart';
import '../../../localization/ext.dart';
import '../../../models/models.dart';
import '../../../services/report_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/stats_cards.dart';

class LiveTab extends StatelessWidget {
  const LiveTab({
    super.key,
    required this.manager,
    required this.selectedMonth,
    required this.selectedYear,
    required this.normalExpenses,
    required this.labourPayments,
    required this.readOnly,
  });

  final Manager manager;
  final int selectedMonth;
  final int selectedYear;
  final List<NormalExpense> normalExpenses;
  final List<LabourPayment> labourPayments;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final filteredBores = manager.data.bores.where((bore) {
      return bore.date.month == selectedMonth && bore.date.year == selectedYear;
    }).toList();

    final filteredNormalExpenses = normalExpenses.where((exp) {
      return exp.date.month == selectedMonth && exp.date.year == selectedYear;
    }).toList();

    final filteredLabourPayments = labourPayments.where((pay) {
      return pay.date.month == selectedMonth && pay.date.year == selectedYear;
    }).toList();

    final totalIncome = filteredBores
        .expand((bore) => bore.payments)
        .fold<double>(0, (sum, p) => sum + p.amount);

    final totalExpense = filteredNormalExpenses
            .fold<double>(0, (sum, e) => sum + e.amount) +
        filteredLabourPayments.fold<double>(0, (sum, p) => sum + p.amount);

    final profitLoss = totalIncome - totalExpense;

    final dieselExpense = filteredNormalExpenses
        .where((e) => e.description.toLowerCase().contains('diesel'))
        .fold<double>(0, (sum, e) => sum + e.amount);

    final tyreExpense = filteredNormalExpenses
        .where((e) => e.description.toLowerCase().contains('tyre'))
        .fold<double>(0, (sum, e) => sum + e.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StatsCards(
          bores: filteredBores,
          normalExpenses: filteredNormalExpenses,
          labourPayments: filteredLabourPayments,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.t('Monthly Summary'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                _SummaryRow(label: context.t('Total Income'), value: totalIncome, isPositive: true),
                _SummaryRow(label: context.t('Total Expense'), value: totalExpense, isPositive: false),
                const Divider(),
                _SummaryRow(
                  label: context.t('Profit/Loss'),
                  value: profitLoss,
                  isPositive: profitLoss >= 0,
                  isBold: true,
                ),
                const SizedBox(height: 12),
                Text(
                  context.t('Specific Expenses'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.mutedForeground,
                      ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(label: context.t('Diesel'), value: dieselExpense, isPositive: false),
                _SummaryRow(label: context.t('Tyre'), value: tyreExpense, isPositive: false),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: DateTime(selectedYear, selectedMonth, 1),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (selected == null) return;
                    await ReportService.printMonthlyReport(
                      manager: manager,
                      month: selected,
                    );
                  },
                  icon: const Icon(Icons.download_outlined),
                  label: Text(context.t('Download Full Report')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.insights_outlined,
                  size: 28,
                  color: AppTheme.mutedForeground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('Live Overview'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.t('Updated from current manager data'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.isPositive,
    this.isBold = false,
  });

  final String label;
  final double value;
  final bool isPositive;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
          ),
          Text(
            currencyInr.format(value),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isPositive ? AppTheme.success : AppTheme.destructive,
                ),
          ),
        ],
      ),
    );
  }
}
