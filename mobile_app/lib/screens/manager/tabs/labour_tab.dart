import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../localization/ext.dart';
import '../../../models/models.dart';
import '../../../services/api_service.dart';
import '../../../services/report_service.dart';
import '../../../utils/formatters.dart';

class LabourTab extends StatelessWidget {
  const LabourTab({
    super.key,
    required this.manager,
    required this.selectedMonth,
    required this.selectedYear,
    required this.workers,
    required this.onRefresh,
    required this.readOnly,
  });

  final Manager manager;
  final int selectedMonth;
  final int selectedYear;
  final List<Worker> workers;
  final Future<void> Function() onRefresh;
  final bool readOnly;

  double _balanceForWorker(Worker worker) {
    final jd = worker.joiningDate;
    if (jd == null) return -worker.amountPaid;
    final now = DateTime.now();
    final absences = worker.absenceRanges ?? [];

    double earned = 0;
    DateTime cursor = DateTime(jd.year, jd.month, jd.day);

    while (!cursor.isAfter(now)) {
      final dim = DateTime(cursor.year, cursor.month + 1, 0).day;
      final monthEnd = DateTime(cursor.year, cursor.month, dim);
      final periodEnd = monthEnd.isBefore(now) ? monthEnd : now;

      int absentInPeriod = 0;
      for (final a in absences) {
        final fromNorm = DateTime(a.fromDate.year, a.fromDate.month, a.fromDate.day);
        final toNorm = DateTime(a.toDate.year, a.toDate.month, a.toDate.day);
        final os = fromNorm.isAfter(cursor) ? fromNorm : cursor;
        final oe = toNorm.isBefore(periodEnd) ? toNorm : periodEnd;
        if (!os.isAfter(oe)) absentInPeriod += oe.difference(os).inDays + 1;
      }

      final daysInPeriod = periodEnd.difference(cursor).inDays + 1;
      final dailyWage = worker.monthlySalary / dim;
      earned += (daysInPeriod - absentInPeriod) * dailyWage;

      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return earned - worker.amountPaid;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.t('Workers'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Flexible(
                child: Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _downloadReport(context),
                      icon: const Icon(Icons.download_outlined),
                      label: Text(context.t('Report')),
                    ),
                    if (!readOnly)
                      TextButton.icon(
                        onPressed: () => _showWorkerDialog(context),
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(context.t('Add')),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...workers.map(
            (worker) => Card(
              child: ListTile(
                onTap: () => _showAttendanceDialog(context, worker: worker),
                title: Text(worker.name),
                subtitle: Text(
                  'Balance: ${currencyInr.format(_balanceForWorker(worker))}',
                ),
                trailing: !readOnly
                    ? PopupMenuButton<String>(
                        onSelected: (value) => _handleAction(context, value, worker),
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'edit', child: Text(context.t('Edit'))),
                          PopupMenuItem(value: 'delete', child: Text(context.t('Delete'))),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          if (workers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(context.t('No workers added yet.')),
            ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action, Worker worker) {
    if (action == 'edit') {
      _showWorkerDialog(context, worker: worker);
    } else if (action == 'delete') {
      _confirmDelete(context, worker);
    }
  }

  Future<void> _downloadReport(BuildContext context) async {
    if (workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('No workers to generate report'))),
      );
      return;
    }

    final worker = await showDialog<Worker>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Select Worker')),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: workers
                .map((w) => ListTile(
                      title: Text(w.name),
                      onTap: () => Navigator.of(context).pop(w),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t('Cancel')),
          ),
        ],
      ),
    );

    if (worker == null) return;

    try {
      await ReportService.printWorkerReport(manager: manager, worker: worker);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Worker worker) async {
    final api = context.read<ApiService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Delete Worker')),
        content: Text(context.t('Are you sure you want to delete this worker?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.t('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.t('Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await api.deleteWorker(managerId: manager.id, workerId: worker.id);
    await onRefresh();
  }

  Future<void> _showWorkerDialog(BuildContext context, {Worker? worker}) async {
    final api = context.read<ApiService>();
    final nameController = TextEditingController(text: worker?.name ?? '');
    final placeController = TextEditingController(text: worker?.place ?? '');
    final salaryController = TextEditingController(
      text: worker?.monthlySalary.toString() ?? '',
    );
    DateTime? joiningDate = worker?.joiningDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(worker == null ? context.t('Add Worker') : context.t('Edit Worker')),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: context.t('Name')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: placeController,
                  decoration: InputDecoration(labelText: context.t('Place')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: salaryController,
                  decoration: InputDecoration(labelText: context.t('Monthly Salary')),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: joiningDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => joiningDate = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: 'Joining Date'),
                    child: Text(
                      joiningDate != null
                          ? '${joiningDate!.day}/${joiningDate!.month}/${joiningDate!.year}'
                          : 'Select date',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.t('Cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.t('Save')),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final name = nameController.text.trim();
    final place = placeController.text.trim();
    final salary = double.tryParse(salaryController.text.trim()) ?? 0;

    if (worker == null) {
      await api.addWorker(
        managerId: manager.id,
        name: name,
        place: place,
        monthlySalary: salary,
        joiningDate: joiningDate,
      );
    } else {
      await api.updateWorker(
        managerId: manager.id,
        workerId: worker.id,
        name: name,
        place: place,
        monthlySalary: salary,
        joiningDate: joiningDate,
      );
    }

    await onRefresh();
  }

  void _showAbsentHistory(BuildContext context, {required List<WorkerAbsenceRange> allAbsences}) {
    if (allAbsences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No absences recorded')),
      );
      return;
    }
    final dates = <String>[];
    for (final a in allAbsences) {
      var d = a.fromDate;
      while (!d.isAfter(a.toDate)) {
        dates.add('${d.day}/${d.month}/${d.year}');
        d = d.add(const Duration(days: 1));
      }
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Absent Dates (${dates.length} days)'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: dates.map((d) => Chip(label: Text(d))).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAttendanceDialog(BuildContext context, {required Worker worker}) async {
    final now = DateTime.now();
    DateTime? _jd = worker.joiningDate;

    final allAbsences = worker.absenceRanges ?? <WorkerAbsenceRange>[];

    int totalAbsentDays = 0;
    for (final absence in allAbsences) {
      final effStart = _jd != null && absence.fromDate.isBefore(_jd!) ? _jd! : absence.fromDate;
      if (effStart.isAfter(now)) continue;
      final effEnd = absence.toDate.isAfter(now) ? now : absence.toDate;
      if (effEnd.isBefore(effStart)) continue;
      totalAbsentDays += effEnd.difference(effStart).inDays + 1;
    }

    int totalEligibleDays = 0;
    if (_jd != null) {
      totalEligibleDays = now.difference(_jd!).inDays + 1;
    }

    final presentDays = totalEligibleDays - totalAbsentDays;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(worker.name)),
              if (!readOnly)
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _jd ?? now,
                      firstDate: DateTime(2000),
                      lastDate: now,
                    );
                    if (picked != null) {
                      final api = context.read<ApiService>();
                      try {
                        await api.updateWorker(
                          managerId: manager.id,
                          workerId: worker.id,
                          name: worker.name,
                          place: worker.place,
                          monthlySalary: worker.monthlySalary,
                          joiningDate: picked,
                        );
                        await onRefresh();
                        if (context.mounted) {
                          _jd = picked;
                          setState(() {});
                        }
                      } catch (_) {}
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _jd != null ? 'Join: ${_jd!.day}/${_jd!.month}/${_jd!.year}' : 'Join: Not set',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Salary: ${currencyInr.format(worker.monthlySalary)}'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Present: $presentDays days  |  '),
                  GestureDetector(
                    onTap: () => _showAbsentHistory(context, allAbsences: allAbsences),
                    child: Text(
                      'Absent: $totalAbsentDays days',
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              if (worker.place.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Place: ${worker.place}'),
              ],
              const SizedBox(height: 20),
              if (!readOnly)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _markAttendanceCalendar(context, worker: worker, effectiveJoiningDate: _jd);
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Mark Attendance'),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.t('Close')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAttendanceCalendar(BuildContext context, {required Worker worker, DateTime? effectiveJoiningDate}) async {
    final api = context.read<ApiService>();
    final now = DateTime.now();
    final jd = effectiveJoiningDate ?? worker.joiningDate;
    int viewMonth = selectedMonth;
    int viewYear = selectedYear;

    final monthState = <String, Set<int>>{};
    DateTime? _absentFromDate;

    Set<int> presentSet() {
      final key = '$viewYear-$viewMonth';
      if (!monthState.containsKey(key)) {
        final dim = DateTime(viewYear, viewMonth + 1, 0).day;
        final s = <int>{};
        for (var d = 1; d <= dim; d++) {
          final dt = DateTime(viewYear, viewMonth, d);
          bool abs = false;
          if (jd != null) {
            final jdNorm = DateTime(jd.year, jd.month, jd.day);
            if (dt.isBefore(jdNorm)) abs = true;
          }
          if (!abs) {
            for (final a in (worker.absenceRanges ?? <WorkerAbsenceRange>[])) {
              final fromNorm = DateTime(a.fromDate.year, a.fromDate.month, a.fromDate.day);
              final toNorm = DateTime(a.toDate.year, a.toDate.month, a.toDate.day);
              if (!dt.isBefore(fromNorm) && !dt.isAfter(toNorm)) {
                abs = true;
                break;
              }
            }
          }
          if (!abs && _absentFromDate != null) {
            final afdNorm = DateTime(_absentFromDate!.year, _absentFromDate!.month, _absentFromDate!.day);
            if (!dt.isBefore(afdNorm)) abs = true;
          }
          if (!abs) s.add(d);
        }
        monthState[key] = s;
      }
      return monthState[key]!;
    }

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    bool canGoPrev() => !(viewYear == 2000 && viewMonth == 1);
    bool canGoNext() => !(viewYear == now.year && viewMonth == now.month);

    bool isDisabled(int day) {
      final dt = DateTime(viewYear, viewMonth, day);
      if (jd != null) {
        final jdNorm = DateTime(jd.year, jd.month, jd.day);
        if (dt.isBefore(jdNorm)) return true;
      }
      if (dt.isAfter(now)) return true;
      return false;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInnerState) {
          final dim = DateTime(viewYear, viewMonth + 1, 0).day;

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (canGoPrev())
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      if (viewMonth == 1) { viewMonth = 12; viewYear--; }
                      else { viewMonth--; }
                      setInnerState(() {});
                    },
                  )
                else
                  const SizedBox(width: 48),
                Text('${monthNames[viewMonth - 1]} $viewYear'),
                if (canGoNext())
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      if (viewMonth == 12) { viewMonth = 1; viewYear++; }
                      else { viewMonth++; }
                      setInnerState(() {});
                    },
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
            content: SizedBox(
              width: 340,
              height: 420,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(dim, (i) {
                    final day = i + 1;
                    final disabled = isDisabled(day);
                    final checked = presentSet().contains(day);
                    return GestureDetector(
                      onTap: disabled ? null : () {
                        setInnerState(() {
                          final s = presentSet();
                          if (s.contains(day)) s.remove(day);
                          else s.add(day);
                        });
                      },
                      onLongPress: disabled ? null : () {
                        setInnerState(() {
                          final dt = DateTime(viewYear, viewMonth, day);
                          if (_absentFromDate != null &&
                              _absentFromDate!.year == dt.year &&
                              _absentFromDate!.month == dt.month &&
                              _absentFromDate!.day == dt.day) {
                            _absentFromDate = null;
                          } else {
                            _absentFromDate = dt;
                          }
                          monthState.clear();
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 44,
                        decoration: BoxDecoration(
                          color: disabled
                              ? Colors.grey.withValues(alpha: 0.05)
                              : checked
                                  ? const Color(0xFF059669).withValues(alpha: 0.12)
                                  : const Color(0xFFDC2626).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: disabled
                                ? Colors.grey.withValues(alpha: 0.15)
                                : checked
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626),
                            width: checked ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: checked ? FontWeight.w700 : FontWeight.w400,
                                color: disabled ? Colors.grey.withValues(alpha: 0.4) : null,
                              ),
                            ),
                            Icon(
                              disabled
                                  ? Icons.remove
                                  : checked
                                      ? Icons.check_box
                                      : Icons.indeterminate_check_box,
                              size: 14,
                              color: disabled
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : checked
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.t('Cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final jdNorm = jd != null ? DateTime(jd.year, jd.month, jd.day) : null;

                    for (final entry in monthState.entries) {
                      final parts = entry.key.split('-');
                      final y = int.parse(parts[0]);
                      final m = int.parse(parts[1]);
                      final dim = DateTime(y, m + 1, 0).day;
                      final present = entry.value;

                      final newAbsent = <int>{};
                      for (var d = 1; d <= dim; d++) {
                        final dt = DateTime(y, m, d);
                        if (jdNorm != null && dt.isBefore(jdNorm)) continue;
                        if (dt.isAfter(now)) continue;
                        if (!present.contains(d)) newAbsent.add(d);
                      }

                      bool unchanged = true;
                      final existingInMonth = (worker.absenceRanges ?? <WorkerAbsenceRange>[])
                          .where((a) => !a.fromDate.isAfter(DateTime(y, m, dim)) && !a.toDate.isBefore(DateTime(y, m, 1)))
                          .toList();
                      final existingDays = <int>{};
                      for (final a in existingInMonth) {
                        final fromNorm = DateTime(a.fromDate.year, a.fromDate.month, a.fromDate.day);
                        final toNorm = DateTime(a.toDate.year, a.toDate.month, a.toDate.day);
                        final effStart = fromNorm.isBefore(DateTime(y, m, 1)) ? DateTime(y, m, 1) : fromNorm;
                        final effEnd = toNorm.isAfter(DateTime(y, m, dim)) ? DateTime(y, m, dim) : toNorm;
                        var cur = effStart;
                        while (!cur.isAfter(effEnd)) {
                          existingDays.add(cur.day);
                          cur = cur.add(const Duration(days: 1));
                        }
                      }
                      if (existingDays.length != newAbsent.length || !existingDays.containsAll(newAbsent)) {
                        unchanged = false;
                      }
                      if (unchanged) continue;

                      for (final a in existingInMonth) {
                        await api.deleteWorkerAbsence(
                          managerId: manager.id,
                          workerId: worker.id,
                          absenceId: a.id,
                        );
                      }

                      final sorted = newAbsent.toList()..sort();
                      if (sorted.isNotEmpty) {
                        int rs = sorted[0], re = sorted[0];
                        for (var j = 1; j < sorted.length; j++) {
                          if (sorted[j] == re + 1) {
                            re = sorted[j];
                          } else {
                            await api.addWorkerAbsence(
                              managerId: manager.id,
                              workerId: worker.id,
                              fromDate: DateTime(y, m, rs),
                              toDate: DateTime(y, m, re),
                            );
                            rs = sorted[j];
                            re = sorted[j];
                          }
                        }
                        await api.addWorkerAbsence(
                          managerId: manager.id,
                          workerId: worker.id,
                          fromDate: DateTime(y, m, rs),
                          toDate: DateTime(y, m, re),
                        );
                      }
                    }

                    if (_absentFromDate != null) {
                      final afdNorm = DateTime(_absentFromDate!.year, _absentFromDate!.month, _absentFromDate!.day);
                      if (!afdNorm.isAfter(now)) {
                        final existingAfter = (worker.absenceRanges ?? <WorkerAbsenceRange>[])
                            .where((a) {
                              final toNorm = DateTime(a.toDate.year, a.toDate.month, a.toDate.day);
                              return !toNorm.isBefore(afdNorm);
                            })
                            .toList();
                        bool alreadyCovered = false;
                        for (final a in existingAfter) {
                          final fromNorm = DateTime(a.fromDate.year, a.fromDate.month, a.fromDate.day);
                          if (!fromNorm.isAfter(afdNorm)) {
                            alreadyCovered = true;
                            break;
                          }
                        }
                        if (!alreadyCovered) {
                          for (final a in existingAfter) {
                            await api.deleteWorkerAbsence(
                              managerId: manager.id,
                              workerId: worker.id,
                              absenceId: a.id,
                            );
                          }
                          await api.addWorkerAbsence(
                            managerId: manager.id,
                            workerId: worker.id,
                            fromDate: _absentFromDate!,
                            toDate: now,
                          );
                        }
                      }
                    }

                    await onRefresh();
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save attendance: $e')),
                      );
                    }
                  }
                },
                child: Text(context.t('Save')),
              ),
            ],
          );
        },
      ),
    );
  }
}
