import 'dart:convert';
import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:flutter/material.dart';

Future<MergeQueryParams?> showMergeQueryParamsDialog(
    BuildContext context, {
      MergeQueryParams? initial,
    }) {
  return showDialog<MergeQueryParams>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _MergeQueryParamsDialog(initial: initial);
    },
  );
}

class _MergeQueryParamsDialog extends StatefulWidget {
  final MergeQueryParams? initial;

  const _MergeQueryParamsDialog({this.initial});

  @override
  State<_MergeQueryParamsDialog> createState() =>
      _MergeQueryParamsDialogState();
}

class _MergeQueryParamsDialogState
    extends State<_MergeQueryParamsDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _baseCtrl;
  late final TextEditingController _sourceCtrl;
  late final TextEditingController _relationKeyCtrl;
  late final TextEditingController _sourceKeysCtrl;
  late final TextEditingController _outputCtrl;
  late final TextEditingController _dslTmpCtrl;
  late final TextEditingController _serialBaseCtrl;
  late final TextEditingController _serialKeyCtrl;

  String? _jsonError;

  @override
  void initState() {
    super.initState();

    final init = widget.initial;

    _baseCtrl = TextEditingController(text: init?.base ?? '');
    _sourceCtrl = TextEditingController(
        text: init?.source.join(', ') ?? '');
    _relationKeyCtrl =
        TextEditingController(text: init?.relationKey ?? '');
    _sourceKeysCtrl = TextEditingController(
        text: init?.sourceKeys.join(', ') ?? '');
    _outputCtrl = TextEditingController(text: init?.output ?? '');
    _dslTmpCtrl = TextEditingController(
        text: init != null
            ? const JsonEncoder.withIndent('  ')
            .convert(init.dslTmp)
            : '{}');
    _serialBaseCtrl =
        TextEditingController(text: init?.serialBase ?? '');
    _serialKeyCtrl =
        TextEditingController(text: init?.serialKey ?? '');
  }

  @override
  void dispose() {
    _baseCtrl.dispose();
    _sourceCtrl.dispose();
    _relationKeyCtrl.dispose();
    _sourceKeysCtrl.dispose();
    _outputCtrl.dispose();
    _dslTmpCtrl.dispose();
    _serialBaseCtrl.dispose();
    _serialKeyCtrl.dispose();
    super.dispose();
  }

  List<String> _splitList(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _parseJson(String src) {
    try {
      final decoded = jsonDecode(src);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      _jsonError = 'JSON must be an object';
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
        base: _baseCtrl.text.trim(),
        source: _splitList(_sourceCtrl.text),
        relationKey: _relationKeyCtrl.text.trim(),
        sourceKeys: _splitList(_sourceKeysCtrl.text),
        output: _outputCtrl.text.trim(),
        dslTmp: dslTmp,
        serialBase:
        _serialBaseCtrl.text.trim().isEmpty
            ? null
            : _serialBaseCtrl.text.trim(),
        serialKey:
        _serialKeyCtrl.text.trim().isEmpty
            ? null
            : _serialKeyCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Merge Query Parameters'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _field(_baseCtrl, 'Base collection'),
                _field(_sourceCtrl, 'Source collections (comma separated)'),
                _field(_relationKeyCtrl, 'Relation key'),
                _field(_sourceKeysCtrl, 'Source keys (comma separated)'),
                _field(_outputCtrl, 'Output collection name'),
                _jsonField(),
                _field(_serialBaseCtrl, 'Serial base (optional)'),
                _field(_serialKeyCtrl, 'Serial key (optional)'),
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
          onPressed: _submit,
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        validator: (v) =>
        (v == null || v.trim().isEmpty) &&
            !label.contains('optional')
            ? 'Required'
            : null,
      ),
    );
  }

  Widget _jsonField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _dslTmpCtrl,
        decoration: InputDecoration(
          labelText: 'DSL tmp (JSON)',
          errorText: _jsonError,
        ),
        minLines: 6,
        maxLines: 12,
        style: const TextStyle(fontFamily: 'monospace'),
        validator: (v) =>
        (v == null || v.trim().isEmpty)
            ? 'Required'
            : null,
      ),
    );
  }
}
