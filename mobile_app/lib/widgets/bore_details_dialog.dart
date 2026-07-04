import 'dart:ui';
import 'package:flutter/material.dart';
import '../localization/ext.dart';
import '../models/models.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

void showBoreDetailsDialog(BuildContext context, Bore bore, {String managerName = ''}) {
  double paid(Bore b) => b.payments.fold<double>(0, (sum, payment) => sum + payment.amount);
  double balance(Bore b) => b.totalBill - paid(b);
  double totalPipeLength = bore.pipesUsed.fold<double>(0, (sum, pipe) => sum + pipe.length);
  double boreCommission = bore.totalFeet * bore.agentCommissionPerFeet;
  double pipeCommission = totalPipeLength * bore.agentCommissionPerPipeFoot;
  double steelCommission = bore.steelFeet * bore.steelAgentCommission;
  double totalCommission = boreCommission + pipeCommission + steelCommission;
  double remainingCommission = totalCommission - bore.commissionSettled;

  showDialog(
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text('Bore ${bore.boreNumber}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailRow(context.t('Date'), shortDate.format(bore.date)),
                  _detailRow(context.t('Agent'), bore.agentName),
                  if (bore.agentCommissionPerFeet > 0 || bore.agentCommissionPerPipeFoot > 0) ...[
                    const Divider(height: 24),
                    Text(context.t('Commission'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                    const SizedBox(height: 6),
                    if (bore.agentCommissionPerFeet > 0)
                      _detailRow(context.t('Bore Comm.'), '${currencyInr.format(boreCommission)} (${bore.totalFeet} ft @ ${currencyInr.format(bore.agentCommissionPerFeet)}/ft)'),
                    if (bore.agentCommissionPerPipeFoot > 0)
                      _detailRow(context.t('Pipe Comm.'), '${currencyInr.format(pipeCommission)} ($totalPipeLength ft @ ${currencyInr.format(bore.agentCommissionPerPipeFoot)}/ft)'),
                    if (bore.steelAgentCommission > 0)
                      _detailRow(context.t('Steel Comm.'), '${currencyInr.format(steelCommission)} (${bore.steelFeet} ft @ ${currencyInr.format(bore.steelAgentCommission)}/ft)'),
                    _detailRow(context.t('Total Comm.'), currencyInr.format(totalCommission), bold: true, color: AppTheme.accent),
                    if (bore.commissionSettled > 0)
                      _detailRow(context.t('Settled / Remaining'), '${currencyInr.format(bore.commissionSettled)} / ${currencyInr.format(remainingCommission)}', color: AppTheme.accent),
                  ],
                  const Divider(height: 24),
                  _detailRow(context.t('Total Feet'), '${bore.totalFeet} ft'),
                  if (bore.feetEntries.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(context.t('Feet Entries:'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
                    const SizedBox(height: 4),
                    ...bore.feetEntries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text('• ${e.length} ft @ ${currencyInr.format(e.pricePerFeet)}/ft',
                        style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                    )),
                  ] else ...[
                    _detailRow(context.t('Avg. Rate'), '${currencyInr.format(bore.pricePerFeet)}/ft'),
                  ],
                  if (bore.pipesUsed.isNotEmpty) ...[
                    const Divider(height: 16),
                    Text(context.t('Pipes Used:'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
                    const SizedBox(height: 4),
                    ...bore.pipesUsed.map((p) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text('• Size ${p.size}", ${p.length} ft @ ${currencyInr.format(p.pricePerPipeFoot)}/ft',
                        style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                    )),
                  ],
                  if (bore.steelFeet > 0) ...[
                    const Divider(height: 16),
                    Text(context.t('Steel:'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text('• ${bore.steelFeet} ft @ ${currencyInr.format(bore.steelPricePerFeet)}/ft + Welding ${currencyInr.format(bore.steelWeldingCharge)}',
                        style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                    ),
                  ],
                  const Divider(height: 24),
                  _detailRow(context.t('Total Bill'), currencyInr.format(bore.totalBill), bold: true),
                  _detailRow(context.t('Payments Made'), currencyInr.format(paid(bore))),
                  _detailRow(context.t('Balance'), currencyInr.format(balance(bore)),
                    bold: true,
                    color: balance(bore) > 0 ? AppTheme.destructive : AppTheme.success),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ReportService.shareCustomerBill(bore: bore, managerName: managerName);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            child: Text(context.t('Share')),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.foreground,
                            side: BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          child: Text(context.t('Close')),
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
}

Widget _detailRow(String label, String value, {bool bold = false, Color? color}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppTheme.foreground,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );
}
