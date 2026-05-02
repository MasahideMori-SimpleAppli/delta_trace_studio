import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/main.dart';
import 'package:flutter/material.dart';

Future<MergeQueryParams?> showMergeQueryParamsDialog(
  BuildContext context, {
  MergeQueryParams? initial,
}) {
  return showDialog<MergeQueryParams>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _MergeQueryParamsDialog(initial: initial),
  );
}

class _MergeQueryParamsDialog extends StatefulWidget {
  final MergeQueryParams? initial;
  const _MergeQueryParamsDialog({this.initial});

  @override
  State<_MergeQueryParamsDialog> createState() =>
      _MergeQueryParamsDialogState();
}

class _MergeQueryParamsDialogState extends State<_MergeQueryParamsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _outputCtrl = TextEditingController();
  final _dslTmpCtrl = TextEditingController();

  String? _base;
  List<String> _selectedSources = [];
  String? _relationKey;
  List<String> _selectedSourceKeys = [];
  String? _serialBase;
  String? _serialKey;
  String? _jsonError;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _base = init.base.isNotEmpty ? init.base : null;
      _selectedSources = List.from(init.source);
      _relationKey = init.relationKey.isNotEmpty ? init.relationKey : null;
      _selectedSourceKeys = List.from(init.sourceKeys);
      _outputCtrl.text = init.output;
      _dslTmpCtrl.text =
          const JsonEncoder.withIndent('  ').convert(init.dslTmp);
      _serialBase = init.serialBase;
      _serialKey = init.serialKey;
    } else {
      _dslTmpCtrl.text = '{}';
    }
  }

  @override
  void dispose() {
    _outputCtrl.dispose();
    _dslTmpCtrl.dispose();
    super.dispose();
  }

  // ---- helpers ----

  List<String> get _allCollections => localDB.raw.keys.toList();

  Set<String> _keysOf(String name) {
    if (!localDB.raw.containsKey(name)) return {};
    return localDB.collection(name).raw.expand((i) => i.keys).toSet();
  }

  Set<String> _keysOfSources() =>
      _selectedSources.expand((s) => _keysOf(s)).toSet();

  List<String> get _sourceCandidates =>
      _allCollections.where((c) => c != _base).toList();

  List<String> get _sourceKeysSorted =>
      (_keysOfSources().toList()..sort());

  List<String> get _serialKeyCandidates =>
      _serialBase != null ? (_keysOf(_serialBase!).toList()..sort()) : [];

  // ---- event handlers ----

  void _onBaseChanged(String? value) {
    setState(() {
      _base = value;
      _selectedSources.clear();
      _relationKey = null;
      _selectedSourceKeys.clear();
    });
  }

  void _onSourceToggled(String collection, bool selected) {
    setState(() {
      if (selected) {
        _selectedSources.add(collection);
      } else {
        _selectedSources.remove(collection);
      }
      final keys = _keysOfSources();
      if (!keys.contains(_relationKey)) _relationKey = null;
      _selectedSourceKeys.retainWhere(keys.contains);
    });
  }

  void _onSerialBaseChanged(String? value) {
    setState(() {
      _serialBase = value;
      _serialKey = null;
    });
  }

  Map<String, dynamic>? _parseJson(String src) {
    _jsonError = null;
    try {
      final decoded = jsonDecode(src);
      if (decoded is Map<String, dynamic>) return decoded;
      _jsonError = 'JSON must be an object {}';
    } catch (e) {
      _jsonError = e.toString();
    }
    return null;
  }

  void _submit() {
    setState(() => _jsonError = null);
    if (!_formKey.currentState!.validate()) return;
    final dslTmp = _parseJson(_dslTmpCtrl.text);
    if (dslTmp == null) {
      setState(() {});
      return;
    }
    Navigator.of(context).pop(
      MergeQueryParams(
        base: _base!,
        source: _selectedSources,
        relationKey: _relationKey ?? '',
        sourceKeys: _selectedSourceKeys,
        output: _outputCtrl.text.trim(),
        dslTmp: dslTmp,
        serialBase: _serialBase,
        serialKey: _serialKey,
      ),
    );
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = _base != null && _selectedSources.isNotEmpty;
    return AlertDialog(
      title: const Text('Merge Query Parameters'),
      content: SizedBox(
        width: 600,
        height: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section(theme, 'Base'),
                const SizedBox(height: 8),
                _baseDropdown(),
                const SizedBox(height: 20),
                _section(theme, 'Source collections'),
                _sourceCheckboxes(),
                const SizedBox(height: 20),
                _section(theme, 'Keys'),
                const SizedBox(height: 8),
                _labeledDropdown(
                  label: 'Relation key',
                  value: _sourceKeysSorted.contains(_relationKey)
                      ? _relationKey
                      : null,
                  candidates: _sourceKeysSorted,
                  emptyHint: 'Select source collections first',
                  onChanged: _selectedSources.isEmpty
                      ? null
                      : (v) => setState(() => _relationKey = v),
                ),
                const SizedBox(height: 16),
                _sourceKeysSection(theme),
                const SizedBox(height: 20),
                _section(theme, 'Output'),
                const SizedBox(height: 8),
                _outputField(),
                const SizedBox(height: 20),
                _section(theme, 'DSL tmp'),
                const SizedBox(height: 8),
                _dslField(),
                const SizedBox(height: 20),
                _section(theme, 'Serial (optional)'),
                const SizedBox(height: 8),
                _serialBaseDropdown(),
                if (_serialBase != null) ...[
                  const SizedBox(height: 12),
                  _labeledDropdown(
                    label: 'Serial key',
                    value: _serialKeyCandidates.contains(_serialKey)
                        ? _serialKey
                        : null,
                    candidates: _serialKeyCandidates,
                    emptyHint: 'No keys found',
                    onChanged: (v) => setState(() => _serialKey = v),
                    nullable: true,
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: canSubmit ? _submit : null,
          child: const Text('OK'),
        ),
      ],
    );
  }

  // ---- section widgets ----

  Widget _section(ThemeData theme, String label) {
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _baseDropdown() {
    return _labeledDropdown(
      label: 'Base collection',
      value: _base,
      candidates: _allCollections,
      emptyHint: 'No collections',
      onChanged: _onBaseChanged,
    );
  }

  Widget _sourceCheckboxes() {
    if (_base == null) {
      return _hint('Select base collection first.');
    }
    final candidates = _sourceCandidates;
    if (candidates.isEmpty) {
      return _hint('No other collections available.');
    }
    return Column(
      children: candidates.map((c) {
        return CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(c),
          value: _selectedSources.contains(c),
          onChanged: (v) => _onSourceToggled(c, v ?? false),
        );
      }).toList(),
    );
  }

  Widget _sourceKeysSection(ThemeData theme) {
    if (_selectedSources.isEmpty) {
      return _hint('Source keys: select source collections first.');
    }
    final candidates = _sourceKeysSorted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source keys',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        ...candidates.map(
          (k) => CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(k, style: const TextStyle(fontSize: 13)),
            value: _selectedSourceKeys.contains(k),
            onChanged: (v) => setState(() {
              if (v ?? false) {
                _selectedSourceKeys.add(k);
              } else {
                _selectedSourceKeys.remove(k);
              }
            }),
          ),
        ),
      ],
    );
  }

  Widget _serialBaseDropdown() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Serial base (optional)',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _serialBase,
          isExpanded: true,
          isDense: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('None', style: TextStyle(color: Colors.grey)),
            ),
            ..._allCollections.map(
              (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
            ),
          ],
          onChanged: _onSerialBaseChanged,
        ),
      ),
    );
  }

  Widget _outputField() {
    return TextFormField(
      controller: _outputCtrl,
      decoration: const InputDecoration(
        labelText: 'Output collection name',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _dslField() {
    return TextFormField(
      controller: _dslTmpCtrl,
      decoration: InputDecoration(
        labelText: 'DSL tmp (JSON)',
        border: const OutlineInputBorder(),
        isDense: true,
        errorText: _jsonError,
      ),
      minLines: 5,
      maxLines: 10,
      style: const TextStyle(fontFamily: 'Noto Sans Mono', fontSize: 13),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  // ---- shared ----

  Widget _labeledDropdown({
    required String label,
    required String? value,
    required List<String> candidates,
    required String emptyHint,
    required ValueChanged<String?>? onChanged,
    bool nullable = false,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(
            candidates.isEmpty ? emptyHint : 'Select',
            style: const TextStyle(color: Colors.grey),
          ),
          items: [
            if (nullable)
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('None', style: TextStyle(color: Colors.grey)),
              ),
            ...candidates.map(
              (k) => DropdownMenuItem<String?>(value: k, child: Text(k)),
            ),
          ],
          onChanged: candidates.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  Widget _hint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }
}
