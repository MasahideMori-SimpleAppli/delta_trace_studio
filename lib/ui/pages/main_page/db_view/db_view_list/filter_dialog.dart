import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/filter_data.dart';
import 'package:flutter/material.dart';
import 'package:simple_locale/simple_locale.dart';

import 'package:simple_managers/simple_managers.dart';
import 'package:simple_widget_markup/simple_widget_markup.dart';

class FilterDialog extends StatefulWidget {
  final StateManager sm;

  const FilterDialog(this.sm, {super.key});

  @override
  State createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String? _getLayout(BuildContext context) {
    final String lang = LocaleManager.of(context)?.getLanguageCode() ?? "en";
    const String pageName = "main_page";
    const String windowClass = "any";
    const String fileName = "filter_dialog";
    final String path =
        "assets/layout/$lang/$pageName/$windowClass/$fileName.spwml";
    return SpWMLLayoutManager().getAssets(
      path,
      () {
        if (mounted) {
          setState(() {});
        }
      },
      (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("SpWMLLoadingError"),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  dynamic _getValue(String valueKey, String typeKey) {
    EnumValueType t = EnumValueType.values.byName(
      widget.sm.tsm.getSelection(typeKey)!,
    );
    String textV = widget.sm.tfm.getText(valueKey);
    switch (t) {
      case EnumValueType.auto_:
        throw ArgumentError();
      case EnumValueType.datetime_:
        return DateTime.parse(textV);
      case EnumValueType.int_:
        return int.parse(textV);
      case EnumValueType.floatStrict_:
      case EnumValueType.floatEpsilon12_:
        return double.parse(textV);
      case EnumValueType.boolean_:
        return bool.parse(textV);
      case EnumValueType.string_:
        return textV;
    }
  }

  QueryNode? _getNode(
    String switchKey,
    String targetKey,
    String nodeKey,
    String valueKey,
    String typeKey,
  ) {
    final bool switchValue = widget.sm.fm.getFlag(switchKey);
    if (switchValue) {
      EnumNodeType nType1 = EnumNodeType.values.byName(
        widget.sm.tsm.getSelection(nodeKey)!,
      );
      // 値を変換しつつ取得。
      String target = widget.sm.tfm.getText(targetKey);
      dynamic v = _getValue(valueKey, typeKey);
      switch (nType1) {
        case EnumNodeType.and_:
        case EnumNodeType.or_:
        case EnumNodeType.not_:
          throw ArgumentError();
        case EnumNodeType.equals_:
          return FieldEquals(target, v);
        case EnumNodeType.notEquals_:
          return FieldNotEquals(target, v);
        case EnumNodeType.greaterThan_:
          return FieldGreaterThan(target, v);
        case EnumNodeType.lessThan_:
          return FieldLessThan(target, v);
        case EnumNodeType.greaterThanOrEqual_:
          return FieldGreaterThanOrEqual(target, v);
        case EnumNodeType.lessThanOrEqual_:
          return FieldLessThanOrEqual(target, v);
        case EnumNodeType.regex_:
          return FieldMatchesRegex(target, v);
        case EnumNodeType.contains_:
          return FieldContains(target, v);
        case EnumNodeType.in_:
          return FieldIn(target, v);
        case EnumNodeType.notIn_:
          return FieldNotIn(target, v);
        case EnumNodeType.startsWith_:
          return FieldStartsWith(target, v);
        case EnumNodeType.endsWith_:
          return FieldEndsWith(target, v);
      }
    } else {
      return null;
    }
  }

  Widget _wrap(Widget w) {
    return AlertDialog(
      content: SizedBox(width: 720, height: 240, child: w),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            try {
              QueryNode? node1 = _getNode(
                "switch1",
                "key1",
                "comparisonMethod1",
                "value1",
                "type1",
              );
              QueryNode? node2 = _getNode(
                "switch2",
                "key2",
                "comparisonMethod2",
                "value2",
                "type2",
              );
              FilterData addData = FilterData(node1, node2);
              Navigator.pop(context, addData);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "TypeError: The input could not be converted to the specified type.",
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: Text('OK'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = _getLayout(context);
    if (layout == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      SpWMLBuilder b = SpWMLBuilder(layout, padding: EdgeInsets.zero);
      b.setStateManager(widget.sm);
      _initViewAndCallbacks(b);
      return _wrap(b.build(context));
    }
  }

  void _initViewAndCallbacks(SpWMLBuilder b) {
    // non use
  }
}
