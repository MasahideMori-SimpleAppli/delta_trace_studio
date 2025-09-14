import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class UtilExportDTDBImpl {

  /// for desktop etc.
  /// * [data] : dtdb data.
  /// * [isLocalTime] : If false, save timestamp create from UTC time.
  static Future<void> exportDTDB(Map<String, dynamic> data, bool isLocalTime) async {
    String prefix = "backup";
    String exp = ".dtdb";
    // 現在時刻
    DateTime now = isLocalTime ? DateTime.now() : DateTime.now().toUtc();
    // タイムスタンプ生成 (YYYYMMDDTHHMMSSfff)
    String timestamp = DateFormat("yyyyMMdd'T'HHmmssSSS").format(now);
    // UUID生成 (先頭8文字)
    String uniqueId = Uuid().v4().replaceAll('-', '').substring(0, 8);
    // ファイル名生成
    String fileName = "${prefix}_${timestamp}_$uniqueId$exp";
    String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save JSON file',
      fileName: fileName,
    );
    if (path == null) return;
    final file = File(path);
    await file.writeAsString(jsonEncode(data));
  }
}
