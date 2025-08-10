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

  @override
  void dispose(){
    _sm.dispose();
    super.dispose();
  }

  /// TODO プロジェクトの仕様に応じて変更してください。
  /// レイアウトを取得します。
  String? _getLayout(BuildContext context){
    // 言語。ローカライズしたい場合はsimple_localeパッケージ(https://pub.dev/packages/simple_locale)が利用できます。
    // final String lang = LocaleManager.of(context)?.getLanguageCode() ?? "en";
    const String lang = "en";
    // ページ名
    const String pageName = "main_page";
    // TODO 画面サイズ。any以外を自動で切り替えたい場合はSpWMLLayoutManager.getWindowClass(context).nameが利用できます。
    const String windowClass = "any";
    // 読み込むSpWMLのファイル名
    const String fileName = "main_page";
    // TODO このパスをpubspec.yamlに追加してください。
    // - assets/layout/en/main_page/any/main_page.spwml
    final String path = "assets/layout/$lang/$pageName/$windowClass/$fileName.spwml";
    return SpWMLLayoutManager().getAssets(path, () {
      if (mounted) {
        setState(() {});
      }
    }, (e) {
      // TODO 読込エラーが発生した場合の処理。
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

  /// TODO ここでビューの初期化やボタンのコールバックなどを設定します。
  void _initViewAndCallbacks(SpWMLBuilder b){
    BtnElement btn1 = b.getElement("runQuery") as BtnElement;
    btn1.setCallback(() {});
    DropdownBtnElement dropDownBtn1 = b.getElement("queryMode") as DropdownBtnElement;
    dropDownBtn1.setCallback((int selectedIndex) {});
    DropdownBtnElement dropDownBtn2 = b.getElement("queryType") as DropdownBtnElement;
    dropDownBtn2.setCallback((int selectedIndex) {});
    DropdownBtnElement dropDownBtn3 = b.getElement("viewMode") as DropdownBtnElement;
    dropDownBtn3.setCallback((int selectedIndex) {});
    DropdownBtnElement dropDownBtn4 = b.getElement("samplingNum") as DropdownBtnElement;
    dropDownBtn4.setCallback((int selectedIndex) {});
    // b.replace("queryBlock", 置き換えたいウィジェット);
    // b.replace("queryInput", 置き換えたいウィジェット);
    // b.replace("dbView", 置き換えたいウィジェット);
    TextFieldElement elm1 = b.getElement("collectionName") as TextFieldElement;
    TextElement elm2 = b.getElement("queryResult") as TextElement;
  }

}
