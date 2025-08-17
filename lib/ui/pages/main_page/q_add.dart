import 'package:flutter/material.dart';

import 'package:simple_managers/simple_managers.dart';
import 'package:simple_widget_markup/simple_widget_markup.dart';
class QAdd extends StatefulWidget {
  const QAdd({super.key});

  @override
  State createState() => _QAddState();
}

class _QAddState extends State<QAdd>{
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
    const String windowClass = "any";
    // 読み込むSpWMLのファイル名
    const String fileName = "q_add";
    // - assets/layout/en/main_page/any/q_add.spwml
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
    return w;
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
    SwitchBtnElement switchBtn1 = b.getElement("mustAffectAtLeastOne") as SwitchBtnElement;
    switchBtn1.setCallback((bool btnEnabled) {});
    TextFieldElement elm1 = b.getElement("collectionName") as TextFieldElement;
    TextFieldElement elm2 = b.getElement("addData") as TextFieldElement;
  }

}
