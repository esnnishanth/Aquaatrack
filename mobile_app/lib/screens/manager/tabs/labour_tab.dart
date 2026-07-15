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

    final absentSet = <String>{};
    for (final a in worker.absenceRanges ?? <WorkerAbsenceRange>[]) {
      final fromNorm = DateTime(a.fromDate.year, a.fromDate.month, a.fromDate.day);
      final toNorm = DateTime(a.toDate.year, a.toDate.month, a.toDate.day);
      final start = fromNorm.isBefore(jd) ? DateTime(jd.year, jd.month, jd.day) : fromNorm;
      if (start.isAfter(now)) continue;
      final effEnd = (a.toDate.year >= 9999 || toNorm.isAfter(now)) ? now : toNorm;
      var cur = start;
      while (!cur.isAfter(effEnd)) {
        absentSet.add('${cur.year}-${cur.month}-${cur.day}');
        cur = cur.add(const Duration(days: 1));
      }
    }

    double earned = 0;
    DateTime cursor = DateTime(jd.year, jd.month, jd.day);

    while (!cursor.isAfter(now)) {
      final dim = DateTime(cursor.year, cursor.month + 1, 0).day;
      final monthEnd = DateTime(cursor.year, cursor.month, dim);
      final periodEnd = monthEnd.isBefore(now) ? monthEnd : now;

      int absentInPeriod = 0;
      var cur = cursor;
      while (!cur.isAfter(periodEnd)) {
        if (absentSet.contains('${cur.year}-${cur.month}-${cur.day}')) {
          absentInPeriod++;
        }
        cur = cur.add(const Duration(days: 1));
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
    DateTime? joinDate = worker.joiningDate;

    final allAbsences = worker.absenceRanges ?? <WorkerAbsenceRange>[];

    final absentSet = <String>{};
    for (final a in allAbsences) {
      final fromNorm = DateTime(a.fromDate.year, a.fromDate.month, a.fromDate.day);
      final toNorm = DateTime(a.toDate.year, a.toDate.month, a.toDate.day);
      final start = joinDate != null && fromNorm.isBefore(joinDate) ? DateTime(joinDate.year, joinDate.month, joinDate.day) : fromNorm;
      if (start.isAfter(now)) continue;
      final effEnd = (a.toDate.year >= 9999 || toNorm.isAfter(now)) ? now : toNorm;
      var cur = start;
      while (!cur.isAfter(effEnd)) {
        absentSet.add('${cur.year}-${cur.month}-${cur.day}');
        cur = cur.add(const Duration(days: 1));
      }
    }

    int totalAbsentDays = absentSet.length;

    int totalEligibleDays = 0;
    if (joinDate != null) {
      totalEligibleDays = now.difference(joinDate).inDays + 1;
    }

    final presentDays = (totalEligibleDays - totalAbsentDays).clamp(0, totalEligibleDays);

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
                      initialDate: joinDate ?? now,
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
                          joinDate = picked;
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
                          joinDate != null ? 'Join: ${joinDate!.day}/${joinDate!.month}/${joinDate!.year}' : 'Join: Not set',
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
                      _markAttendanceCalendar(context, worker: worker, effectiveJoiningDate: joinDate);
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
    final jdNorm = jd != null ? DateTime(jd.year, jd.month, jd.day) : null;

    int viewMonth = selectedMonth;
    int viewYear = selectedYear;

    String dk(int y, int m, int d) => '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

    final absentDays = <String>{};
    for (final a in worker.absenceRanges ?? <WorkerAbsenceRange>[]) {
      final fromNorm = DateTime(a.fromDate.year, a.fromDate.month, a.fromDate.day);
      final toNorm = DateTime(a.toDate.year, a.toDate.month, a.toDate.day);
      final start = jdNorm != null && fromNorm.isBefore(jdNorm) ? jdNorm : fromNorm;
      final effEnd = (a.toDate.year >= 9999 || toNorm.isAfter(now)) ? now : toNorm;
      var cur = start;
      while (!cur.isAfter(effEnd)) {
        absentDays.add(dk(cur.year, cur.month, cur.day));
        cur = cur.add(const Duration(days: 1));
      }
    }

    bool ongoing = false;

    bool isPresent(int y, int m, int d) {
      final dt = DateTime(y, m, d);
      if (jdNorm != null && dt.isBefore(jdNorm)) return false;
      if (dt.isAfter(now)) return false;
      return !absentDays.contains(dk(y, m, d));
    }

    bool isDisabled(int y, int m, int d) {
      final dt = DateTime(y, m, d);
      if (jdNorm != null && dt.isBefore(jdNorm)) return true;
      if (dt.isAfter(now)) return true;
      return false;
    }

    void toggleDay(int y, int m, int d) {
      final key = dk(y, m, d);
      if (absentDays.contains(key)) {
        absentDays.remove(key);
      } else {
        absentDays.add(key);
      }
    }

    void toggleRangeFrom(DateTime dt) {
      bool anyAbsent = false;
      var cur = dt;
      while (!cur.isAfter(now)) {
        if (absentDays.contains(dk(cur.year, cur.month, cur.day))) {
          anyAbsent = true;
          break;
        }
        cur = cur.add(const Duration(days: 1));
      }
      cur = dt;
      while (!cur.isAfter(now)) {
        final key = dk(cur.year, cur.month, cur.day);
        if (anyAbsent) {
          absentDays.remove(key);
        } else {
          absentDays.add(key);
        }
        cur = cur.add(const Duration(days: 1));
      }
      ongoing = !anyAbsent;
    }

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    bool canGoPrev() => !(viewYear == 2000 && viewMonth == 1);
    bool canGoNext() => !(viewYear == now.year && viewMonth == now.month);

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
                    final disabled = isDisabled(viewYear, viewMonth, day);
                    final checked = isPresent(viewYear, viewMonth, day);
                    return GestureDetector(
                      onTap: disabled ? null : () {
                        setInnerState(() {
                          toggleDay(viewYear, viewMonth, day);
                        });
                      },
                      onLongPress: disabled ? null : () {
                        setInnerState(() {
                          toggleRangeFrom(DateTime(viewYear, viewMonth, day));
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
                    final allKeys = absentDays.toList()..sort();

                    final ranges = <Map<String, String>>[];
                    if (allKeys.isNotEmpty) {
                      var p = allKeys[0].split('-');
                      DateTime rangeStart = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                      DateTime rangeEnd = rangeStart;

                      for (var i = 1; i < allKeys.length; i++) {
                        p = allKeys[i].split('-');
                        final currDate = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                        if (currDate.difference(rangeEnd).inDays == 1) {
                          rangeEnd = currDate;
                        } else {
                          ranges.add({
                            'fromDate': rangeStart.toIso8601String(),
                            'toDate': rangeEnd.toIso8601String(),
                          });
                          rangeStart = currDate;
                          rangeEnd = currDate;
                        }
                      }
                      if (ongoing) {
                        rangeEnd = DateTime(9999, 12, 31);
                      }
                      ranges.add({
                        'fromDate': rangeStart.toIso8601String(),
                        'toDate': rangeEnd.toIso8601String(),
                      });
                    } else if (ongoing) {
                      // Should not happen, but guard
                      ongoing = false;
                    }

                    await api.replaceWorkerAbsences(
                      managerId: manager.id,
                      workerId: worker.id,
                      absenceRanges: ranges,
                    );

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
