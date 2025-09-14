import 'dart:convert';

import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/pagination_widget.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_with_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:simple_managers/simple_managers.dart';
import 'package:simple_widget_markup/simple_widget_markup.dart';

class DbViewLog extends StatefulWidget {
  const DbViewLog({super.key});

  @override
  State createState() => _DbViewLogState();
}

class _DbViewLogState extends State<DbViewLog> {
  // マネージャークラス。
  // https://pub.dev/packages/simple_managers
  final StateManager _sm = StateManager();
  static const int _defItemsPerPage = 5;
  int _itemsPerPage = _defItemsPerPage;
  int _pageIndex = 0;
  final ScrollController _scCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _sm.tsm.setSelection("itemsPerPage", _defItemsPerPage.toString());
  }

  @override
  void dispose() {
    _sm.dispose();
    _scCtrl.dispose();
    super.dispose();
  }

  /// レイアウトを取得します。
  String? _getLayout(BuildContext context) {
    // 言語。ローカライズしたい場合はsimple_localeパッケージ(https://pub.dev/packages/simple_locale)が利用できます。
    // final String lang = LocaleManager.of(context)?.getLanguageCode() ?? "en";
    const String lang = "en";
    // ページ名
    const String pageName = "main_page";
    // 画面サイズ。any以外を自動で切り替えたい場合はSpWMLLayoutManager.getWindowClass(context).nameが利用できます。
    const String windowClass = "any";
    // 読み込むSpWMLのファイル名
    const String fileName = "db_view_log";
    // このパスをpubspec.yamlに追加してください。
    // - assets/layout/en/main_page/any/db_view_log.spwml
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
    return w;
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

  /// ここでビューの初期化やボタンのコールバックなどを設定します。
  void _initViewAndCallbacks(SpWMLBuilder b) {
    // トータルページ数などの計算
    int totalPages = (appliedQueries.length / _itemsPerPage).ceil();
    if (totalPages == 0) {
      totalPages = 1;
    }
    // UI
    DropdownBtn2Element dropDownBtn2No1 =
        b.getElement("itemsPerPage") as DropdownBtn2Element;
    dropDownBtn2No1.setCallback((String? tag) {
      if (tag != null) {
        setState(() {
          _itemsPerPage = int.tryParse(tag) ?? _defItemsPerPage;
        });
      }
    });
    b.replace(
      "paging",
      PaginationWidget(
        pageNum: _pageIndex + 1,
        totalPages: totalPages,
        callback: (int selectedPageNum) {
          setState(() {
            _scCtrl.jumpTo(0);
            _pageIndex = selectedPageNum - 1;
          });
        },
      ),
    );
    (b.getElement("scrollView") as ScrollElement).setScrollController(_scCtrl);
    b.replaceUnderStructure("queries", _getQueriesList());
  }

  List<Widget> _getQueriesList() {
    final offset = _pageIndex * _itemsPerPage;
    List<QueryWithTime> queries = appliedQueries
        .skip(offset)
        .take(_itemsPerPage)
        .toList();
    int queryNum = offset;
    return queries.map((query) {
      queryNum += 1;
      final type = query.q['type']?.toString() ?? 'unknown';
      // JSON全体を整形して文字列化
      final jsonStr = const JsonEncoder.withIndent('  ').convert(query.q);
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$queryNum. ${type.toUpperCase()} ${query.dt.toLocal().toIso8601String()}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: jsonStr));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Query copied to clipboard'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Divider(),
              Text(jsonStr),
            ],
          ),
        ),
      );
    }).toList();
  }
}
