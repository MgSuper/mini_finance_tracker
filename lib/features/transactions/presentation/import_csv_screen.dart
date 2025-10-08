import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/transactions/data/csv_import.dart';
import 'package:mini_finan/features/transactions/import_controller.dart';

class ImportCsvScreen extends ConsumerStatefulWidget {
  const ImportCsvScreen({super.key});

  @override
  ConsumerState<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends ConsumerState<ImportCsvScreen> {
  ParsedCsv? parsed;
  Map<String, int> mapping = {
    'date': -1,
    'description': -1,
    'debit': -1,
    'credit': -1,
    'amount': -1,
    'currency': -1,
    'merchant': -1,
    'category': -1,
  };
  String currencyFallback = 'USD';

  Future<void> _pickCsv() async {
    final res = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (res == null || res.files.isEmpty) return;

    final file = res.files.single;
    String content;
    if (file.bytes != null) {
      content = String.fromCharCodes(file.bytes!);
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    } else {
      return;
    }

    final p = parseCsv(content);
    setState(() => parsed = p);

    // Auto-guess columns by common names
    final headers = p.headers.map((h) => h.toLowerCase()).toList();
    int idx(String name) => headers.indexWhere((h) => h.contains(name));
    mapping['date'] = idx('date');
    mapping['description'] = idx('desc');
    mapping['merchant'] = headers
        .indexWhere((h) => h.contains('merchant') || h.contains('payee'));
    mapping['amount'] =
        headers.indexWhere((h) => h == 'amount' || h.contains('amount'));
    mapping['debit'] = headers.indexWhere((h) => h.contains('debit'));
    mapping['credit'] = headers.indexWhere((h) => h.contains('credit'));
    mapping['currency'] =
        headers.indexWhere((h) => h.contains('currency') || h == 'cur');
    mapping['category'] = headers.indexWhere((h) => h.contains('category'));
  }

  Future<void> _import() async {
    final controller = ref.read(importControllerProvider.notifier);
    try {
      final count = await controller.commit(
        rows: parsed?.rows ?? const [],
        mapping: mapping,
        currencyFallback: currencyFallback,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Imported $count transactions')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Import failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importControllerProvider);
    final p = parsed;

    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            FilledButton.icon(
              onPressed: state.isLoading ? null : _pickCsv,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose CSV'),
            ),
            const SizedBox(height: 12),
            if (p == null) const Text('No file selected'),
            if (p != null) ...[
              Text(
                  'Detected ${p.rows.length} rows • ${p.headers.length} columns'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: currencyFallback,
                decoration:
                    const InputDecoration(labelText: 'Fallback currency'),
                items: const ['USD', 'EUR', 'VND', 'SGD', 'JPY']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => currencyFallback = v ?? 'USD'),
              ),
              const SizedBox(height: 12),
              const Text('Map columns:'),
              const SizedBox(height: 6),
              _MapRow(
                label: 'Date',
                headers: p.headers,
                value: mapping['date']!,
                onChanged: (i) => setState(() => mapping['date'] = i),
              ),
              _MapRow(
                label: 'Description',
                headers: p.headers,
                value: mapping['description']!,
                onChanged: (i) => setState(() => mapping['description'] = i),
              ),
              _MapRow(
                label: 'Merchant',
                headers: p.headers,
                value: mapping['merchant']!,
                onChanged: (i) => setState(() => mapping['merchant'] = i),
              ),
              _MapRow(
                label: 'Amount',
                headers: p.headers,
                value: mapping['amount']!,
                onChanged: (i) => setState(() => mapping['amount'] = i),
              ),
              _MapRow(
                label: 'Debit',
                headers: p.headers,
                value: mapping['debit']!,
                onChanged: (i) => setState(() => mapping['debit'] = i),
              ),
              _MapRow(
                label: 'Credit',
                headers: p.headers,
                value: mapping['credit']!,
                onChanged: (i) => setState(() => mapping['credit'] = i),
              ),
              _MapRow(
                label: 'Currency',
                headers: p.headers,
                value: mapping['currency']!,
                onChanged: (i) => setState(() => mapping['currency'] = i),
              ),
              _MapRow(
                label: 'Category',
                headers: p.headers,
                value: mapping['category']!,
                onChanged: (i) => setState(() => mapping['category'] = i),
              ),
              const SizedBox(height: 16),
              const Text('Preview (first 10 rows):'),
              const SizedBox(height: 8),
              _PreviewTable(rows: p.rows.take(10).toList()),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: state.isLoading ? null : _import,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(state.isLoading ? 'Importing…' : 'Import'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapRow extends StatelessWidget {
  const _MapRow({
    required this.label,
    required this.headers,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<String> headers;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: value >= 0 && value < headers.length ? value : null,
            isExpanded: true,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), isDense: true),
            items: [
              const DropdownMenuItem(value: -1, child: Text('— (none)')),
              for (int i = 0; i < headers.length; i++)
                DropdownMenuItem(value: i, child: Text('[$i] ${headers[i]}')),
            ],
            onChanged: (v) => onChanged(v ?? -1),
          ),
        ),
      ],
    );
  }
}

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.rows});
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(
        children: [
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: Theme.of(context).dividerColor))),
              alignment: Alignment.centerLeft,
              child: Text(r.join('  |  '),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}
