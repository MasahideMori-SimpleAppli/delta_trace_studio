import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/main.dart';
import 'package:flutter/material.dart';

import 'package:simple_managers/simple_managers.dart';
import 'package:simple_widget_markup/simple_widget_markup.dart';

class DbViewTree extends StatefulWidget {
  const DbViewTree({super.key});

  @override
  State createState() => _DbViewTreeState();
}

class _DbViewTreeState extends State<DbViewTree> {
  // マネージャークラス。
  // https://pub.dev/packages/simple_managers
  final StateManager _sm = StateManager();

  @override
  void initState() {
    super.initState();
    // ドロップダウンボタンの値を初期化。
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
    // 言語。ローカライズしたい場合はsimple_localeパッケージ(https://pub.dev/packages/simple_locale)が利用できます。
    // final String lang = LocaleManager.of(context)?.getLanguageCode() ?? "en";
    const String lang = "en";
    // ページ名
    const String pageName = "main_page";
    const String windowClass = "any";
    // 読み込むSpWMLのファイル名
    const String fileName = "db_view_tree";
    // - assets/layout/en/main_page/any/db_view_tree.spwml
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
    DropdownBtn2Element dropDownBtn2Elm1 =
        b.getElement("samplingNum") as DropdownBtn2Element;
    dropDownBtn2Elm1.setCallback((String? tag) {
      if (tag != null) {
        // 画面更新。
        setState(() {});
      }
    });
    DropdownBtn2Element dropDownBtn2Elm2 =
        b.getElement("textLength") as DropdownBtn2Element;
    dropDownBtn2Elm2.setCallback((String? tag) {
      if (tag != null) {
        // 画面更新。
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

  /// テキスト型の階層表示用リストに変換する関数
  ///
  /// * [dbData] : DBの内容。
  /// * [maxFieldLength] : フィールドに表示する文字列の最大文字数。
  /// * [maxSamplesPerDb] : 各DBから表示するレコード数の上限（0以下なら全件表示）。
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
      // 表示件数の上限を決定
      final sampleCount = (maxSamplesPerDb > 0)
          ? collection.length.clamp(0, maxSamplesPerDb)
          : collection.length;
      // 省略が必要かどうかのフラグ。
      for (int i = 0; i < sampleCount; i++) {
        final record = collection.raw[i];
        // JSON文字列に変換
        String jsonString = jsonEncode(record);
        // 長い場合は末尾に...
        if (jsonString.length > maxFieldLength) {
          jsonString = '${jsonString.substring(0, maxFieldLength)}...}';
        }
        if (collection.length <= maxSamplesPerDb && i == (sampleCount - 1)) {
          r.add('   └─ #${i + 1} $jsonString');
        } else {
          r.add('   ├─ #${i + 1} $jsonString');
        }
      }
      // 省略した場合はメッセージを追加
      if (collection.length > maxSamplesPerDb) {
        final remaining = collection.length - maxSamplesPerDb;
        final itemWord = remaining == 1 ? 'item' : 'items';
        r.add('   └─ ... ($remaining more $itemWord)');
      }
    });
    return r;
  }
}
