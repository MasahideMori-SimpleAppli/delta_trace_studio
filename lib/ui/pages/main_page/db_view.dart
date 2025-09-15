import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_log.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/view_mode.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_tree.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/enum_view_mode.dart';
import 'package:delta_trace_studio/ui/pages/main_page/enum_db_collection.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class DbView extends StatefulWidget {
  const DbView({super.key});

  @override
  State<DbView> createState() => _DbViewState();
}

class _DbViewState extends State<DbView> {
  ViewMode _dbViewMode = ViewMode(EnumViewMode.treeView);

  @override
  void initState() {
    super.initState();
    stateDB.addListener(EnumDbCollection.dbViewMode.name, dbChangeCallback);
  }

  @override
  void dispose() {
    stateDB.removeListener(EnumDbCollection.dbViewMode.name, dbChangeCallback);
    super.dispose();
  }

  void dbChangeCallback() {
    setState(() {
      // 必要な場合は追加の処理を入れることも可能。
    });
  }

  @override
  Widget build(BuildContext context) {
    QueryResult r = stateDB.executeQuery<ViewMode>(
      QueryBuilder.getAll(target: EnumDbCollection.dbViewMode.name).build(),
    );
    if (r.isSuccess && r.result.isNotEmpty) {
      _dbViewMode = r.convert(ViewMode.fromDict).first;
    }
    switch (_dbViewMode.viewMode) {
      case EnumViewMode.treeView:
        return DbViewTree();
      case EnumViewMode.listView:
        return DbViewList();
      case EnumViewMode.logView:
        return DbViewLog();
    }
  }
}
