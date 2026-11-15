import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/application/util_convert_type.dart';
import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_with_time.dart';
import 'package:flutter/material.dart';

/// (en) Lets the user choose a key and a type, and converts the values of
/// that key in the selected collection. If any value cannot be converted,
/// nothing is changed. The query is recorded in the applied query history.
///
/// (ja) ユーザーが選んだキーの値を、選択中のコレクション全体で指定の型に変換します。
/// 変換できない値が1つでもあれば、何も変更しません。
/// 実行したクエリは適用済みクエリの履歴に記録します。
///
/// * [context] : The context used to show dialogs and messages.
/// * [target] : The selected collection name.
/// * [keys] : The keys that can be chosen, in display order.
///
/// Returns true if the collection was changed.
Future<bool> convertTypeFlow(
  BuildContext context,
  String target,
  List<String> keys,
) async {
  final l10n = AppLocalizations.of(context)!;
  final choice = await _showConvertTypeDialog(context, l10n, keys);
  if (choice == null || !context.mounted) return false;
  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
    );
  }

  final res = UtilConvertType.convert(
    localDB.collection(target).raw,
    choice.key,
    choice.type,
  );
  if (res.failedCount > 0) {
    showMessage(
      l10n.convertTypeFailed(res.failedCount, res.firstFailed.toString()),
    );
    return false;
  }
  if (res.changedCount == 0) {
    showMessage(l10n.convertTypeSuccess(0));
    return false;
  }
  final now = DateTime.now().toUtc();
  final Query q = RawQueryBuilder.clearAdd(
    target: target,
    rawAddData: res.items,
    cause: Cause(
      who: Actor(EnumActorType.system, "DeltaTraceStudio"),
      when: TemporalTrace(
        nodes: [TimestampNode(timestamp: now, location: "DeltaTraceStudio App")],
      ),
      what: "Converting the type of key '${choice.key}' to "
          "${choice.type.name} is performed through user UI actions.",
      why: "Run convert key type function.",
      from: "DeltaTraceStudio App",
    ),
  ).build();
  final r = localDB.executeQuery(q);
  if (!r.isSuccess) {
    showMessage(l10n.listOperationFailed);
    return false;
  }
  appliedQueries.add(QueryWithTime(q.toDict(), now));
  showMessage(l10n.convertTypeSuccess(res.changedCount));
  return true;
}

/// (en) Asks the user for the key and the target type.
///
/// (ja) 変換するキーと変換後の型をユーザーに選んでもらいます。
///
/// * [context] : The context used to show the dialog.
/// * [l10n] : The localizations.
/// * [keys] : The keys that can be chosen.
///
/// Returns the choice, or null if cancelled.
Future<({String key, EnumConvertType type})?> _showConvertTypeDialog(
  BuildContext context,
  AppLocalizations l10n,
  List<String> keys,
) {
  String? key;
  var type = EnumConvertType.int_;
  const labels = {
    EnumConvertType.int_: 'int',
    EnumConvertType.double_: 'double',
    EnumConvertType.bool_: 'bool',
    EnumConvertType.string_: 'String',
  };
  return showDialog<({String key, EnumConvertType type})>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(l10n.listConvertType),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: key,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.filterKeyLabel),
                items: keys
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) => setState(() => key = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EnumConvertType>(
                initialValue: type,
                decoration: InputDecoration(labelText: l10n.convertTypeTarget),
                items: labels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => type = v);
                },
              ),
              const SizedBox(height: 16),
              Text(l10n.convertTypeNote),
              if (type != EnumConvertType.string_) ...[
                const SizedBox(height: 8),
                Text(l10n.convertTypeEmptyNote),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: key == null
                ? null
                : () => Navigator.pop(dialogContext, (key: key!, type: type)),
            child: Text(l10n.ok),
          ),
        ],
      ),
    ),
  );
}
