import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/merge_dialog.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_with_time.dart';
import 'package:flutter/material.dart';

/// (en) Returns the Cause recorded for an operation made in the editor.
///
/// (ja) エディタで行った操作に記録する Cause を返します。
///
/// * [now] : The time of the operation in UTC.
/// * [what] : What was done.
/// * [why] : Why it was done.
Cause _uiCause(DateTime now, String what, String why) => Cause(
  who: Actor(EnumActorType.system, "DeltaTraceStudio"),
  when: TemporalTrace(
    nodes: [TimestampNode(timestamp: now, location: "DeltaTraceStudio App")],
  ),
  what: what,
  why: why,
  from: "DeltaTraceStudio App",
);

/// (en) Shows a failure message.
///
/// (ja) 失敗のメッセージを表示します。
///
/// * [context] : The context used to show the message.
void _showFailed(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context)!.listOperationFailed),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// (en) Lets the user set the merge parameters and merges collections.
/// The query is recorded in the applied query history.
///
/// (ja) ユーザーにマージの設定をしてもらい、コレクションをマージします。
/// 実行したクエリは適用済みクエリの履歴に記録します。
///
/// * [context] : The context used to show dialogs and messages.
/// * [target] : The selected collection name, or null.
///
/// Returns the output collection name, or null if nothing was merged.
Future<String?> mergeFlow(BuildContext context, String? target) async {
  final source = [...localDB.raw.keys].where((x) => x != target);
  final MergeQueryParams? mqp = await showMergeQueryParamsDialog(
    context,
    initial: MergeQueryParams(
      base: target ?? "",
      source: source.toList(),
      relationKey: "",
      sourceKeys: [],
      output: "output_collection_name",
      dslTmp: {},
      serialBase: target,
    ),
  );
  if (mqp == null) return null;
  final now = DateTime.now().toUtc();
  final Query mergeQuery = RawQueryBuilder.merge(
    mergeQueryParams: mqp,
    cause: _uiCause(
      now,
      "Merging collections is performed through user UI actions.",
      "Run merge function.",
    ),
  ).build();
  final r = localDB.executeQuery(mergeQuery);
  if (!r.isSuccess) {
    if (context.mounted) _showFailed(context);
    return null;
  }
  appliedQueries.add(QueryWithTime(mergeQuery.toDict(), now));
  return mqp.output;
}

/// (en) Asks for confirmation and removes a collection.
/// The query is recorded in the applied query history.
///
/// (ja) 確認のうえでコレクションを削除します。
/// 実行したクエリは適用済みクエリの履歴に記録します。
///
/// * [context] : The context used to show dialogs and messages.
/// * [target] : The collection to remove.
///
/// Returns true if the collection was removed.
Future<bool> removeCollectionFlow(BuildContext context, String target) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(l10n.listConfirmTitle),
        content: Text(l10n.listConfirmRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.yes),
          ),
        ],
      );
    },
  );
  if (ok != true) return false;
  final now = DateTime.now().toUtc();
  final removeQuery = RawQueryBuilder.removeCollection(
    target: target,
    cause: _uiCause(
      now,
      "removeCollections is performed through user UI actions.",
      "Run removeCollection function.",
    ),
  ).build();
  final r = localDB.executeQuery(removeQuery);
  if (!r.isSuccess) {
    if (context.mounted) _showFailed(context);
    return false;
  }
  appliedQueries.add(QueryWithTime(removeQuery.toDict(), now));
  return true;
}
