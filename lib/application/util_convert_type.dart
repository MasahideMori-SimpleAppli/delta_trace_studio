/// (en) The type that values of a key are converted to.
///
/// (ja) キーの値の変換後の型です。
enum EnumConvertType { int_, double_, bool_, string_ }

/// (en) The result of converting the values of a key.
///
/// (ja) キーの値を変換した結果です。
class ConvertTypeResult {
  /// (en) The items after conversion (copies; the input is not changed).
  ///
  /// (ja) 変換後の要素（コピーで、入力は変更されません）。
  final List<Map<String, dynamic>> items;

  /// (en) The number of values that were changed.
  ///
  /// (ja) 変更された値の数。
  final int changedCount;

  /// (en) The number of values that could not be converted.
  ///
  /// (ja) 変換できなかった値の数。
  final int failedCount;

  /// (en) The first value that could not be converted, or null.
  ///
  /// (ja) 最初に変換できなかった値。無い場合は null。
  final Object? firstFailed;

  /// * [items] : The items after conversion.
  /// * [changedCount] : The number of values that were changed.
  /// * [failedCount] : The number of values that could not be converted.
  /// * [firstFailed] : The first value that could not be converted.
  const ConvertTypeResult(
    this.items,
    this.changedCount,
    this.failedCount,
    this.firstFailed,
  );
}

/// (en) Converts the values of a key with the same rules as the
/// conversions of DeltaTraceDB.
///
/// (ja) キーの値を、DeltaTraceDB の変換と同じ規則で変換します。
class UtilConvertType {
  /// (en) Converts the value of [key] in every item to [type].
  /// Null values and items without the key are not changed.
  /// For int, double and bool, an empty string becomes null.
  ///
  /// (ja) 全ての要素の [key] の値を [type] に変換します。
  /// 値が null の要素と、キーを持たない要素は変更しません。
  /// int、double、bool では、空文字は null になります。
  ///
  /// * [items] : The items to convert.
  /// * [key] : The top-level key to convert.
  /// * [type] : The target type.
  static ConvertTypeResult convert(
    Iterable<Map<String, dynamic>> items,
    String key,
    EnumConvertType type,
  ) {
    final out = <Map<String, dynamic>>[];
    var changed = 0;
    var failed = 0;
    Object? firstFailed;
    for (final item in items) {
      final copy = Map<String, dynamic>.from(item);
      final v = item[key];
      if (v != null) {
        final (ok, nv) = _convertValue(v, type);
        if (!ok) {
          if (failed == 0) firstFailed = v;
          failed++;
        } else if (nv.runtimeType != v.runtimeType || nv != v) {
          copy[key] = nv;
          changed++;
        }
      }
      out.add(copy);
    }
    return ConvertTypeResult(out, changed, failed, firstFailed);
  }

  /// (en) Converts one value. Returns (false, null) if it cannot be converted.
  /// int uses int.parse rules (surrounding whitespace is ignored, 0x is
  /// accepted), double uses double.parse rules but rejects NaN and infinity
  /// because they cannot be saved as JSON, and bool accepts "true" / "false"
  /// in any case, as with EnumValueType.boolean_.
  ///
  /// (ja) 値を1つ変換します。変換できない場合は (false, null) を返します。
  /// int は int.parse の規則（前後の空白は無視、0x も可）、double は
  /// double.parse の規則ですが、JSON で保存できない NaN と無限大は不可とします。
  /// bool は EnumValueType.boolean_ と同じく、大文字小文字を問わず
  /// "true" / "false" を受け付けます。
  ///
  /// * [v] : A non-null value.
  /// * [type] : The target type.
  static (bool, Object?) _convertValue(Object v, EnumConvertType type) {
    if (type != EnumConvertType.string_ && v == '') return (true, null);
    switch (type) {
      case EnumConvertType.int_:
        if (v is int) return (true, v);
        final r = v is String ? int.tryParse(v) : null;
        return (r != null, r);
      case EnumConvertType.double_:
        final r = switch (v) {
          int() => v.toDouble(),
          double() => v,
          String() => double.tryParse(v),
          _ => null,
        };
        return (r != null && r.isFinite) ? (true, r) : (false, null);
      case EnumConvertType.bool_:
        if (v is bool) return (true, v);
        final s = v is String ? v.toLowerCase() : null;
        if (s == 'true' || s == 'false') return (true, s == 'true');
        return (false, null);
      case EnumConvertType.string_:
        if (v is String) return (true, v);
        if (v is num || v is bool) return (true, v.toString());
        return (false, null);
    }
  }
}
