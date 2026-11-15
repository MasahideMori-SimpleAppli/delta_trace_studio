/// (en) The kind of error found while reading a CSV file.
///
/// (ja) CSV ファイルの読み込みで見つかったエラーの種類です。
enum EnumCsvErrorKind {
  /// (en) The header has an empty or duplicate column name.
  ///
  /// (ja) ヘッダーに空の列名または重複した列名がある。
  header,

  /// (en) A row has a different number of columns from the header.
  ///
  /// (ja) 列数がヘッダーと一致しない行がある。
  columnCount,

  /// (en) A quoted value is not closed, or a character follows a closing quote.
  ///
  /// (ja) 引用符で囲んだ値が閉じていない、または閉じた引用符の後に文字がある。
  format,
}

/// (en) An error found while reading a CSV file.
///
/// (ja) CSV ファイルの読み込みで見つかったエラーです。
class CsvFormatError implements Exception {
  /// (en) The kind of error.
  ///
  /// (ja) エラーの種類。
  final EnumCsvErrorKind kind;

  /// (en) The line number (1-based) where the record with the error starts.
  /// 0 for header errors.
  ///
  /// (ja) エラーのあるレコードが始まる行番号（1始まり）。ヘッダーのエラーでは 0。
  final int line;

  /// * [kind] : The kind of error.
  /// * [line] : The line number where the record with the error starts.
  CsvFormatError(this.kind, this.line);

  @override
  String toString() => 'CsvFormatError(${kind.name}, line $line)';
}

/// (en) Reads CSV text into items for DeltaTraceDB.
///
/// (ja) CSV のテキストを DeltaTraceDB の要素に変換します。
class UtilImportCsv {
  /// (en) Converts CSV text to a list of maps.
  /// The first record is the header, and each following record becomes
  /// a map of {column name: cell text}. All values are kept as strings.
  /// Values are separated by commas, may be enclosed in double quotes
  /// (`""` inside quotes is a quote, and quoted values may contain line breaks),
  /// and lines end with LF, CRLF or CR. A leading BOM and trailing empty lines
  /// are ignored.
  ///
  /// (ja) CSV のテキストを Map のリストに変換します。
  /// 最初のレコードをヘッダーとし、以降の各レコードを {列名: セルの文字列} の
  /// Map にします。値は全て文字列のままです。
  /// 値はカンマ区切りで、ダブルクォートで囲めます（囲んだ中の `""` は引用符1つで、
  /// 改行も含められます）。行末は LF、CRLF、CR のいずれかです。
  /// 先頭の BOM と末尾の空行は無視します。
  ///
  /// * [text] : The CSV text.
  ///
  /// Throws [CsvFormatError] if the CSV is invalid.
  static List<Map<String, dynamic>> toItems(String text) {
    final records = _parse(text.startsWith('﻿') ? text.substring(1) : text);
    while (records.isNotEmpty &&
        records.last.$2.length == 1 &&
        records.last.$2.first.isEmpty) {
      records.removeLast();
    }
    if (records.isEmpty) return [];
    final header = records.first.$2;
    if (header.any((e) => e.isEmpty) || header.toSet().length != header.length) {
      throw CsvFormatError(EnumCsvErrorKind.header, 0);
    }
    final items = <Map<String, dynamic>>[];
    for (final (line, cells) in records.skip(1)) {
      if (cells.length != header.length) {
        throw CsvFormatError(EnumCsvErrorKind.columnCount, line);
      }
      items.add({for (var i = 0; i < header.length; i++) header[i]: cells[i]});
    }
    return items;
  }

  /// (en) Splits CSV text into records of cells,
  /// each with the line number where it starts.
  ///
  /// (ja) CSV のテキストを、開始行番号付きのセルのレコードに分割します。
  ///
  /// * [text] : The CSV text without a BOM.
  static List<(int, List<String>)> _parse(String text) {
    final records = <(int, List<String>)>[];
    var cells = <String>[];
    final cell = StringBuffer();
    var line = 1;
    var recordLine = 1;
    var inQuotes = false;
    var afterQuote = false;
    var i = 0;
    void endRecord() {
      cells.add(cell.toString());
      cell.clear();
      records.add((recordLine, cells));
      cells = <String>[];
      afterQuote = false;
    }

    while (i < text.length) {
      final c = text[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            inQuotes = false;
            afterQuote = true;
          }
        } else {
          if (c == '\n' || (c == '\r' && !_isCrLf(text, i))) line++;
          cell.write(c);
        }
      } else if (c == ',') {
        cells.add(cell.toString());
        cell.clear();
        afterQuote = false;
      } else if (c == '\r' || c == '\n') {
        if (_isCrLf(text, i)) i++;
        endRecord();
        line++;
        recordLine = line;
      } else if (afterQuote) {
        throw CsvFormatError(EnumCsvErrorKind.format, recordLine);
      } else if (c == '"' && cell.isEmpty) {
        inQuotes = true;
      } else {
        cell.write(c);
      }
      i++;
    }
    if (inQuotes) throw CsvFormatError(EnumCsvErrorKind.format, recordLine);
    if (cells.isNotEmpty || cell.isNotEmpty || afterQuote) endRecord();
    return records;
  }

  /// (en) Returns true if [text] has CRLF at [i].
  ///
  /// (ja) [text] の [i] の位置が CRLF なら true を返します。
  static bool _isCrLf(String text, int i) =>
      text[i] == '\r' && i + 1 < text.length && text[i + 1] == '\n';
}
