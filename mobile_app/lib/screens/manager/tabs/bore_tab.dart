import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../localization/ext.dart';
import '../../../models/models.dart';
import '../../../services/api_service.dart';
import '../../../services/bore_bill_ocr.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/bore_details_dialog.dart';
import '../../../theme/app_theme.dart';

class BoreTab extends StatelessWidget {
  const BoreTab({
    super.key,
    required this.managerId,
    required this.managerName,
    required this.selectedMonth,
    required this.selectedYear,
    required this.bores,
    required this.pipeStock,
    required this.agents,
    required this.onRefresh,
    required this.readOnly,
  });

  final String managerId;
  final String managerName;
  final int selectedMonth;
  final int selectedYear;
  final List<Bore> bores;
  final List<PipeStockItem> pipeStock;
  final List<Agent> agents;
  final Future<void> Function() onRefresh;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final filteredBores = bores.where((bore) {
      return bore.date.month == selectedMonth && bore.date.year == selectedYear;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.t('Bores'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Wrap(
              spacing: 8,
              children: [
                if (!readOnly)
                  TextButton.icon(
                    onPressed: () => _scanBillAndAddBore(context),
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(context.t('Scan Bill')),
                  ),
                if (!readOnly)
                  TextButton.icon(
                    onPressed: () => _showBoreDialog(context),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(context.t('Add Bore')),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...filteredBores.map(
          (bore) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.7),
                child: ListTile(
                  title: Text(
                    '${bore.boreNumber} \u2022 ${shortDate.format(bore.date)}',
                  ),
                  subtitle: Text(
                    'Total Bill: ${currencyInr.format(bore.totalBill)} | Balance: ${currencyInr.format(_balance(bore))}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!readOnly)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showBoreDialog(context, bore: bore),
                        ),
                      if (!readOnly)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, bore),
                        ),
                    ],
                  ),
                  onTap: () => showBoreDetailsDialog(context, bore, managerName: managerName),
                ),
              ),
            ),
          ),
        ),
        if (filteredBores.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(context.t('No bores added yet.')),
          ),
      ],
    );
  }

  double _paid(Bore bore) =>
      bore.payments.fold<double>(0, (sum, payment) => sum + payment.amount);
  double _balance(Bore bore) => bore.totalBill - _paid(bore);

  // ---------------------------------------------------------------------
  // Scan Bill flow
  // ---------------------------------------------------------------------

  Future<void> _scanBillAndAddBore(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.t('Take Photo')),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.t('Choose from Gallery')),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (!context.mounted) return;

    // Show a dismissible loading dialog while the bill is read.
    bool dialogShowing = true;
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          dialogShowing = false;
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: AppTheme.glassDecoration(borderRadius: 24, opacity: 0.85),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      context.t('Reading bill…'),
                      style: TextStyle(color: AppTheme.foreground),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ));

    BoreScanResult? result;
    String? scanError;
    try {
      final ocr = BoreBillOcr();
      result = await ocr.extract(picked);
      await ocr.dispose();
    } catch (e) {
      scanError = e.toString();
    }

    if (dialogShowing && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (!context.mounted) return;

    if (scanError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: $scanError'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }

    // Open the bore dialog — with parsed data if OCR succeeded, otherwise
    // as a blank manual-entry form.
    final hasData = result != null &&
        (result.feetEntries.isNotEmpty ||
            result.pipesUsed.isNotEmpty ||
            result.totalBill > 0);
    await _showBoreDialog(context, prefill: hasData ? result : null);
  }

  Future<void> _confirmDelete(BuildContext context, Bore bore) async {
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
                  Text(context.t('Delete Bore'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                  const SizedBox(height: 8),
                  Text(context.t('This will remove the bore and related payments.'), style: TextStyle(color: AppTheme.mutedForeground)),
                  const SizedBox(height: 24),
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
                        child: Text(context.t('Delete')),
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

    await api.deleteBore(managerId: managerId, boreId: bore.id);
    await onRefresh();
  }

  Future<void> _showBoreDialog(
    BuildContext context, {
    Bore? bore,
    BoreScanResult? prefill,
  }) async {
    final api = context.read<ApiService>();
    final boreNumberController = TextEditingController(
      text: bore?.boreNumber ?? _nextBoreNumber(),
    );
    final agentCommissionController = TextEditingController(
      text: bore != null ? bore.agentCommissionPerFeet.toStringAsFixed(0) : '',
    );
    final agentPipeCommissionController = TextEditingController(
      text: bore != null ? bore.agentCommissionPerPipeFoot.toStringAsFixed(0) : '',
    );
    final agentController = TextEditingController(
      text: bore?.agentName ?? prefill?.agentName ?? '',
    );
    final initialPaymentController = TextEditingController(
      text: bore?.payments.isNotEmpty == true
          ? bore!.payments.first.amount.toStringAsFixed(0)
          : ((prefill?.initialPayment ?? 0) > 0
              ? prefill!.initialPayment.toStringAsFixed(0)
              : ''),
    );
    String initialPaymentMethod = bore?.payments.isNotEmpty == true
        ? bore!.payments.first.method
        : 'cash';
    final agentNameToMatch = bore?.agentName ?? prefill?.agentName;
    final agentNameLower = agentNameToMatch?.toLowerCase().trim();
    Agent? selectedAgent = agentNameLower != null && agentNameLower.isNotEmpty
        ? agents.where((a) => a.name.toLowerCase().trim() == agentNameLower).firstOrNull
        : null;
    final agentWarning = prefill?.agentName != null && selectedAgent == null;
    bool feetCommError = false;
    bool pipeCommError = false;
    bool steelCommError = false;
    DateTime selectedDate = bore?.date ?? prefill?.date ?? DateTime.now();

    final feetLengthCtrl = <TextEditingController>[];
    final feetRateCtrl = <TextEditingController>[];
    final feetFocusNodes = <FocusNode>[];

    void initFeet(double length, double rate) {
      feetLengthCtrl.add(TextEditingController(text: length > 0 ? length.toStringAsFixed(0) : ''));
      feetRateCtrl.add(TextEditingController(text: rate > 0 ? rate.toStringAsFixed(0) : ''));
      feetFocusNodes.add(FocusNode());
    }

    if (bore != null) {
      for (final e in bore.feetEntries) {
        initFeet(e.length, e.pricePerFeet);
      }
    } else if (prefill != null && prefill.feetEntries.isNotEmpty) {
      for (final e in prefill.feetEntries) {
        initFeet(e.length, e.pricePerFeet);
      }
    } else {
      initFeet(0, 0);
    }

    final pipeSizeValues = <double>[];
    final pipeLengthCtrl = <TextEditingController>[];
    final pipePriceCtrl = <TextEditingController>[];
    final pipeFocusNodes = <FocusNode>[];
    final pipeStockWarning = <bool>[];

    void initPipe(double size, double length, double price) {
      pipeSizeValues.add(size);
      pipeStockWarning.add(size > 0 && !pipeStock.any((s) => s.size == size));
      pipeLengthCtrl.add(TextEditingController(text: length > 0 ? length.toStringAsFixed(0) : ''));
      pipePriceCtrl.add(TextEditingController(text: price > 0 ? price.toStringAsFixed(0) : ''));
      pipeFocusNodes.add(FocusNode());
    }

    if (bore != null) {
      for (final e in bore.pipesUsed) {
        initPipe(e.size, e.length, e.pricePerPipeFoot);
      }
    } else if (prefill != null && prefill.pipesUsed.isNotEmpty) {
      for (final e in prefill.pipesUsed) {
        initPipe(e.size, e.length, e.pricePerPipeFoot);
      }
    } else {
      initPipe(0, 0, 0);
    }

    double steelFeet = bore?.steelFeet ?? prefill?.steelFeet ?? 0;
    double steelPricePerFeet = bore?.steelPricePerFeet ?? prefill?.steelPricePerFeet ?? 0;
    // Steel agent commission isn't printed on the bill, so it's never
    // pre-filled from a scan — only carried over when editing an existing bore.
    double steelAgentCommission = bore?.steelAgentCommission ?? 0;
    double steelWeldingCharge = bore?.steelWeldingCharge ?? prefill?.steelWeldingCharge ?? 0;

    double computeTotal() {
      double boreCost = 0;
      for (var i = 0; i < feetLengthCtrl.length; i++) {
        final l = double.tryParse(feetLengthCtrl[i].text) ?? 0;
        final r = double.tryParse(feetRateCtrl[i].text) ?? 0;
        boreCost += l * r;
      }
      double pipeCost = 0;
      for (var i = 0; i < pipeLengthCtrl.length; i++) {
        final l = double.tryParse(pipeLengthCtrl[i].text) ?? 0;
        final p = double.tryParse(pipePriceCtrl[i].text) ?? 0;
        pipeCost += l * p;
      }
      double steelCost = steelFeet * steelPricePerFeet;
      return boreCost + pipeCost + steelCost + steelWeldingCharge;
    }

    Future<void> addFeetEntry(StateSetter setState) async {
      final node = FocusNode();
      setState(() {
        initFeet(0, 0);
        feetFocusNodes.add(node);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => node.requestFocus());
    }

    Future<void> addPipeEntry(StateSetter setState) async {
      final node = FocusNode();
      setState(() {
        initPipe(0, 0, 0);
        pipeFocusNodes.add(node);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => node.requestFocus());
    }

    Future<void> showSteelDialog(BuildContext context, StateSetter setState) async {
      final feetCtrl = TextEditingController(text: steelFeet > 0 ? steelFeet.toStringAsFixed(0) : '');
      final priceCtrl = TextEditingController(text: steelPricePerFeet > 0 ? steelPricePerFeet.toStringAsFixed(0) : '');
      final agentCommCtrl = TextEditingController(text: steelAgentCommission > 0 ? steelAgentCommission.toStringAsFixed(0) : '');
      final weldingCtrl = TextEditingController(text: steelWeldingCharge > 0 ? steelWeldingCharge.toStringAsFixed(0) : '');

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
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
                    Text(context.t('Steel Entry'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: feetCtrl,
                      decoration: InputDecoration(
                        labelText: context.t('Feet'),
                        
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      decoration: InputDecoration(
                        labelText: context.t('Price / ft'),
                        
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: agentCommCtrl,
                      decoration: InputDecoration(
                        labelText: context.t('Agent Commission / ft'),
                        
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: weldingCtrl,
                      decoration: InputDecoration(
                        labelText: context.t('Welding Charge'),
                        
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(context.t('Cancel')),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
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

      if (confirmed == true) {
        setState(() {
          steelFeet = double.tryParse(feetCtrl.text) ?? 0;
          steelPricePerFeet = double.tryParse(priceCtrl.text) ?? 0;
          steelAgentCommission = double.tryParse(agentCommCtrl.text) ?? 0;
          steelWeldingCharge = double.tryParse(weldingCtrl.text) ?? 0;
        });
      }
    }

    bool hasEnoughStock(List<({double size, double length, double price})> pipeData) {
      final stock = <double, int>{};
      for (final item in pipeStock) {
        stock[item.size] = item.quantity;
      }

      final needed = <double, int>{};
      for (final entry in pipeData) {
        if (entry.size <= 0 || entry.length <= 0) continue;
        final pipesNeeded = (entry.length / 20).ceil();
        needed[entry.size] = (needed[entry.size] ?? 0) + pipesNeeded;
      }

      for (final size in needed.keys) {
        final available = stock[size] ?? 0;
        if (needed[size]! > available) {
          return false;
        }
      }
      return true;
    }

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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        bore != null
                            ? context.t('Edit Bore')
                            : (prefill != null
                                ? context.t('Review Scanned Bore')
                                : context.t('Add Bore')),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.foreground),
                      ),
                      if (prefill != null &&
                          (prefill.confidence == 'low' || prefill.unclearFields.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    prefill.unclearFields.isNotEmpty
                                        ? '${context.t("Please double-check")}: ${prefill.unclearFields.join(", ")}'
                                        : context.t('Some fields may not be accurate — please double-check before saving.'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: boreNumberController,
                        decoration: InputDecoration(
                          labelText: context.t('Bore Number'),
                          
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
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: agentCommissionController,
                        decoration: InputDecoration(
                          labelText: context.t('Agent Commission Per Feet'),
                          errorText: feetCommError ? context.t('Value required') : null,
                          
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Agent>(
                        initialValue: selectedAgent,
                        items: agents
                            .map(
                              (agent) => DropdownMenuItem(
                                value: agent,
                                child: Text(agent.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => selectedAgent = value),
                        decoration: InputDecoration(
                          labelText: context.t('Agent'),
                          
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
                      if (agentWarning)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  context.t('Scanned agent not in list — type name below'),
                                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: agentController,
                        decoration: InputDecoration(
                          labelText: context.t('Agent Name (optional)'),
                          
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.t('Feet Entries'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(feetLengthCtrl.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: feetLengthCtrl[index],
                                  focusNode: feetFocusNodes[index],
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: context.t('Feet (Length)'),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    
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
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: feetRateCtrl[index],
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: context.t('Rate/ft'),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    
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
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              if (!readOnly)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => setState(() {
                                    feetLengthCtrl[index].dispose();
                                    feetRateCtrl[index].dispose();
                                    feetFocusNodes[index].dispose();
                                    feetLengthCtrl.removeAt(index);
                                    feetRateCtrl.removeAt(index);
                                    feetFocusNodes.removeAt(index);
                                  }),
                                ),
                            ],
                          ),
                        );
                      }),
                      if (!readOnly)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => addFeetEntry(setState),
                            icon: const Icon(Icons.add),
                            label: Text(context.t('Add Feet Entry')),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.t('PVC Entries'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(pipeSizeValues.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                  child: DropdownButtonFormField<double>(
                                    value: pipeSizeValues[index] > 0 && !pipeStockWarning[index] ? pipeSizeValues[index] : null,
                                  focusNode: pipeFocusNodes[index],
                                  style: TextStyle(fontSize: 13, color: AppTheme.foreground),
                                  decoration: InputDecoration(
                                    labelText: context.t('Size (Qty)'),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    
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
                                  isExpanded: true,
                                  items: pipeStock
                                      .map((stock) => DropdownMenuItem(
                                            value: stock.size,
                                            child: Text('${stock.size.toStringAsFixed(0)}" (${stock.quantity})', style: TextStyle(fontSize: 13, color: AppTheme.foreground)),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        pipeSizeValues[index] = val;
                                        pipeStockWarning[index] = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                              if (pipeStockWarning[index])
                                Tooltip(
                                  message: context.t('Pipe size not in stock'),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: pipeLengthCtrl[index],
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: context.t('Length (ft)'),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    
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
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: pipePriceCtrl[index],
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: context.t('Price/ft'),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    
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
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              if (!readOnly)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => setState(() {
                                      pipeLengthCtrl[index].dispose();
                                      pipePriceCtrl[index].dispose();
                                      pipeFocusNodes[index].dispose();
                                      pipeSizeValues.removeAt(index);
                                      pipeStockWarning.removeAt(index);
                                      pipeLengthCtrl.removeAt(index);
                                      pipePriceCtrl.removeAt(index);
                                      pipeFocusNodes.removeAt(index);
                                    }),
                                ),
                            ],
                          ),
                        );
                      }),
                      if (!readOnly)
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => addPipeEntry(setState),
                              icon: const Icon(Icons.add),
                              label: Text(context.t('PVC Entry')),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => showSteelDialog(context, setState),
                              icon: const Icon(Icons.add),
                              label: Text(context.t('Steel')),
                            ),
                          ],
                        ),
                      if (steelFeet > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.miscellaneous_services, size: 16, color: AppTheme.success),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Steel: ${steelFeet.toStringAsFixed(0)} ft x ${currencyInr.format(steelPricePerFeet)}/ft + Welding ${currencyInr.format(steelWeldingCharge)}',
                                    style: TextStyle(fontSize: 12, color: AppTheme.foreground),
                                  ),
                                ),
                                if (!readOnly)
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    onPressed: () => showSteelDialog(context, setState),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (steelCommError)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            context.t('Steel Agent Commission required'),
                            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: agentPipeCommissionController,
                        decoration: InputDecoration(
                          labelText: context.t('Agent Commission Per Pipe Foot'),
                          errorText: pipeCommError ? context.t('Value required') : null,
                          
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total Bill: ${currencyInr.format(computeTotal())}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: initialPaymentController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: context.t('Initial Payment'),
                          
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
                        child: (double.tryParse(initialPaymentController.text) ?? 0) > 0
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
                                    Text(
                                      context.t('Select Paid Method'),
                                      style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Radio<String>(
                                                value: 'cash',
                                                groupValue: initialPaymentMethod,
                                                onChanged: (v) => setState(() => initialPaymentMethod = v!),
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
                                                groupValue: initialPaymentMethod,
                                                onChanged: (v) => setState(() => initialPaymentMethod = v!),
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(context.t('Cancel')),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                final hasFeet = feetLengthCtrl.any((c) => (double.tryParse(c.text) ?? 0) > 0);
                                final hasPipe = pipeLengthCtrl.any((c) => (double.tryParse(c.text) ?? 0) > 0);
                                final hasSteel = steelFeet > 0;
                                final fErr = hasFeet && (double.tryParse(agentCommissionController.text) ?? 0) <= 0;
                                final pErr = hasPipe && (double.tryParse(agentPipeCommissionController.text) ?? 0) <= 0;
                                final sErr = hasSteel && steelAgentCommission <= 0;
                                if (fErr || pErr || sErr) {
                                  setState(() {
                                    feetCommError = fErr;
                                    pipeCommError = pErr;
                                    steelCommError = sErr;
                                  });
                                  return;
                                }
                                Navigator.of(context).pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              child: Text(bore == null ? context.t('Save') : context.t('Update')),
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
      ),
    );

    if (confirmed != true) {
      for (final c in feetLengthCtrl) { c.dispose(); }
      for (final c in feetRateCtrl) { c.dispose(); }
      for (final c in pipeLengthCtrl) { c.dispose(); }
      for (final c in pipePriceCtrl) { c.dispose(); }
      for (final node in feetFocusNodes) { node.dispose(); }
      for (final node in pipeFocusNodes) { node.dispose(); }
      return;
    }

    final pipeData = <({double size, double length, double price})>[];
    for (var i = 0; i < pipeSizeValues.length; i++) {
      final size = pipeSizeValues[i];
      final length = double.tryParse(pipeLengthCtrl[i].text) ?? 0;
      final price = double.tryParse(pipePriceCtrl[i].text) ?? 0;
      if (size > 0 && length > 0) {
        pipeData.add((size: size, length: length, price: price));
      }
    }

    if (!hasEnoughStock(pipeData)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('Insufficient pipe stock for this bore.'))),
      );
      for (final c in feetLengthCtrl) { c.dispose(); }
      for (final c in feetRateCtrl) { c.dispose(); }
      for (final c in pipeLengthCtrl) { c.dispose(); }
      for (final c in pipePriceCtrl) { c.dispose(); }
      for (final node in feetFocusNodes) { node.dispose(); }
      for (final node in pipeFocusNodes) { node.dispose(); }
      return;
    }

    final pipesUsed = pipeData
        .map((e) => PipeEntry(size: e.size, length: e.length, pricePerPipeFoot: e.price))
        .toList();

    final pipeLogsPayload = pipeData
        .map((e) => PipeLog(
          id: '',
          date: selectedDate,
          type: 'Usage',
          quantity: (e.length / 20).ceil(),
          diameter: e.size,
        ))
        .toList();

    final totalBill = computeTotal();

    final validFeetEntries = <FeetEntry>[];
    for (var i = 0; i < feetLengthCtrl.length; i++) {
      final length = double.tryParse(feetLengthCtrl[i].text) ?? 0;
      final rate = double.tryParse(feetRateCtrl[i].text) ?? 0;
      if (length > 0) {
        validFeetEntries.add(FeetEntry(length: length, pricePerFeet: rate));
      }
    }

    final computedTotalFeet = validFeetEntries.fold<double>(
      0,
      (sum, e) => sum + e.length,
    );
    final computedBoreCost = validFeetEntries.fold<double>(
      0,
      (sum, e) => sum + (e.length * e.pricePerFeet),
    );
    final computedPricePerFeet = computedTotalFeet > 0
        ? computedBoreCost / computedTotalFeet
        : 0.0;

    if (bore == null) {
      await api.addBore(
        managerId: managerId,
        date: selectedDate,
        boreNumber: boreNumberController.text.trim(),
        totalFeet: computedTotalFeet,
        pricePerFeet: computedPricePerFeet,
        agentCommissionPerFeet:
            double.tryParse(agentCommissionController.text) ?? 0,
        agentCommissionPerPipeFoot:
            double.tryParse(agentPipeCommissionController.text) ?? 0,
        pipesUsed: pipesUsed,
        feetEntries: validFeetEntries,
        agentName: (selectedAgent?.name ?? agentController.text.trim()),
        totalBill: totalBill,
        initialPayment: double.tryParse(initialPaymentController.text) ?? 0,
        initialPaymentMethod: initialPaymentMethod,
        pipeLogs: pipeLogsPayload,
        steelFeet: steelFeet,
        steelPricePerFeet: steelPricePerFeet,
        steelAgentCommission: steelAgentCommission,
        steelWeldingCharge: steelWeldingCharge,
      );
    } else {
      await api.updateBore(
        managerId: managerId,
        boreId: bore.id,
        date: selectedDate,
        boreNumber: boreNumberController.text.trim(),
        totalFeet: computedTotalFeet,
        pricePerFeet: computedPricePerFeet,
        agentCommissionPerFeet:
            double.tryParse(agentCommissionController.text) ?? 0,
        agentCommissionPerPipeFoot:
            double.tryParse(agentPipeCommissionController.text) ?? 0,
        pipesUsed: pipesUsed,
        feetEntries: validFeetEntries,
        agentName: (selectedAgent?.name ?? agentController.text.trim()),
        totalBill: totalBill,
        initialPayment: double.tryParse(initialPaymentController.text) ?? 0,
        initialPaymentMethod: initialPaymentMethod,
        pipeLogs: pipeLogsPayload,
        steelFeet: steelFeet,
        steelPricePerFeet: steelPricePerFeet,
        steelAgentCommission: steelAgentCommission,
        steelWeldingCharge: steelWeldingCharge,
      );
    }

    for (final c in feetLengthCtrl) { c.dispose(); }
    for (final c in feetRateCtrl) { c.dispose(); }
    for (final c in pipeLengthCtrl) { c.dispose(); }
    for (final c in pipePriceCtrl) { c.dispose(); }
    for (final node in feetFocusNodes) { node.dispose(); }
    for (final node in pipeFocusNodes) { node.dispose(); }

    await onRefresh();
  }

  String _nextBoreNumber() {
    if (bores.isEmpty) return 'B001';
    final maxNum = bores
        .map((bore) => int.tryParse(bore.boreNumber.replaceAll('B', '')) ?? 0)
        .reduce((value, element) => value > element ? value : element);
    final next = maxNum + 1;
    return 'B${next.toString().padLeft(3, '0')}';
  }
}