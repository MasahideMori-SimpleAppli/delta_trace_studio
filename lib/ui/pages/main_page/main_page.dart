import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/infrastructure/file/util_export_dtdb.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/view_mode.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/enum_view_mode.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_widget.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_with_time.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // マネージャークラス。
  // https://pub.dev/packages/simple_managers
  final StateManager _sm = StateManager();

  final TextEditingController _tecJSON = TextEditingController(text: "");

  // 作成したクエリのバッファ
  final List<Query> _queries = [];

  // クエリまたはコード変換の結果
  String _resultStr = "Empty.";

  @override
  void initState() {
    super.initState();
    _sm.tsm.setSelection("queryMode", "Json");
    _queries.add(
      RawQueryBuilder.add(
        target: "users",
        rawAddData: [
          {"id": 0, "name": "test1"},
        ],
      ).build(),
    );
    _queries.add(
      RawQueryBuilder.add(
        target: "users",
        rawAddData: [
          {"id": 1, "name": "test2"},
        ],
      ).build(),
    );
    _queries.add(
      RawQueryBuilder.add(
        target: "users",
        rawAddData: [
          {"id": 2, "name": "test3"},
        ],
      ).build(),
    );
  }

  @override
  void dispose() {
    _sm.dispose();
    _tecJSON.dispose();
    super.dispose();
  }

  /// レイアウトを取得します。
  String? _getLayout(BuildContext context) {
    // 言語。ローカライズしたい場合はsimple_localeパッケージ(https://pub.dev/packages/simple_locale)が利用できます。
    // final String lang = LocaleManager.of(context)?.getLanguageCode() ?? "en";
    const String lang = "en";
    // ページ名
    const String pageName = "main_page";
    const String windowClass = "any";
    // 読み込むSpWMLのファイル名
    const String fileName = "main_page";
    // - assets/layout/en/main_page/any/main_page.spwml
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

  /// 必要な場合はScaffoldとSafeAreaなどで囲むラッパー。
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
      // SpWMLに設定されているSIDを使って、各種マネージャークラスを自動設定します。
      b.setStateManager(_sm);
      _initViewAndCallbacks(b);
      return _wrap(b.build(context));
    }
  }

  /// create query widgets.
  Widget _createQWidgets(String? mode) {
    if (mode == "Json") {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Text(
              "You can paste the result of debugPrint(jsonEncode(query.toDict())) in your IDE here.",
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
    } else {
      List<Widget> r = [];
      for (int index = 0; index < _queries.length; index++) {
        final i = _queries[index];
        r.add(
          QueryWidget(
            index: index,
            query: i,
            onChanged: (int index, Query? q) {
              setState(() {
                if (q == null) {
                  // delete
                  _queries.removeAt(index);
                } else {
                  // update
                  _queries[index] = q;
                }
              });
            },
          ),
        );
      }
      return SingleChildScrollView(child: Column(children: r));
    }
  }

  /// ここでビューの初期化やボタンのコールバックなどを設定します。
  void _initViewAndCallbacks(SpWMLBuilder b) {
    // 左上
    // クエリの追加や一括削除。
    // BtnElement btn1 = b.getElement("addQuery") as BtnElement;
    // btn1.setCallback(() {});
    // BtnElement btn2 = b.getElement("clearQuery") as BtnElement;
    // btn2.setCallback(() {
    //   setState(() {
    //     _queries.clear();
    //   });
    // });

    // クエリの実行モード
    DropdownBtn2Element qMode =
        b.getElement("queryMode") as DropdownBtn2Element;
    qMode.setCallback((String? mode) {
      setState(() {});
    });

    // 作成済みのクエリのリストをウィジェットとして表示
    b.replace("queryView", _createQWidgets(qMode.getValue()));

    // クエリの実行
    BtnElement btn3 = b.getElement("runQuery") as BtnElement;
    btn3.setCallback(() {
      String queryMode = qMode.getValue()!;
      if (queryMode == "Normal") {
        // Normal
      } else if (queryMode == "Transaction") {
        // Transaction
      } else {
        // Json
        final Map<String, dynamic> jsonObj = jsonDecode(_tecJSON.text);
        setState(() {
          try {
            final result = localDB.executeQueryObject(jsonObj);
            _resultStr = JsonEncoder.withIndent('  ').convert(result.toDict());
            if (result.isSuccess) {
              appliedQueries.add(
                QueryWithTime(jsonObj, DateTime.now().toUtc()),
              );
            }
          } catch (e) {
            _resultStr = e.toString();
          }
        });
      }
    });
    // BtnElement btn4 = b.getElement("convertDart") as BtnElement;
    // btn4.setCallback(() {
    //   String queryMode = qMode.getValue()!;
    //   if (queryMode == "Normal") {
    //     // Normal
    //   } else if (queryMode == "Transaction") {
    //     // Transaction
    //   } else {
    //     // Json
    //     setState(() {
    //       _resultStr = "Json to code conversion is not supported.";
    //     });
    //   }
    // });

    // 左下
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

    // 右上
    BtnElement importDB = b.getElement("importDB") as BtnElement;
    importDB.setCallback(() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['dtdb'],
          withData: true,
        );
        // キャンセル時用。
        if (result == null) return;
        final bytes = result.files.single.bytes;
        if (bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to read file."),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        final content = utf8.decode(bytes); // JSON文字列に変換
        final data = jsonDecode(content); // JSON → Mapに変換
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
                maxWidth: 600, // 最大幅を600pxに制限
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

    // 右下
    b.replace("dbView", DbView());
  }

  Future<void> _setToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
