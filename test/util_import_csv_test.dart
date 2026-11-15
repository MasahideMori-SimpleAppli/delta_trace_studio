import 'package:delta_trace_studio/infrastructure/file/util_import_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quotes, line breaks, BOM and trailing empty lines', () {
    final items = UtilImportCsv.toItems(
      '﻿name,price,memo\r\n"Smith, J","10.50","a ""b""\nc"\r\n2,,\r\n\r\n',
    );
    expect(items, [
      {'name': 'Smith, J', 'price': '10.50', 'memo': 'a "b"\nc'},
      {'name': '2', 'price': '', 'memo': ''},
    ]);
  });

  test('errors report the line where the record starts', () {
    CsvFormatError err(String text) {
      try {
        UtilImportCsv.toItems(text);
      } on CsvFormatError catch (e) {
        return e;
      }
      fail('no error');
    }

    expect(err('a,a\n1,2').kind, EnumCsvErrorKind.header);
    expect(err('a,\n1,2').kind, EnumCsvErrorKind.header);
    final c = err('a,b\n"x\ny",1\n1');
    expect((c.kind, c.line), (EnumCsvErrorKind.columnCount, 4));
    final f = err('a,b\n"x"y,1');
    expect((f.kind, f.line), (EnumCsvErrorKind.format, 2));
    final u = err('a,b\n1,"x');
    expect((u.kind, u.line), (EnumCsvErrorKind.format, 2));
  });
}
