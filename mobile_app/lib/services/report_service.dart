import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

final _pdfMoney = NumberFormat.decimalPattern('en_IN');

String _money(num value) => 'Rs. ${_pdfMoney.format(value)}';

class ReportService {
  static pw.Table fromStyledTextArray({
    required List<String> headers,
    required List<List<String>> data,
    Map<int, pw.TableColumnWidth>? columnWidths,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      columnWidths: columnWidths,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(AppTheme.primary.toARGB32())),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
      cellAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      rowDecoration: const pw.BoxDecoration(),
    );
  }

  static Future<void> printMonthlyReport({
    required Manager manager,
    required DateTime month,
  }) async {
    final doc = pw.Document();
    final monthName = '${month.month.toString().padLeft(2, '0')}-${month.year}';

    bool sameMonth(DateTime date) =>
        date.month == month.month && date.year == month.year;

    final income = manager.data.bores
        .expand((bore) => bore.payments)
        .where((payment) => sameMonth(payment.date))
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final normalExpenses = manager.data.normalExpenses
        .where((expense) => sameMonth(expense.date))
        .toList();
    final labourPayments = manager.data.labourPayments
        .where((payment) => sameMonth(payment.date))
        .toList();

    final expensesTotal =
        normalExpenses.fold<double>(0, (sum, e) => sum + e.amount) +
        labourPayments.fold<double>(0, (sum, e) => sum + e.amount);

    final dieselExpense = normalExpenses
        .where((e) => e.description.toLowerCase().contains('diesel'))
        .fold<double>(0, (sum, e) => sum + e.amount);

    final tyreExpense = normalExpenses
        .where((e) => e.description.toLowerCase().contains('tyre'))
        .fold<double>(0, (sum, e) => sum + e.amount);

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'AquaTrack Monthly Summary',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Manager: ${manager.name}'),
            pw.Text('Month: $monthName'),
            pw.SizedBox(height: 16),
            pw.Container(
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: fromStyledTextArray(
                headers: ['Metric', 'Amount (INR)'],
                data: [
                  ['Total Income', _money(income)],
                  ['Total Expenses', _money(expensesTotal)],
                  ['Profit / Loss', _money(income - expensesTotal)],
                  ['Diesel Expense', _money(dieselExpense)],
                  ['Tyre Expense', _money(tyreExpense)],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static Future<void> printExpenseReport({
    required Manager manager,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final doc = pw.Document();
    final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);

    bool inRange(DateTime date) => !date.isBefore(start) && !date.isAfter(end);

    final normalExpenses = manager.data.normalExpenses
        .where((e) => inRange(e.date))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final labourPayments = manager.data.labourPayments
        .where((p) => inRange(p.date))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final total = normalExpenses
            .fold<double>(0, (sum, e) => sum + e.amount) +
        labourPayments.fold<double>(0, (sum, p) => sum + p.amount);

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'AquaTrack Expense Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Manager: ${manager.name}'),
            pw.Text('Period: ${shortDate.format(start)} - ${shortDate.format(end)}'),
            pw.SizedBox(height: 16),
            pw.Container(
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: fromStyledTextArray(
                headers: ['Metric', 'Amount (INR)'],
                data: [
                  ['Total Expenses', _money(total)],
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Expense Details',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            fromStyledTextArray(
              headers: ['Date', 'Category', 'Description', 'Amount'],
              data: [
                ...normalExpenses.map(
                  (e) => [
                    e.date.toIso8601String().split('T').first,
                    'Normal',
                    e.description,
                    e.amount.toStringAsFixed(0),
                  ],
                ),
                ...labourPayments.map(
                  (p) {
                    final idx = manager.data.workers.indexWhere((w) => w.id == p.workerId);
                    final label = idx != -1 ? manager.data.workers[idx].name : p.workerId;
                    return [
                      p.date.toIso8601String().split('T').first,
                      'Labour',
                      label,
                      p.amount.toStringAsFixed(0),
                    ];
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static Future<void> printWorkerReport({
    required Manager manager,
    required Worker worker,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final jd = worker.joiningDate;
    final payments = manager.data.labourPayments
        .where((payment) => payment.workerId == worker.id)
        .toList();

    final absences = worker.absenceRanges ?? [];
    double earned = 0;

    if (jd != null) {
      int completeMonths = 0;
      DateTime cursor = DateTime(jd.year, jd.month, jd.day);
      while (true) {
        int nm = cursor.month + 1;
        int ny = cursor.year;
        if (nm > 12) { nm = 1; ny++; }
        int nd = jd.day;
        int dim = DateTime(ny, nm + 1, 0).day;
        if (nd > dim) nd = dim;
        final next = DateTime(ny, nm, nd);
        if (next.isAfter(now)) break;
        cursor = next;
        completeMonths++;
      }

      earned = completeMonths * worker.monthlySalary;

      int remainingDays = now.difference(cursor).inDays;
      if (remainingDays > 0) {
        final curDim = DateTime(now.year, now.month + 1, 0).day;
        final dailyWage = worker.monthlySalary / curDim;
        int absentRemaining = 0;
        for (final a in absences) {
          final os = a.fromDate.isAfter(cursor) ? a.fromDate : cursor;
          final oe = a.toDate.isBefore(now) ? a.toDate : now;
          if (!os.isAfter(oe)) absentRemaining += oe.difference(os).inDays + 1;
        }
        earned += (remainingDays - absentRemaining) * dailyWage;
      }
    }

    int totalAbsentDays = 0;
    if (jd != null) {
      for (final a in absences) {
        final os = a.fromDate.isAfter(jd) ? a.fromDate : jd;
        final oe = a.toDate.isBefore(now) ? a.toDate : now;
        if (!os.isAfter(oe)) totalAbsentDays += oe.difference(os).inDays + 1;
      }
    }
    final totalEligibleDays = jd != null ? now.difference(jd).inDays + 1 : 0;
    final totalPresentDays = totalEligibleDays - totalAbsentDays;
    final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final balance = earned - totalPaid;

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'AquaTrack Worker Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Worker: ${worker.name}'),
            pw.Text('Manager: ${manager.name}'),
            pw.SizedBox(height: 16),
            fromStyledTextArray(
              headers: ['Metric', 'Amount (INR)'],
              data: [
                ['Earned (Present Days)', _money(earned)],
                ['Total Paid', _money(totalPaid)],
                ['Outstanding Balance', _money(balance)],
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                children: [
                  pw.Text('Days Present: $totalPresentDays    Days Absent: $totalAbsentDays'),
                  pw.SizedBox(height: 8),
                  fromStyledTextArray(
                    headers: ['S.No', 'From', 'To'],
                    data: worker.absenceRanges != null && worker.absenceRanges!.isNotEmpty
                        ? List.generate(worker.absenceRanges!.length, (i) {
                            final a = worker.absenceRanges![i];
                            return [
                              '${i + 1}',
                              shortDate.format(a.fromDate),
                              shortDate.format(a.toDate),
                            ];
                          })
                        : [['-', 'No absences marked', '']],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Payment History',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            fromStyledTextArray(
              headers: ['Date', 'Amount'],
              data: payments
                  .map(
                    (payment) => [
                      payment.date.toIso8601String().split('T').first,
                      payment.amount.toStringAsFixed(0),
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }
  static Future<void> printAgentCommissionReport({
    required Manager manager,
    required Agent agent,
    DateTime? fromDate,
    DateTime? toDate,
    bool simulateSettlement = false,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final startSource = fromDate ?? DateTime(now.year, now.month, 1);
    final endSource = toDate ?? DateTime(now.year, now.month + 1, 0);
    final start = DateTime(
      startSource.year,
      startSource.month,
      startSource.day,
    );
    final end = DateTime(
      endSource.year,
      endSource.month,
      endSource.day,
      23,
      59,
      59,
      999,
    );

    bool inRange(DateTime date) => !date.isBefore(start) && !date.isAfter(end);

    double totalPipeLength(Bore bore) =>
        bore.pipesUsed.fold<double>(0, (sum, pipe) => sum + pipe.length);
    double boreBalance(Bore bore) =>
        bore.totalBill -
        bore.payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    double boreCommission(Bore bore) =>
        bore.totalFeet * bore.agentCommissionPerFeet;
    double pipeCommission(Bore bore) =>
        totalPipeLength(bore) * bore.agentCommissionPerPipeFoot;
    double steelCommission(Bore bore) =>
        bore.steelFeet * bore.steelAgentCommission;
    double totalCommission(Bore bore) =>
        boreCommission(bore) + pipeCommission(bore) + steelCommission(bore);

    final bores =
        manager.data.bores
            .where((bore) => bore.agentName == agent.name && inRange(bore.date))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final totalBoreFeet = bores.fold<double>(
      0,
      (sum, bore) => sum + bore.totalFeet,
    );
    final totalBoreCommission = bores.fold<double>(
      0,
      (sum, bore) => sum + boreCommission(bore),
    );
    final totalPipeCommission = bores.fold<double>(
      0,
      (sum, bore) => sum + pipeCommission(bore),
    );
    final totalSteelCommission = bores.fold<double>(
      0,
      (sum, bore) => sum + steelCommission(bore),
    );
    final totalCommissionAmount = totalBoreCommission + totalPipeCommission + totalSteelCommission;
    final totalBoreBalance = bores.fold<double>(
      0,
      (sum, bore) => sum + boreBalance(bore),
    );
    final totalPipeFeet = bores.fold<double>(
      0,
      (sum, bore) => sum + totalPipeLength(bore),
    );
    final totalSteelFeet = bores.fold<double>(
      0,
      (sum, bore) => sum + bore.steelFeet,
    );
    final settlementAmount =
        simulateSettlement && totalBoreBalance > 0 && totalCommissionAmount > 0
        ? (totalBoreBalance < totalCommissionAmount
              ? totalBoreBalance
              : totalCommissionAmount)
        : 0.0;
    final displayBalance = totalBoreBalance - settlementAmount;
    final displayCommission = totalCommissionAmount - settlementAmount;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(AppTheme.primary.toARGB32()),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'AquaTrack Agent Commission Report',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Manager: ${manager.name}',
                  style: const pw.TextStyle(color: PdfColors.white),
                ),
                pw.Text(
                  'Agent: ${agent.name}',
                  style: const pw.TextStyle(color: PdfColors.white),
                ),
                pw.Text(
                  'Period: ${longDate.format(start)} - ${longDate.format(end)}',
                  style: const pw.TextStyle(color: PdfColors.white),
                ),
                pw.Text(
                  'Settlement Mode: ${simulateSettlement ? 'On' : 'Off'}',
                  style: const pw.TextStyle(color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          fromStyledTextArray(
            headers: const ['Metric', 'Amount (INR)'],
            data: [
              ['Total Bore Feet', '${totalBoreFeet.toStringAsFixed(0)} ft'],
              ['Total Pipe Feet', '${totalPipeFeet.toStringAsFixed(0)} ft'],
              ['Total Steel Feet', '${totalSteelFeet.toStringAsFixed(0)} ft'],
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Commission Details',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (bores.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 12),
              child: pw.Text('No bores found for the selected criteria.'),
            )
          else
            fromStyledTextArray(
              headers: const [
                'Bore ID',
                'Date',
                'Bore Commission',
                'Pipe Commission',
                'Steel Commission',
                'Total Commission',
                'Balance',
              ],
              data: bores
                  .map(
                    (bore) => [
                      bore.boreNumber,
                      shortDate.format(bore.date),
                      '${bore.totalFeet.toStringAsFixed(0)} x ${bore.agentCommissionPerFeet.toStringAsFixed(0)} = ${_money(boreCommission(bore))}',
                      '${totalPipeLength(bore).toStringAsFixed(0)} x ${bore.agentCommissionPerPipeFoot.toStringAsFixed(0)} = ${_money(pipeCommission(bore))}',
                      bore.steelFeet > 0 ? '${bore.steelFeet.toStringAsFixed(0)} x ${bore.steelAgentCommission.toStringAsFixed(0)} = ${_money(steelCommission(bore))}' : 'N/A',
                      _money(totalCommission(bore)),
                      _money(boreBalance(bore)),
                    ],
                  )
                  .toList(),
              columnWidths: {
                0: const pw.FixedColumnWidth(38),
                1: const pw.FixedColumnWidth(50),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.0),
                6: const pw.FixedColumnWidth(62),
              },
            ),
          pw.SizedBox(height: 14),
          fromStyledTextArray(
            headers: const ['Summary', 'Amount (INR)'],
            data: [
              ['Total Balance', _money(displayBalance)],
              ['Total Commission', _money(displayCommission)],
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static Future<void> shareCustomerBill({
    required Bore bore,
    required String managerName,
  }) async {
    final doc = pw.Document();

    double paid = bore.payments.fold<double>(0, (sum, p) => sum + p.amount);
    double balance = bore.totalBill - paid;

    String rs(num v) => 'Rs ${_pdfMoney.format(v)}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'AQUA TRACK',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'BORE DRILLING MANAGEMENT',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.blue600, letterSpacing: 2),
                  ),
                ],
              ),
            ),
            pw.Divider(color: PdfColors.blue800, thickness: 1.5),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Bill No: ${bore.boreNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('Date: ${shortDate.format(bore.date)}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text('Manager: $managerName', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Agent Name: ${bore.agentName}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 12),
            pw.Header(text: 'Feet Entries', level: 0),
            fromStyledTextArray(
              headers: ['#', 'Length (ft)', 'Rate/ft', 'Amount'],
              data: bore.feetEntries.asMap().entries.map((e) => [
                '${e.key + 1}',
                e.value.length.toStringAsFixed(0),
                rs(e.value.pricePerFeet),
                rs(e.value.length * e.value.pricePerFeet),
              ]).toList(),
              columnWidths: {
                0: const pw.FixedColumnWidth(20),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
            ),
            pw.SizedBox(height: 8),
            if (bore.pipesUsed.isNotEmpty) ...[
              pw.Header(text: 'Pipe Entries', level: 0),
              fromStyledTextArray(
                headers: ['#', 'Size', 'Qty', 'Length (ft)', 'Price/ft', 'Amount'],
                data: bore.pipesUsed.asMap().entries.map((e) {
                  final qty = (e.value.length / 20).ceil();
                  return [
                    '${e.key + 1}',
                    '${e.value.size.toStringAsFixed(0)}"',
                    '$qty',
                    e.value.length.toStringAsFixed(0),
                    rs(e.value.pricePerPipeFoot),
                    rs(e.value.length * e.value.pricePerPipeFoot),
                  ];
                }).toList(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(18),
                  1: const pw.FixedColumnWidth(36),
                  2: const pw.FixedColumnWidth(30),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1),
                },
              ),
              pw.SizedBox(height: 8),
            ],
            if (bore.steelFeet > 0) ...[
              pw.Header(text: 'Steel', level: 0),
              fromStyledTextArray(
                headers: ['Feet', 'Price/ft', 'Amount', 'Welding Charge'],
                data: [
                  [
                    bore.steelFeet.toStringAsFixed(0),
                    rs(bore.steelPricePerFeet),
                    rs(bore.steelFeet * bore.steelPricePerFeet),
                    rs(bore.steelWeldingCharge),
                  ],
                ],
              ),
              pw.SizedBox(height: 8),
            ],
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Bill:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text(rs(bore.totalBill), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Paid:', style: const pw.TextStyle(fontSize: 11)),
                pw.Text(rs(paid), style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Balance:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.red700)),
                pw.Text(rs(balance), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.red700)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bill_${bore.boreNumber}.pdf');
    await file.writeAsBytes(await doc.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Bill - ${bore.boreNumber}');
  }
}
