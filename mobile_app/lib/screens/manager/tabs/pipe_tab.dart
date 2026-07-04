import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../localization/ext.dart';
import '../../../models/models.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';

class PipeTab extends StatelessWidget {
  const PipeTab({super.key, required this.managerId, required this.pipeStock, required this.onRefresh, required this.readOnly});

  final String managerId;
  final List<PipeStockItem> pipeStock;
  final Future<void> Function() onRefresh;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final sorted = [...pipeStock]..sort((a, b) => a.size.compareTo(b.size));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.t('Pipe in Vehicle'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _AddPipeForm(managerId: managerId, onRefresh: onRefresh, readOnly: readOnly),
        const SizedBox(height: 16),
        ...sorted.map((item) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: AppTheme.depthCard(borderRadius: 16, depth: 0.7),
                  child: ListTile(
                    title: Text('${item.size}"'),
                    subtitle: Text('Quantity: ${item.quantity}'),
                    trailing: !readOnly
                        ? PopupMenuButton<String>(
                            onSelected: (value) => _handleAction(context, value, item),
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'adjust', child: Text(context.t('Adjust'))),
                              PopupMenuItem(value: 'delete', child: Text(context.t('Delete'))),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
            )),
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(context.t('No pipes added yet.')),
          ),
      ],
    );
  }

  Future<void> _handleAction(BuildContext context, String action, PipeStockItem item) async {
    if (action == 'adjust') {
      await _showAdjustDialog(context, item);
    } else if (action == 'delete') {
      await _deleteStock(context, item);
    }
  }

  Future<void> _showAdjustDialog(BuildContext context, PipeStockItem item) async {
    final api = context.read<ApiService>();
    final controller = TextEditingController(text: item.quantity.toString());
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
                  Text(context.t('Adjust Quantity'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: context.t('New Quantity'),
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
                  const SizedBox(height: 20),
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
    );
    if (confirmed != true) return;

    final quantity = int.tryParse(controller.text.trim()) ?? item.quantity;
    await api.updatePipeStock(managerId: managerId, size: item.size, quantity: quantity);
    await onRefresh();
  }

  Future<void> _deleteStock(BuildContext context, PipeStockItem item) async {
    final api = context.read<ApiService>();
    await api.deletePipeStock(managerId: managerId, size: item.size);
    await onRefresh();
  }
}

class _AddPipeForm extends StatefulWidget {
  const _AddPipeForm({required this.managerId, required this.onRefresh, required this.readOnly});

  final String managerId;
  final Future<void> Function() onRefresh;
  final bool readOnly;

  @override
  State<_AddPipeForm> createState() => _AddPipeFormState();
}

class _AddPipeFormState extends State<_AddPipeForm> {
  late final TextEditingController _sizeController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _sizeController = TextEditingController();
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _quantityController.dispose();
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
            children: [
              TextField(
                controller: _sizeController,
                decoration: InputDecoration(
                  labelText: context.t('Pipe Size'),
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
              const SizedBox(height: 12),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: context.t('Quantity'),
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
              const SizedBox(height: 12),
              if (!widget.readOnly)
                ElevatedButton(
                  onPressed: () async {
                    final size = double.tryParse(_sizeController.text.trim()) ?? 0;
                    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
                    if (size <= 0 || quantity <= 0) return;
                    await api.addPipeStock(managerId: widget.managerId, size: size, quantity: quantity);
                    await widget.onRefresh();
                    _sizeController.clear();
                    _quantityController.clear();
                  },
                  child: Text(context.t('Add Pipe')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
