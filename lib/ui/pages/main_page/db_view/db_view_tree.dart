import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/main.dart';
import 'package:flutter/material.dart';
import 'package:simple_locale/simple_locale.dart';

import 'package:simple_managers/simple_managers.dart';
import 'package:simple_widget_markup/simple_widget_markup.dart';

class DbViewTree extends StatefulWidget {
  const DbViewTree({super.key});

  @override
  State createState() => _DbViewTreeState();
}

class _DbViewTreeState extends State<DbViewTree> {
  // The manager class for SpWML.
  final StateManager _sm = StateManager();

  @override
  void initState() {
    super.initState();
    // initialize dropdown button value.
    _sm.tsm.setSelection("samplingNum", "3");
    _sm.tsm.setSelection("textLength", "50");
  }

  @override
  void dispose() {
    _sm.dispose();
    super.dispose();
  }

  /// レイアウトを取得します。
  String? _getLayout(BuildContext context) {
    final String lang = LocaleManager.of(context)?.getLanguageCode() ?? "en";
    // page name
    const String pageName = "main_page";
    const String windowClass = "any";
    // loading SpWML file name
    const String fileName = "db_view_tree";
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

  Widget _wrap(Widget w) {
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final layout = _getLayout(context);
    if (layout == null) {
      return _wrap(const Center(child: CircularProgressIndicator()));
    } else {
      SpWMLBuilder b = SpWMLBuilder(layout, padding: EdgeInsets.zero);
      // Various manager classes are automatically configured using the SID set in SpWML.
      b.setStateManager(_sm);
      _initViewAndCallbacks(b);
      return _wrap(b.build(context));
    }
  }

  void _initViewAndCallbacks(SpWMLBuilder b) {
    DropdownBtn2Element dropDownBtn2Elm1 =
        b.getElement("samplingNum") as DropdownBtn2Element;
    dropDownBtn2Elm1.setCallback((String? tag) {
      if (tag != null) {
        // update UI
        setState(() {});
      }
    });
    DropdownBtn2Element dropDownBtn2Elm2 =
        b.getElement("textLength") as DropdownBtn2Element;
    dropDownBtn2Elm2.setCallback((String? tag) {
      if (tag != null) {
        // update UI
        setState(() {});
      }
    });
    TextElement text = b.getElement("treeView") as TextElement;
    text.setContentText(
      _mapToTextTree(
        localDB.raw,
        maxFieldLength: int.tryParse(dropDownBtn2Elm2.getValue() ?? "50") ?? 50,
        maxSamplesPerDb: int.tryParse(dropDownBtn2Elm1.getValue() ?? "3") ?? 3,
      ).join("\n"),
    );
  }

  /// Function to convert to a text-type hierarchical list
  ///
  /// * [dbData] : DB content。
  /// * [maxFieldLength] : The maximum number of characters to display in the field.
  /// * [maxSamplesPerDb] : The maximum number of records to display from each database (if less than 0, all records will be displayed).
  List<String> _mapToTextTree(
    Map<String, Collection> dbData, {
    int maxFieldLength = 50,
    int maxSamplesPerDb = 1,
  }) {
    if(dbData.isEmpty){
      return ["No data."];
    }
    final List<String> r = [];
    dbData.forEach((String collectionName, Collection collection) {
      r.add('📂 $collectionName');
      // 表示件数の上限を決定(Determine the maximum number of items to display)
      final sampleCount = (maxSamplesPerDb > 0)
          ? collection.length.clamp(0, maxSamplesPerDb)
          : collection.length;
      for (int i = 0; i < sampleCount; i++) {
        final record = collection.raw[i];
        String jsonString = jsonEncode(record);
        // 長い場合は末尾に...(If it is long, add "..." to the end.)
        if (jsonString.length > maxFieldLength) {
          jsonString = '${jsonString.substring(0, maxFieldLength)}...}';
        }
        if (collection.length <= maxSamplesPerDb && i == (sampleCount - 1)) {
          r.add('   └─ #${i + 1} $jsonString');
        } else {
          r.add('   ├─ #${i + 1} $jsonString');
        }
      }
      // If omitted, add a message
      if (collection.length > maxSamplesPerDb) {
        final remaining = collection.length - maxSamplesPerDb;
        final itemWord = remaining == 1 ? 'item' : 'items';
        r.add('   └─ ... ($remaining more $itemWord)');
      }
    });
    return r;
  }
}
