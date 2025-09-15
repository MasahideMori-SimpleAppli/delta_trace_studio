import 'dart:convert';

import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/pagination_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:simple_managers/simple_managers.dart';
import 'package:simple_widget_markup/simple_widget_markup.dart';

class DbViewList extends StatefulWidget {
  const DbViewList({super.key});

  @override
  State createState() => _DbViewListState();
}

class _DbViewListState extends State<DbViewList> {
  // マネージャークラス。
  // https://pub.dev/packages/simple_managers
  final StateManager _sm = StateManager();
  static const int _defItemsPerPage = 10;
  String? _target;
  int _itemsPerPage = _defItemsPerPage;
  int _pageIndex = 0;
  final ScrollController _scCtrl = ScrollController();
  final _tec = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sm.tsm.setSelection("itemsPerPage", _defItemsPerPage.toString());
  }

  void dbChangeCallback() {
    setState(() {
      // 必要な場合は追加の処理を入れることも可能。
    });
  }

  @override
  void dispose() {
    _sm.dispose();
    _scCtrl.dispose();
    _tec.dispose();
    if (_target != null && _target != "") {
      localDB.removeListener(_target!, dbChangeCallback);
    }
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
    const String fileName = "db_view_list";
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
    // ターゲットによって分岐。
    TextFieldElement tfe =
        b.getElement("targetCollectionName") as TextFieldElement;
    tfe.setOnEditingComplete(() {
      setState(() {
        // 画面更新。
      });
    });
    if (_target != null && _target != "") {
      localDB.removeListener(_target!, dbChangeCallback);
    }
    _target = tfe.getValue();
    if (_target == null || _target == "") {
      return;
    }
    localDB.addListener(_target!, dbChangeCallback);
    // トータルページ数などの計算
    int totalPages = (localDB.collection(_target!).length / _itemsPerPage)
        .ceil();
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
    b.replaceUnderStructure("collectionItems", _getCollectionItems(_target!));
  }

  List<Widget> _getCollectionItems(String target) {
    final offset = _pageIndex * _itemsPerPage;
    List<Map<String, dynamic>> items = localDB
        .collection(target)
        .raw
        .skip(offset)
        .take(_itemsPerPage)
        .toList();
    int itemNum = offset;
    return items.map((item) {
      itemNum += 1;
      final int nowItemNum = itemNum;
      // JSON全体を整形して文字列化
      final jsonStr = const JsonEncoder.withIndent('  ').convert(item);
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル行
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "$nowItemNum. ",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () async {
                      _tec.text = jsonStr;
                      final updated = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Edit JSON"),
                            content: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 600, // 最大幅を600pxに制限
                                minWidth: 320
                              ),
                              child: SingleChildScrollView(
                                child: TextField(
                                  controller: _tec,
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, _tec.text);
                                },
                                child: const Text("Save"),
                              ),
                            ],
                          );
                        },
                      );
                      if (updated != null) {
                        try {
                          // JSONをパースしてMapに戻す
                          final newItem =
                              jsonDecode(updated) as Map<String, dynamic>;
                          setState(() {
                            // rawリストを書き換え
                            localDB.collection(target).raw[nowItemNum - 1] =
                                newItem;
                          });
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Invalid JSON format"),
                              ),
                            );
                          }
                        }
                      }
                    },
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
