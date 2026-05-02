import 'package:file_state_manager/file_state_manager.dart';
import 'package:delta_trace_db/delta_trace_db.dart';

class FilterFormState {
  final bool enabled1;
  final String key1;
  final EnumNodeType method1;
  final String value1;
  final EnumValueType type1;
  final bool enabled2;
  final String key2;
  final EnumNodeType method2;
  final String value2;
  final EnumValueType type2;

  const FilterFormState({
    this.enabled1 = false,
    this.key1 = '',
    this.method1 = EnumNodeType.equals_,
    this.value1 = '',
    this.type1 = EnumValueType.int_,
    this.enabled2 = false,
    this.key2 = '',
    this.method2 = EnumNodeType.equals_,
    this.value2 = '',
    this.type2 = EnumValueType.int_,
  });
}

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
