import 'dart:convert';
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
  static Future<void> exportDTDB(Map<String, dynamic> data, bool isLocalTime) async {
    final jsonStr = jsonEncode(data);
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
    final Uint8List bytes = utf8.encode(jsonStr);
    final url = web.URL.createObjectURL(Blob.fromBytes(bytes.toList()));
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
