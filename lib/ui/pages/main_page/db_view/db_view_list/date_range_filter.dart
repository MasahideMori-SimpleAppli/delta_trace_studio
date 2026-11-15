import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:flutter/material.dart';

/// (en) A filter that keeps items whose date-time value of a key is within
/// a range. This filter is applied by the editor itself, not by DeltaTraceDB.
///
/// (ja) キーの日時の値が範囲内にある要素だけを残すフィルタです。
/// DeltaTraceDB ではなく、エディタ自身が適用します。
class DateRangeFilter {
  /// (en) The key to filter by, or null.
  ///
  /// (ja) 絞り込むキー。未設定の場合は null。
  final String? key;

  /// (en) The start of the range, or null for no lower limit.
  ///
  /// (ja) 範囲の開始。下限が無い場合は null。
  final DateTime? start;

  /// (en) The end of the range, or null for no upper limit.
  ///
  /// (ja) 範囲の終了。上限が無い場合は null。
  final DateTime? end;

  /// (en) Whether the range was entered in local time.
  ///
  /// (ja) 範囲をローカル時刻で入力したかどうか。
  final bool useLocal;

  /// * [key] : The key to filter by.
  /// * [start] : The start of the range.
  /// * [end] : The end of the range.
  /// * [useLocal] : Whether the range was entered in local time.
  const DateRangeFilter({this.key, this.start, this.end, this.useLocal = false});

  /// (en) Whether the filter is set.
  ///
  /// (ja) フィルタが設定されているかどうか。
  bool get isActive =>
      key != null && key!.isNotEmpty && (start != null || end != null);

  /// (en) Returns true if [item] passes the filter.
  /// Items without a parsable date-time do not pass an active filter.
  ///
  /// (ja) [item] がフィルタを通過する場合は true を返します。
  /// フィルタが有効なとき、日時として解析できない要素は通過しません。
  ///
  /// * [item] : The item to check.
  bool matches(Map<String, dynamic> item) {
    if (!isActive) return true;
    final val = item[key!];
    if (val == null) return false;
    final dt = DateTime.tryParse(val.toString());
    if (dt == null) return false;
    if (start != null && dt.isBefore(start!)) return false;
    if (end != null && dt.isAfter(end!)) return false;
    return true;
  }
}

/// (en) Asks the user for a date range filter.
///
/// (ja) 日付範囲フィルタをユーザーに設定してもらいます。
///
/// * [context] : The context used to show the dialog.
/// * [keys] : The keys that can be chosen.
/// * [initial] : The current filter.
///
/// Returns the new filter (one without a key when cleared),
/// or null if cancelled.
Future<DateRangeFilter?> showDateRangeFilterDialog(
  BuildContext context, {
  required List<String> keys,
  required DateRangeFilter initial,
}) {
  final l10n = AppLocalizations.of(context)!;
  String key = initial.key ?? '';
  DateTime? start = initial.start;
  DateTime? end = initial.end;
  bool useLocal = initial.useLocal;

  return showDialog<DateRangeFilter>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(l10n.dateFilterTitle),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.dateFilterKey,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: keys.contains(key) ? key : null,
                        hint: Text(l10n.dateFilterKeyHint),
                        isExpanded: true,
                        isDense: true,
                        items: keys
                            .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => key = v);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.dateFilterUseLocalTime,
                      style: const TextStyle(fontSize: 13),
                    ),
                    value: useLocal,
                    onChanged: (v) => setDialogState(() {
                      useLocal = v ?? false;
                      start = null;
                      end = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  _DateTimeRow(
                    label: l10n.dateFilterStart,
                    value: start,
                    onPick: () async {
                      final dt = await _pickDateTime(context, start, useLocal);
                      if (dt != null) setDialogState(() => start = dt);
                    },
                    onClear: () => setDialogState(() => start = null),
                  ),
                  const SizedBox(height: 12),
                  _DateTimeRow(
                    label: l10n.dateFilterEnd,
                    value: end,
                    onPick: () async {
                      final dt = await _pickDateTime(context, end, useLocal);
                      if (dt != null) setDialogState(() => end = dt);
                    },
                    onClear: () => setDialogState(() => end = null),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  DateRangeFilter(useLocal: useLocal),
                ),
                child: Text(l10n.dateFilterClear),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: (key.isNotEmpty && (start != null || end != null))
                    ? () => Navigator.pop(
                        dialogContext,
                        DateRangeFilter(
                          key: key,
                          start: start,
                          end: end,
                          useLocal: useLocal,
                        ),
                      )
                    : null,
                child: Text(l10n.ok),
              ),
            ],
          );
        },
      );
    },
  );
}

/// (en) Asks the user for a date and a time.
///
/// (ja) 日付と時刻をユーザーに選んでもらいます。
///
/// * [context] : The context used to show the pickers.
/// * [initial] : The initial date-time, or null for now.
/// * [useLocal] : If true, returns a local date-time; otherwise UTC.
///
/// Returns the chosen date-time, or null if cancelled.
Future<DateTime?> _pickDateTime(
  BuildContext context,
  DateTime? initial,
  bool useLocal,
) async {
  final now = DateTime.now();
  final initialLocal = initial?.toLocal();
  final date = await showDatePicker(
    context: context,
    initialDate: initialLocal ?? now,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (date == null) return null;
  if (!context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: initialLocal != null
        ? TimeOfDay.fromDateTime(initialLocal)
        : TimeOfDay(hour: now.hour, minute: now.minute),
  );
  if (time == null) return null;
  if (useLocal) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  } else {
    return DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);
  }
}

/// (en) A row that shows a date-time with buttons to pick and clear it.
///
/// (ja) 日時を表示し、選択とクリアのボタンを持つ行です。
class _DateTimeRow extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  String _format(AppLocalizations l10n, DateTime? dt) {
    if (dt == null) return l10n.dateFilterNotSet;
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              alignment: Alignment.centerLeft,
            ),
            onPressed: onPick,
            child: Text(
              _format(l10n, value),
              style: const TextStyle(fontFamily: 'Noto Sans Mono', fontSize: 13),
            ),
          ),
        ),
        if (value != null)
          IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: onClear)
        else
          const SizedBox(width: 40),
      ],
    );
  }
}
