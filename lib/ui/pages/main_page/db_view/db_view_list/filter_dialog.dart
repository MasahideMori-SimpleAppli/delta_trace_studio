import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/filter_data.dart';
import 'package:flutter/material.dart';

class FilterDialog extends StatefulWidget {
  final FilterFormState? initial;
  final List<String> availableKeys;
  const FilterDialog({super.key, this.initial, this.availableKeys = const []});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  bool _enabled1 = false;
  String _key1 = '';
  EnumNodeType _method1 = EnumNodeType.equals_;
  final _valCtrl1 = TextEditingController();
  EnumValueType _type1 = EnumValueType.int_;

  bool _enabled2 = false;
  String _key2 = '';
  EnumNodeType _method2 = EnumNodeType.equals_;
  final _valCtrl2 = TextEditingController();
  EnumValueType _type2 = EnumValueType.int_;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _enabled1 = init.enabled1;
      _key1 = init.key1;
      _method1 = init.method1;
      _valCtrl1.text = init.value1;
      _type1 = init.type1;
      _enabled2 = init.enabled2;
      _key2 = init.key2;
      _method2 = init.method2;
      _valCtrl2.text = init.value2;
      _type2 = init.type2;
    }
  }

  @override
  void dispose() {
    _valCtrl1.dispose();
    _valCtrl2.dispose();
    super.dispose();
  }

  static List<DropdownMenuItem<EnumNodeType>> _methodItems(
    AppLocalizations l10n,
  ) => [
    DropdownMenuItem(value: EnumNodeType.equals_, child: Text('=')),
    DropdownMenuItem(value: EnumNodeType.notEquals_, child: Text('≠')),
    DropdownMenuItem(value: EnumNodeType.greaterThan_, child: Text('>')),
    DropdownMenuItem(value: EnumNodeType.lessThan_, child: Text('<')),
    DropdownMenuItem(value: EnumNodeType.greaterThanOrEqual_, child: Text('>=')),
    DropdownMenuItem(value: EnumNodeType.lessThanOrEqual_, child: Text('<=')),
    DropdownMenuItem(value: EnumNodeType.regex_, child: Text(l10n.filterOpRegex)),
    DropdownMenuItem(value: EnumNodeType.contains_, child: Text(l10n.filterOpContains)),
    DropdownMenuItem(value: EnumNodeType.in_, child: Text(l10n.filterOpIn)),
    DropdownMenuItem(value: EnumNodeType.notIn_, child: Text(l10n.filterOpNotIn)),
    DropdownMenuItem(value: EnumNodeType.startsWith_, child: Text(l10n.filterOpStartsWith)),
    DropdownMenuItem(value: EnumNodeType.endsWith_, child: Text(l10n.filterOpEndsWith)),
  ];

  static List<DropdownMenuItem<EnumValueType>> _typeItems(
    AppLocalizations l10n,
  ) => [
    DropdownMenuItem(
      value: EnumValueType.datetime_,
      child: Text('Datetime'),
    ),
    DropdownMenuItem(value: EnumValueType.int_, child: Text('int')),
    DropdownMenuItem(
      value: EnumValueType.floatStrict_,
      child: Text('Float strict'),
    ),
    DropdownMenuItem(
      value: EnumValueType.floatEpsilon12_,
      child: Text('Float ε12'),
    ),
    DropdownMenuItem(value: EnumValueType.boolean_, child: Text('boolean')),
    DropdownMenuItem(value: EnumValueType.string_, child: Text('String')),
    DropdownMenuItem(
      value: EnumValueType.stringIgnoreCase_,
      child: Text('String (ignore case)'),
    ),
  ];

  dynamic _parseValue(String text, EnumValueType type) {
    switch (type) {
      case EnumValueType.auto_:
        throw ArgumentError();
      case EnumValueType.datetime_:
        return DateTime.parse(text);
      case EnumValueType.int_:
        return int.parse(text);
      case EnumValueType.floatStrict_:
      case EnumValueType.floatEpsilon12_:
        return double.parse(text);
      case EnumValueType.boolean_:
        return bool.parse(text);
      case EnumValueType.string_:
      case EnumValueType.stringIgnoreCase_:
        return text;
    }
  }

  QueryNode? _buildNode(
    bool enabled,
    String key,
    EnumNodeType method,
    String valueText,
    EnumValueType type,
  ) {
    if (!enabled) return null;
    final v = _parseValue(valueText, type);
    switch (method) {
      case EnumNodeType.and_:
      case EnumNodeType.or_:
      case EnumNodeType.not_:
        throw ArgumentError();
      case EnumNodeType.equals_:
        return FieldEquals(key, v, vType: type);
      case EnumNodeType.notEquals_:
        return FieldNotEquals(key, v, vType: type);
      case EnumNodeType.greaterThan_:
        return FieldGreaterThan(key, v, vType: type);
      case EnumNodeType.lessThan_:
        return FieldLessThan(key, v, vType: type);
      case EnumNodeType.greaterThanOrEqual_:
        return FieldGreaterThanOrEqual(key, v, vType: type);
      case EnumNodeType.lessThanOrEqual_:
        return FieldLessThanOrEqual(key, v, vType: type);
      case EnumNodeType.regex_:
        return FieldMatchesRegex(key, v);
      case EnumNodeType.contains_:
        return FieldContains(key, v);
      case EnumNodeType.in_:
        return FieldIn(key, v);
      case EnumNodeType.notIn_:
        return FieldNotIn(key, v);
      case EnumNodeType.startsWith_:
        return FieldStartsWith(key, v);
      case EnumNodeType.endsWith_:
        return FieldEndsWith(key, v);
    }
  }

  Widget _buildFilterRow({
    required String label,
    required bool enabled,
    required String keyValue,
    required EnumNodeType method,
    required TextEditingController valCtrl,
    required EnumValueType type,
    required AppLocalizations l10n,
    required ValueChanged<bool?> onEnabledChanged,
    required ValueChanged<String?> onKeyChanged,
    required ValueChanged<EnumNodeType?> onMethodChanged,
    required ValueChanged<EnumValueType?> onTypeChanged,
  }) {
    final keys = widget.availableKeys;
    final effectiveKeyValue = keys.contains(keyValue) ? keyValue : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(value: enabled, onChanged: onEnabledChanged),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.filterKeyLabel,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: effectiveKeyValue,
                hint: const Text('-'),
                isExpanded: true,
                isDense: true,
                items: keys
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: enabled ? onKeyChanged : null,
              ),
            ),
          ),
          DropdownButton<EnumNodeType>(
            value: method,
            isDense: true,
            items: _methodItems(l10n),
            onChanged: enabled ? onMethodChanged : null,
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: valCtrl,
              enabled: enabled,
              decoration: InputDecoration(
                labelText: l10n.filterValueLabel,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          DropdownButton<EnumValueType>(
            value: type,
            isDense: true,
            items: _typeItems(l10n),
            onChanged: enabled ? onTypeChanged : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.filterTitle),
      content: SizedBox(
        width: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filterDescription),
            const SizedBox(height: 8),
            _buildFilterRow(
              label: '1.',
              enabled: _enabled1,
              keyValue: _key1,
              method: _method1,
              valCtrl: _valCtrl1,
              type: _type1,
              l10n: l10n,
              onEnabledChanged: (v) => setState(() => _enabled1 = v ?? false),
              onKeyChanged: (v) {
                if (v != null) setState(() => _key1 = v);
              },
              onMethodChanged: (v) {
                if (v != null) setState(() => _method1 = v);
              },
              onTypeChanged: (v) {
                if (v != null) setState(() => _type1 = v);
              },
            ),
            _buildFilterRow(
              label: '2.',
              enabled: _enabled2,
              keyValue: _key2,
              method: _method2,
              valCtrl: _valCtrl2,
              type: _type2,
              l10n: l10n,
              onEnabledChanged: (v) => setState(() => _enabled2 = v ?? false),
              onKeyChanged: (v) {
                if (v != null) setState(() => _key2 = v);
              },
              onMethodChanged: (v) {
                if (v != null) setState(() => _method2 = v);
              },
              onTypeChanged: (v) {
                if (v != null) setState(() => _type2 = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_enabled1 && _key1.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.filterKeyRequired),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
            if (_enabled2 && _key2.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.filterKeyRequired),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
            try {
              final node1 = _buildNode(
                _enabled1,
                _key1,
                _method1,
                _valCtrl1.text,
                _type1,
              );
              final node2 = _buildNode(
                _enabled2,
                _key2,
                _method2,
                _valCtrl2.text,
                _type2,
              );
              Navigator.pop(context, (
                filterData: FilterData(node1, node2),
                formState: FilterFormState(
                  enabled1: _enabled1,
                  key1: _key1,
                  method1: _method1,
                  value1: _valCtrl1.text,
                  type1: _type1,
                  enabled2: _enabled2,
                  key2: _key2,
                  method2: _method2,
                  value2: _valCtrl2.text,
                  type2: _type2,
                ),
              ));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.filterTypeError),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
