import 'package:delta_trace_studio/infrastructure/file/util_export_dtdb/util_export_dtdb_io.dart'
    if (dart.library.js) 'package:delta_trace_studio/infrastructure/file/util_export_dtdb/util_export_dtdb_web.dart';

class UtilExportDTDB {
  static Future<void> exportDTDB(
    List<int> data,
    bool isLocalTime,
    bool useMicroSec,
  ) async {
    return UtilExportDTDBImpl.exportDTDB(data, isLocalTime, useMicroSec);
  }
}
