import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_query.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_tree.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/enum_view_mode.dart';
import 'package:flutter/material.dart';

class DbView extends StatelessWidget {
  final EnumViewMode viewMode;

  const DbView({super.key, required this.viewMode});

  @override
  Widget build(BuildContext context) {
    switch (viewMode) {
      case EnumViewMode.listView:
        return DbViewList(key: ValueKey(dbVersion));
      case EnumViewMode.treeView:
        return DbViewTree();
      case EnumViewMode.queryView:
        return DbViewQuery();
    }
  }
}
