import 'package:delta_trace_studio/infrastructure/file/util_export_dtdb/util_export_dtdb_io.dart'
    if (dart.library.js) 'package:delta_trace_studio/infrastructure/file/util_export_dtdb/util_export_dtdb_web.dart';

class UtilExportDTDB {
  static Future<void> exportDTDB(Map<String, dynamic> data, bool isLocalTime) async {
    return UtilExportDTDBImpl.exportDTDB(data, isLocalTime);
  }
}
