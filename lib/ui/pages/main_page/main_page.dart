import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/infrastructure/file/util_export_dtdb.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/view_mode.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/enum_view_mode.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_with_time.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_locale/simple_locale.dart';
import 'package:simple_managers/simple_managers.dart';
import 'package:simple_widget_markup/simple_widget_markup.dart';

import '../../../main.dart';
import 'enum_db_collection.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // The manager class for SpWML.
  final StateManager _sm = StateManager();

  final TextEditingController _tecJSON = TextEditingController(text: "");

  // result code.
  String _resultStr = "Empty.";

  @override
  void initState() {
    super.initState();
    _sm.tsm.setSelection("queryMode", "Json");
  }

  @override
  void dispose() {
    _sm.dispose();
    _tecJSON.dispose();
    super.dispose();
  }

  String? _getLayout(BuildContext context) {
    final String lang = LocaleManager.of(context)?.getLanguageCode() ?? "en";
    // page name
    const String pageName = "main_page";
    const String windowClass = "any";
    // loading SpWML file name
    const String fileName = "main_page";
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
    return Scaffold(body: SafeArea(child: w));
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

  /// create query widgets.
  Widget _createQWidgets() {
    // now JSON only.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Text(AppLocalizations.of(context)!.enterQueryCode,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(controller: _tecJSON, maxLines: null),
            ),
          ),
        ),
      ],
    );
  }

  /// This is where you set up view initialization, button callbacks, etc.
  void _initViewAndCallbacks(SpWMLBuilder b) {
    // query view
    b.replace("queryView", _createQWidgets());

    // run query button
    BtnElement btn3 = b.getElement("runQuery") as BtnElement;
    btn3.setCallback(() {
      // Json
      final Map<String, dynamic> jsonObj = jsonDecode(_tecJSON.text);
      setState(() {
        try {
          final result = localDB.executeQueryObject(jsonObj);
          _resultStr = JsonEncoder.withIndent('  ').convert(result.toDict());
          if (result.isSuccess) {
            appliedQueries.add(QueryWithTime(jsonObj, DateTime.now().toUtc()));
          }
        } catch (e) {
          _resultStr = e.toString();
        }
      });
    });

    // left bottom
    BtnElement btn5 = b.getElement("resultCopy") as BtnElement;
    btn5.setCallback(() async {
      await _setToClipboard(_resultStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Copied to clipboard."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
    TextElement elm2 = b.getElement("queryResult") as TextElement;
    elm2.setContentText(_resultStr);

    // right top
    BtnElement importDB = b.getElement("importDB") as BtnElement;
    importDB.setCallback(() async {
      try {
        const XTypeGroup typeGroup = XTypeGroup(
          label: 'Database files',
          extensions: ['dtdb'],
        );
        final XFile? result = await openFile(acceptedTypeGroups: [typeGroup]);
        // キャンセル時用。
        if (result == null) {
          return;
        }
        final bytes = await result.readAsBytes();
        final content = utf8.decode(bytes); // to JSON string
        final data = jsonDecode(content); // JSON → Map
        setState(() {
          localDB = DeltaTraceDatabase.fromDict(data);
          appliedQueries.clear();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
    BtnElement exportDB = b.getElement("exportDB") as BtnElement;
    exportDB.setCallback(() async {
      final bool? isLocalTime = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Export Database"),
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
                minWidth: 320,
              ),
              child: Text(
                "Can I use local time in the file name?\nIf you select No, UTC will be used.",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text("Yes"),
              ),
            ],
          );
        },
      );
      if (isLocalTime != null) {
        await UtilExportDTDB.exportDTDB(localDB.toDict(), isLocalTime);
      }
    });

    DropdownBtnElement dropDownBtn3 =
        b.getElement("viewMode") as DropdownBtnElement;
    dropDownBtn3.setCallback((int selectedIndex) {
      stateDB.executeQuery(
        QueryBuilder.clearAdd(
          target: EnumDbCollection.dbViewMode.name,
          addData: [ViewMode(EnumViewMode.values.elementAt(selectedIndex))],
        ).build(),
      );
    });

    // right bottom
    b.replace("dbView", DbView());
  }

  Future<void> _setToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
