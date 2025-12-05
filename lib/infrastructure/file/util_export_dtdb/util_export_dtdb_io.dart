import 'dart:io';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:file_selector/file_selector.dart';

class UtilExportDTDBImpl {
  /// for desktop etc.
  /// * [data] : dtdb data.
  /// * [isLocalTime] : If false, save timestamp created from UTC time.
  /// * [useMicroSec] : If true, timestamp includes microseconds (6 digits). Otherwise milliseconds (3 digits).
  static Future<void> exportDTDB(
    List<int> data,
    bool isLocalTime,
    bool useMicroSec,
  ) async {
    String prefix = "backup";
    String exp = ".dtdb";
    // --- 現在時刻 ---
    DateTime now = isLocalTime ? DateTime.now() : DateTime.now().toUtc();
    // --- 基本フォーマット（秒まで） ---
    String base = DateFormat("yyyyMMdd'T'HHmmss").format(now);
    // --- ミリ秒 or マイクロ秒の生成 ---
    String fraction;
    if (useMicroSec) {
      // microseconds (000000〜999999)
      fraction = now.microsecond.toString().padLeft(6, '0');
    } else {
      // milliseconds (000〜999)
      fraction = now.millisecond.toString().padLeft(3, '0');
    }
    // --- 完成した timestamp ---
    String timestamp = "$base$fraction";
    // --- UUID生成 ---
    String uniqueId = Uuid().v4().replaceAll('-', '').substring(0, 8);
    // --- ファイル名 ---
    String fileName = "${prefix}_${timestamp}_$uniqueId$exp";
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Database files',
      extensions: ['dtdb'],
    );
    final FileSaveLocation? path = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [typeGroup],
      confirmButtonText: 'Save',
    );
    if (path == null) return;
    final file = File(path.path);
    await file.writeAsBytes(data);
  }
}
