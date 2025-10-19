import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/filter_data.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/filter_dialog.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/filtered_item.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/pagination_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_locale/simple_locale.dart';

import 'package:simple_managers/simple_managers.dart';
import 'package:simple_widget_markup/simple_widget_markup.dart';

class DbViewList extends StatefulWidget {
  const DbViewList({super.key});

  @override
  State createState() => _DbViewListState();
}

class _DbViewListState extends State<DbViewList> {
  // The manager class for SpWML.
  final StateManager _sm = StateManager();
  final StateManager _filterSm = StateManager();
  static const int _defItemsPerPage = 10;
  String? _selectedTarget;
  int _itemsPerPage = _defItemsPerPage;
  int _pageIndex = 0;
  final ScrollController _scCtrl = ScrollController();
  final _tec = TextEditingController();

  final List<FilteredItem> _filteredItem = [];
  FilterData _filterData = FilterData(null, null);

  @override
  void initState() {
    super.initState();
    _sm.tsm.setSelection("itemsPerPage", _defItemsPerPage.toString());
    _filterSm.tsm.setSelection("comparisonMethod1", EnumNodeType.equals_.name);
    _filterSm.tsm.setSelection("type1", "int_");
    _filterSm.tsm.setSelection("comparisonMethod2", EnumNodeType.equals_.name);
    _filterSm.tsm.setSelection("type2", "int_");
  }

  @override
  void dispose() {
    _sm.dispose();
    _filterSm.dispose();
    _scCtrl.dispose();
    _tec.dispose();
    super.dispose();
  }

  String? _getLayout(BuildContext context) {
    final String lang = LocaleManager.of(context)?.getLanguageCode() ?? "en";
    // page name
    const String pageName = "main_page";
    const String windowClass = "any";
    // loading SpWML file name
    const String fileName = "db_view_list";
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

  /// This is where you set up view initialization, button callbacks, etc.
  void _initViewAndCallbacks(SpWMLBuilder b) {
    // ターゲットを設定。
    b.replace(
      "targetCollectionDDBtn",
      _buildStringDropdown(
        items: localDB.raw.keys.toList(),
        selectedValue: _selectedTarget,
        onChanged: (String? s) {
          setState(() {
            _selectedTarget = s;
            _resetFilter();
          });
        },
      ),
    );
    // フィルタの計算。
    _searchFilter();
    // トータルページ数の計算
    int totalPages = _getTotalPages();
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
    b.replaceUnderStructure(
      "collectionItems",
      (_filterData.isFilterEnabled())
          ? _getCollectionItemsForFilter(_selectedTarget)
          : _getCollectionItemsNonFilter(_selectedTarget),
    );
    // filter
    BtnElement filterBtn = b.getElement("filter") as BtnElement;
    filterBtn.setCallback(() async {
      final FilterData? result = await showDialog<FilterData>(
        context: context,
        barrierDismissible: false, // 外をタップして閉じないようにする
        builder: (context) => FilterDialog(_filterSm),
      );
      if (result != null) {
        setState(() {
          _filterData = result;
        });
      }
    });
    if (_filterData.isFilterEnabled()) {
      filterBtn.setBtnColor(Colors.red);
    }
    // removeCollection
    BtnElement removeCollectionBtn =
        b.getElement("removeCollection") as BtnElement;
    if (_selectedTarget == null) {
      removeCollectionBtn.setEnabled(false);
    }
    removeCollectionBtn.setCallback(() {
      showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Confirmation'),
            content: const Text(
              'The displayed collection will be deleted from the database.\nAre you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // ダイアログを閉じる
                },
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // ダイアログを閉じる
                  setState(() {
                    if (_selectedTarget != null) {
                      localDB.removeCollection(_selectedTarget!);
                      _selectedTarget = null;
                      _resetFilter();
                    }
                  });
                },
                child: const Text('Yes'),
              ),
            ],
          );
        },
      );
    });
  }

  void _resetFilter() {
    _pageIndex = 0;
    _filteredItem.clear();
    _filterData = FilterData(null, null);
    _filterSm.fm.setFlag("switch1", false);
    _filterSm.fm.setFlag("switch2", false);
  }

  /// フィルターを使用してサーチし、結果を保持して画面更新します。
  void _searchFilter() {
    if (_filterData.isFilterEnabled()) {
      _filteredItem.clear();
      int index = 0;
      for (Map<String, dynamic> i in localDB.collection(_selectedTarget!).raw) {
        if (_filterData.node1 != null && _filterData.node2 == null) {
          if (_filterData.node1!.evaluate(i)) {
            _filteredItem.add(FilteredItem(index, i));
          }
        } else if (_filterData.node1 == null && _filterData.node2 != null) {
          if (_filterData.node2!.evaluate(i)) {
            _filteredItem.add(FilteredItem(index, i));
          }
        } else {
          if (_filterData.node1!.evaluate(i) &&
              _filterData.node2!.evaluate(i)) {
            _filteredItem.add(FilteredItem(index, i));
          }
        }
        index += 1;
      }
    }
  }

  /// Stringリストからドロップダウンボタンを作成する関数
  Widget _buildStringDropdown({
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    String hintText = "Please select",
  }) {
    return DropdownButton<String>(
      value: selectedValue,
      hint: Text(hintText),
      isExpanded: false,
      items: items.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: onChanged,
    );
  }

  /// トータルページ数を返します。フィルタが有効な場合はフィルタされたターゲットも計算されます。
  int _getTotalPages() {
    if (_filterData.isFilterEnabled()) {
      int totalPages = _selectedTarget == null
          ? 1
          : (_filteredItem.length / _itemsPerPage).ceil();
      if (totalPages == 0) {
        totalPages = 1;
      }
      return totalPages;
    } else {
      int totalPages = _selectedTarget == null
          ? 1
          : (localDB.collection(_selectedTarget!).length / _itemsPerPage)
                .ceil();
      if (totalPages == 0) {
        totalPages = 1;
      }
      return totalPages;
    }
  }

  /// フィルタ有りの場合に選択中のコレクションの内容をWidgetのリストに変換する関数。
  List<Widget> _getCollectionItemsForFilter(String? target) {
    if (target == null) {
      return [SpWML("(text, mT:2, pAll:8)Please select target collection.")];
    }
    final offset = _pageIndex * _itemsPerPage;
    List<FilteredItem> items = _filteredItem
        .skip(offset)
        .take(_itemsPerPage)
        .toList();
    return items.map((item) {
      final itemNumInDb = item.index + 1;
      // JSON全体を整形して文字列化
      final jsonStr = const JsonEncoder.withIndent('  ').convert(item.item);
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
                      "$itemNumInDb ",
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
                                minWidth: 320,
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
                            localDB.collection(target).raw[itemNumInDb - 1] =
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

  /// フィルタ無しの場合に選択中のコレクションの内容をWidgetのリストに変換する関数。
  List<Widget> _getCollectionItemsNonFilter(String? target) {
    if (target == null) {
      return [SpWML("(text, mT:2, pAll:8)Please select target collection.")];
    }
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
                                minWidth: 320,
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
