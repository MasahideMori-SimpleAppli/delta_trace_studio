import 'package:file_state_manager/file_state_manager.dart';

import 'package:delta_trace_studio/ui/pages/main_page/db_view/enum_view_mode.dart';

class ViewMode extends CloneableFile {
  EnumViewMode viewMode;

  ViewMode(this.viewMode);

  factory ViewMode.fromDict(Map<String, dynamic> src) {
    return ViewMode(EnumViewMode.values.byName(src["mode"]));
  }

  @override
  ViewMode clone() {
    return ViewMode.fromDict(toDict());
  }

  @override
  Map<String, dynamic> toDict() {
    return {"mode": viewMode.name};
  }
}
