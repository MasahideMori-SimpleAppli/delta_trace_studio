import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:file_selector/file_selector.dart';

class UtilExportDTDBImpl {
  /// for desktop etc.
  /// * [data] : dtdb data.
  /// * [isLocalTime] : If false, save timestamp create from UTC time.
  static Future<void> exportDTDB(
    Map<String, dynamic> data,
    bool isLocalTime,
  ) async {
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
    // ファイルタイプを指定（任意）
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Database files',
      extensions: ['dtdb'],
    );
    // 保存先パスを選択
    final FileSaveLocation? path = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [typeGroup],
      confirmButtonText: 'Save',
    );
    if (path == null) return;
    final file = File(path.path);
    await file.writeAsString(jsonEncode(data));
  }
}
