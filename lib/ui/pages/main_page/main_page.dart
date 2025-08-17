import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:flutter/material.dart';
import 'package:simple_managers/simple_managers.dart';
import 'package:simple_widget_markup/simple_widget_markup.dart';
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>{
  // マネージャークラス。
  // https://pub.dev/packages/simple_managers
  final StateManager _sm = StateManager();

  // 作成したクエリのバッファ
  List<Query> _queries = [];
  
  @override
  void initState() {
    super.initState();
    _sm.tsm.setSelection("queryMode", "Normal");
    _queries.add(RawQueryBuilder.add(target: "users", rawAddData: [{"id" : 0, "name" : "test1"}]).build());
    _queries.add(RawQueryBuilder.add(target: "users", rawAddData: [{"id" : 1, "name" : "test2"}]).build());
    _queries.add(RawQueryBuilder.add(target: "users", rawAddData: [{"id" : 2, "name" : "test3"}]).build());
  }

  @override
  void dispose(){
    _sm.dispose();
    super.dispose();
  }

  /// レイアウトを取得します。
  String? _getLayout(BuildContext context){
    // 言語。ローカライズしたい場合はsimple_localeパッケージ(https://pub.dev/packages/simple_locale)が利用できます。
    // final String lang = LocaleManager.of(context)?.getLanguageCode() ?? "en";
    const String lang = "en";
    // ページ名
    const String pageName = "main_page";
    const String windowClass = "any";
    // 読み込むSpWMLのファイル名
    const String fileName = "main_page";
    // - assets/layout/en/main_page/any/main_page.spwml
    final String path = "assets/layout/$lang/$pageName/$windowClass/$fileName.spwml";
    return SpWMLLayoutManager().getAssets(path, () {
      if (mounted) {
        setState(() {});
      }
    }, (e) {
      debugPrint("SpWMLLoadingError");
    });
  }

  /// 必要な場合はScaffoldとSafeAreaなどで囲むラッパー。
  Widget _wrap(Widget w){
    return Scaffold(body: SafeArea(child: w));
  }

  @override
  Widget build(BuildContext context){
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

  List<Widget> _createQueryWidgets() {
    List<Widget> r = [];
    for (int index = 0; index < _queries.length; index++) {
      final i = _queries[index];
      r.add(
        Card(
          child: ListTile(
            title: Text(i.target),
            subtitle: Text(i.type.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _queries.removeAt(index);
                });
              },
            ),
            onTap: () async {

              // if (newQuery != null) {
              //   setState(() {
              //     _queries[index] = newQuery;
              //   });
              // }
            },
          ),
        ),
      );
    }
    return r;
  }


  /// ここでビューの初期化やボタンのコールバックなどを設定します。
  void _initViewAndCallbacks(SpWMLBuilder b){
    // クエリの追加や一括削除。
    BtnElement btn1 = b.getElement("addQuery") as BtnElement;
    btn1.setCallback(() {

    });
    BtnElement btn2 = b.getElement("clearQuery") as BtnElement;
    btn2.setCallback(() {
      setState(() {
        _queries.clear();
      });
    });

    // 作成済みのクエリのリストをウィジェットとして表示
    b.replaceUnderStructure("queryList", _createQueryWidgets());

    // クエリの実行
    BtnElement btn3 = b.getElement("runQuery") as BtnElement;
    btn3.setCallback(() {
      DropdownBtn2Element ddBtn1 = b.getElement("queryMode") as DropdownBtn2Element;
      String queryMode = ddBtn1.getValue()!;
      if(queryMode == "Normal"){
        // Normal

      }
      else{
        // Transaction

      }
    });
    BtnElement btn4 = b.getElement("convertCode") as BtnElement;
    btn4.setCallback(() {
      DropdownBtn2Element ddBtn1 = b.getElement("queryMode") as DropdownBtn2Element;
      String queryMode = ddBtn1.getValue()!;
      if(queryMode == "Normal"){
        // Normal

      }
      else{
        // Transaction

      }
    });
    // 右側
    DropdownBtnElement dropDownBtn3 = b.getElement("viewMode") as DropdownBtnElement;
    dropDownBtn3.setCallback((int selectedIndex) {});
    TextElement elm2 = b.getElement("queryResult") as TextElement;
  }

}
