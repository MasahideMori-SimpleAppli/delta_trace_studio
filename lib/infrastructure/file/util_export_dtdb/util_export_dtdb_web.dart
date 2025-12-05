import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;
import 'dart:typed_data';

@JS("Blob")
extension type Blob._(JSObject _) implements JSObject {
  external factory Blob(JSArray<JSArrayBuffer> blobParts, JSObject? options);

  factory Blob.fromBytes(List<int> bytes) {
    final data = Uint8List.fromList(bytes).buffer.toJS;
    return Blob([data].toJS, null);
  }

  external JSArrayBuffer? get blobParts;

  external JSObject? get options;
}

class UtilExportDTDBImpl {
  /// for web.
  ///
  /// * [data] : dtdb data.
  /// * [isLocalTime] : If false, save timestamp create from UTC time.
  /// * [useMicroSec] : If true, timestamp includes microseconds (6 digits). Otherwise milliseconds (3 digits).
  static Future<void> exportDTDB(
    List<int> data,
    bool isLocalTime,
    bool useMicroSec,
  ) async {
    String prefix = "backup";
    String exp = ".dtdb";
    // 現在時刻
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
    // UUID生成 (先頭8文字)
    String uniqueId = Uuid().v4().replaceAll('-', '').substring(0, 8);
    // ファイル名生成
    String fileName = "${prefix}_${timestamp}_$uniqueId$exp";
    final url = web.URL.createObjectURL(Blob.fromBytes(data));
    final JSObject document =
        globalContext.getProperty('document'.toJS) as JSObject;
    final JSObject anchor =
        document.callMethod('createElement'.toJS, 'a'.toJS) as JSObject;
    anchor.setProperty('href'.toJS, url.toJS);
    anchor.setProperty('style'.toJS, 'display: none'.toJS);
    anchor.setProperty('rel'.toJS, 'noopener'.toJS);
    anchor.setProperty('target'.toJS, '_blank'.toJS);
    anchor.setProperty('download'.toJS, fileName.toJS);
    final JSObject? body = document.getProperty('body'.toJS) as JSObject?;
    body?.callMethod('appendChild'.toJS, anchor);
    anchor.callMethod('click'.toJS);
    body?.callMethod('removeChild'.toJS, anchor);
    final JSObject urlObj = globalContext.getProperty('URL'.toJS) as JSObject;
    urlObj.callMethod('revokeObjectURL'.toJS, url.toJS);
  }
}
