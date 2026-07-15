import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../localization/ext.dart';
import '../../../models/models.dart';
import '../../../services/api_service.dart';
import '../../../utils/formatters.dart';
import '../../../theme/app_theme.dart';

class IncomeTab extends StatelessWidget {
  const IncomeTab({
    super.key,
    required this.managerId,
    required this.selectedMonth,
    required this.selectedYear,
    required this.bores,
    required this.onRefresh,
    required this.readOnly,
  });

  final String managerId;
  final int selectedMonth;
  final int selectedYear;
  final List<Bore> bores;
  final Future<void> Function() onRefresh;
  final bool readOnly;

  double _paid(Bore bore) => bore.payments.fold<double>(0, (sum, payment) => sum + payment.amount);
  double _balance(Bore bore) => bore.totalBill - _paid(bore);

  @override
  Widget build(BuildContext context) {
    final payments = bores
        .expand((bore) => bore.payments
            .where((p) => p.date.month == selectedMonth && p.date.year == selectedYear)
            .map((p) => _PaymentItem(boreId: bore.id, boreNumber: bore.boreNumber, payment: p)))
        .toList()
      ..sort((a, b) => b.payment.date.compareTo(a.payment.date));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.t('Income'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (!readOnly)
              TextButton.icon(
                onPressed: () => _showPaymentDialog(context),
                icon: const Icon(Icons.add),
                label: Text(context.t('Record Payment')),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...payments.map((item) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.7),
                  child: ListTile(
                    title: Text('${item.boreNumber} \u2022 ${shortDate.format(item.payment.date)}'),
                    subtitle: Text(currencyInr.format(item.payment.amount)),
                    trailing: !readOnly
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(context, item),
                          )
                        : null,
                  ),
                ),
              ),
            )),
        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(context.t('No payments recorded yet.')),
          ),
      ],
    );
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    final api = context.read<ApiService>();
    Bore? selectedBore;
    String paidMethod = 'cash';
    final amountController = TextEditingController();

    final boresWithBalance = bores.where((bore) => _balance(bore) > 0).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: AppTheme.glassDecoration(borderRadius: 24, opacity: 0.85),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(context.t('Record Payment'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Bore>(
                        value: selectedBore,
                        items: boresWithBalance
                            .map((bore) => DropdownMenuItem(
                                  value: bore,
                                  child: Text('${bore.boreNumber} (Balance: ${currencyInr.format(_balance(bore))})'),
                                ))
                            .toList(),
                        onChanged: (value) => selectedBore = value,
                        decoration: InputDecoration(
                          labelText: context.t('Select Bore'),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: context.t('Amount Received'),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: (double.tryParse(amountController.text) ?? 0) > 0
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
                                                groupValue: paidMethod,
                                                onChanged: (v) => setDialogState(() => paidMethod = v!),
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
                                                groupValue: paidMethod,
                                                onChanged: (v) => setDialogState(() => paidMethod = v!),
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.t('Cancel'))),
                          const SizedBox(width: 8),
                          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(context.t('Save'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed != true || selectedBore == null) return;

    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0 || amount > _balance(selectedBore!)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('Enter a valid amount.'))));
      return;
    }

    await api.addPayment(managerId: managerId, boreId: selectedBore!.id, amount: amount, date: DateTime.now(), method: paidMethod);
    await onRefresh();
  }

  Future<void> _confirmDelete(BuildContext context, _PaymentItem item) async {
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
                  Text(context.t('Delete Payment'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                  const SizedBox(height: 8),
                  Text(context.t('This will remove the payment record.'), style: TextStyle(color: AppTheme.mutedForeground)),
                  const SizedBox(height: 24),
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

    await api.deletePayment(managerId: managerId, boreId: item.boreId, paymentId: item.payment.id);
    await onRefresh();
  }
}

class _PaymentItem {
  _PaymentItem({required this.boreId, required this.boreNumber, required this.payment});

  final String boreId;
  final String boreNumber;
  final Payment payment;
}
