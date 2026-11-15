import 'package:delta_trace_studio/application/util_convert_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<Object?> values(ConvertTypeResult r) =>
      r.items.map((e) => e['v']).toList();

  test('int: whitespace, 0x and empty string; double values fail', () {
    final items = [
      {'v': ' 7 '},
      {'v': '0x10'},
      {'v': ''},
      {'v': null},
      {'w': 1},
      {'v': 3},
    ];
    final r = UtilConvertType.convert(items, 'v', EnumConvertType.int_);
    expect((r.failedCount, r.changedCount), (0, 3));
    expect(values(r), [7, 16, null, null, null, 3]);
    expect(items.first['v'], ' 7 ');
    final f = UtilConvertType.convert(
      [
        {'v': '1'},
        {'v': 1.5},
        {'v': '2.0'},
      ],
      'v',
      EnumConvertType.int_,
    );
    expect((f.failedCount, f.firstFailed), (2, 1.5));
  });

  test('double rejects NaN and Infinity, bool ignores case, string', () {
    expect(
      UtilConvertType.convert(
        [
          {'v': 'NaN'},
        ],
        'v',
        EnumConvertType.double_,
      ).failedCount,
      1,
    );
    expect(
      UtilConvertType.convert(
        [
          {'v': 'Infinity'},
        ],
        'v',
        EnumConvertType.double_,
      ).failedCount,
      1,
    );
    expect(
      values(
        UtilConvertType.convert(
          [
            {'v': '1e3'},
            {'v': 2},
          ],
          'v',
          EnumConvertType.double_,
        ),
      ),
      [1000.0, 2.0],
    );
    expect(
      values(
        UtilConvertType.convert(
          [
            {'v': 'TRUE'},
            {'v': 'false'},
          ],
          'v',
          EnumConvertType.bool_,
        ),
      ),
      [true, false],
    );
    expect(
      UtilConvertType.convert(
        [
          {'v': 'yes'},
          {'v': 1},
        ],
        'v',
        EnumConvertType.bool_,
      ).failedCount,
      2,
    );
    final s = UtilConvertType.convert(
      [
        {'v': 1.5},
        {'v': true},
        {'v': ''},
      ],
      'v',
      EnumConvertType.string_,
    );
    expect(values(s), ['1.5', 'true', '']);
    expect(s.changedCount, 2);
    expect(
      UtilConvertType.convert(
        [
          {
            'v': [1],
          },
        ],
        'v',
        EnumConvertType.string_,
      ).failedCount,
      1,
    );
  });
}
