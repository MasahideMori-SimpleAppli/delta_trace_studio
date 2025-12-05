import 'package:file_state_manager/file_state_manager.dart';
import 'package:delta_trace_db/delta_trace_db.dart';

class FilterData extends CloneableFile {
  QueryNode? node1;
  QueryNode? node2;

  FilterData(this.node1, this.node2);

  factory FilterData.fromDict(Map<String, dynamic> src) {
    return FilterData(
      src["node1"] != null ? QueryNode.fromDict(src["node1"]!) : null,
      src["node2"] != null ? QueryNode.fromDict(src["node2"]!) : null,
    );
  }

  @override
  FilterData clone() {
    return FilterData.fromDict(toDict());
  }

  @override
  Map<String, dynamic> toDict() {
    return {"node1": node1?.toDict(), "node2": node2?.toDict()};
  }

  /// Enable filter, return true;
  bool isFilterEnabled() {
    return node1 != null || node2 != null;
  }
}
