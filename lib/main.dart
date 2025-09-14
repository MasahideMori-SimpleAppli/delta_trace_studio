import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/drawer/util_drawer.dart';
import 'package:delta_trace_studio/ui/pages/main_page/main_page.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_with_time.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_locale/simple_locale.dart';

// DBを定義。
// ローカルテスト用のDB。
DeltaTraceDatabase localDB = DeltaTraceDatabase();
// このセッションで適用が成功したクエリのリスト。
final List<QueryWithTime> appliedQueries = [];
// 状態管理用のDB。
final stateDB = DeltaTraceDatabase();

void main() {
  // test code
  // debugPrint(
  //   jsonEncode(
  //     RawQueryBuilder.add(
  //       target: "test",
  //       rawAddData: [
  //         {"test": "test", "a": "b"},
  //       ],
  //     ).build().toDict(),
  //   ),
  // );
  //
  // localDB.executeQuery(
  //   RawQueryBuilder.add(
  //     target: "users",
  //     rawAddData: [
  //       {"id": 0, "name": "test1"},
  //       {"id": 1, "name": "test2"},
  //       {"id": 2, "name": "test3"},
  //     ],
  //   ).build(),
  // );
  //
  // localDB.executeQuery(
  //   RawQueryBuilder.add(
  //     target: "tickets",
  //     rawAddData: [
  //       {
  //         "id": 0,
  //         "name": "test1",
  //         "class": "A",
  //         "context": "aaaaaaaaaaaaaaaaaaaaaaaaaa",
  //       },
  //       {
  //         "id": 1,
  //         "name": "test2",
  //         "class": "B",
  //         "context": "aaaaaaaaaaaaaaaaaaaaaaaaaa",
  //       },
  //       {
  //         "id": 2,
  //         "name": "test3",
  //         "class": "C",
  //         "context": "aaaaaaaaaaaaaaaaaaaaaaaaaa",
  //       },
  //     ],
  //   ).build(),
  // );

  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/fonts/Noto_Sans_JP/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(
    LocalizedApp(
      supportedLocales: AppLocalizations.supportedLocales,
      child: const DeltaTraceStudioApp(),
    ),
  );
}

class DeltaTraceStudioApp extends StatelessWidget {
  const DeltaTraceStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: LocaleManager.of(context)?.getLocaleForApp(),
      title: 'DeltaTrace Studio',
      theme: ThemeData(
        fontFamily: "Noto Sans JP",
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DeltaTraceStudioHome(),
    );
  }
}

class DeltaTraceStudioHome extends StatefulWidget {
  const DeltaTraceStudioHome({super.key});

  @override
  State<DeltaTraceStudioHome> createState() => _DeltaTraceStudioHomeState();
}

class _DeltaTraceStudioHomeState extends State<DeltaTraceStudioHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DeltaTrace Studio')),
      drawer: UtilDrawer.createDrawer(context),
      body: MainPage(),
    );
  }
}
