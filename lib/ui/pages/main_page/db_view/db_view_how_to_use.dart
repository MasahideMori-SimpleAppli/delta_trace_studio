import 'package:flutter/material.dart';
import 'package:simple_locale/simple_locale.dart';

import 'package:simple_managers/simple_managers.dart';
import 'package:simple_widget_markup/simple_widget_markup.dart';

class DbViewHowToUse extends StatefulWidget {
  const DbViewHowToUse({super.key});

  @override
  State createState() => _DbViewHowToUseState();
}

class _DbViewHowToUseState extends State<DbViewHowToUse> {
  // The manager class for SpWML.
  final StateManager _sm = StateManager();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _sm.dispose();
    super.dispose();
  }

  String? _getLayout(BuildContext context) {
    final String lang = LocaleManager.of(context)?.getLanguageCode() ?? "en";
    // page name
    const String pageName = "main_page";
    const String windowClass = "any";
    // loading SpWML file name
    const String fileName = "db_view_how_to_use";
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
    // show the how to use by spwml only.
  }
}
