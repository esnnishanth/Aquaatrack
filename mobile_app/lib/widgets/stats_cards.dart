import 'dart:ui';
import 'package:flutter/material.dart';
import '../localization/ext.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class StatsCards extends StatelessWidget {
  const StatsCards({super.key, required this.bores, required this.normalExpenses, required this.labourPayments});

  final List<Bore> bores;
  final List<NormalExpense> normalExpenses;
  final List<LabourPayment> labourPayments;

  @override
  Widget build(BuildContext context) {
    final totalIncome = bores.expand((bore) => bore.payments).fold<double>(0, (sum, p) => sum + p.amount);
    final totalNormalExpenses = normalExpenses
        .where((e) => e.createdBy != 'owner')
        .fold<double>(0, (sum, e) => sum + e.amount);
    final totalLabour = labourPayments
        .where((p) => p.createdBy != 'owner')
        .fold<double>(0, (sum, p) => sum + p.amount);
    final balance = totalIncome - totalNormalExpenses - totalLabour;

    final totalBoreFeet = bores.fold<double>(0, (sum, bore) => sum + bore.totalFeet);
    final totalPipeLength = bores.fold<double>(
      0,
      (sum, bore) => sum + bore.pipesUsed.fold<double>(0, (pipeSum, pipe) => pipeSum + pipe.length),
    );

    return Column(
      children: [
        _GlassStatCard(title: context.t('Balance'), value: currencyInr.format(balance), subtitle: context.t('After all expenses'), icon: Icons.account_balance_wallet_outlined, accent: balance >= 0),
        const SizedBox(height: 12),
        _GlassStatCard(title: context.t('Total Bore Feet'), value: '${totalBoreFeet.toStringAsFixed(0)} ft', subtitle: context.t('All time'), icon: Icons.trending_up, accent: null),
        const SizedBox(height: 12),
        _GlassStatCard(title: context.t('Total Pipe Length'), value: '${totalPipeLength.toStringAsFixed(0)} ft', subtitle: context.t('All time'), icon: Icons.view_week_outlined, accent: null),
      ],
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  const _GlassStatCard({required this.title, required this.value, required this.subtitle, required this.icon, this.accent});

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool? accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.8),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: accent == true
                      ? AppTheme.primaryGradient
                      : accent == false
                          ? LinearGradient(colors: [AppTheme.destructive, AppTheme.destructive.withValues(alpha: 0.7)])
                          : LinearGradient(colors: [AppTheme.accent, AppTheme.accentLight]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (accent == true ? AppTheme.primary : accent == false ? AppTheme.destructive : AppTheme.accent).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.foreground)),
                    Text(subtitle, style: TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
