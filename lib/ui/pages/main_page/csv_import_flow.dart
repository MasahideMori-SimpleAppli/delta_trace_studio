import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_with_time.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

/// (en) Lets the user pick a CSV file and adds it to the current database
/// as a collection with the addCsv query of DeltaTraceDB. Each row becomes
/// an item of {header: cell text}. The CSV is checked with UtilCsv first,
/// so that errors can be shown in the user's language.
/// If the collection already exists, its contents are replaced with the
/// clearAddCsv query after confirmation. The query, which contains the CSV
/// text, is recorded in the applied query history.
///
/// (ja) ユーザーが選んだ CSV ファイルを、現在のデータベースにコレクションとして
/// DeltaTraceDB の addCsv クエリで追加します。各行は {ヘッダー: セルの文字列} の
/// 要素になります。エラーを利用者の言語で表示できるように、先に UtilCsv で
/// CSV を検査します。
/// 同名のコレクションがある場合は、確認のうえで clearAddCsv クエリで
/// 内容を置き換えます。実行したクエリ（CSV の文字列を含む）は、
/// 適用済みクエリの履歴に記録します。
///
/// * [context] : The context used to show dialogs and messages.
///
/// Returns the name of the imported collection, or null if nothing was imported.
Future<String?> importCsvFlow(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
    );
  }

  const XTypeGroup typeGroup = XTypeGroup(label: 'CSV', extensions: ['csv']);
  final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
  if (file == null || !context.mounted) return null;
  final String text;
  final List<Map<String, dynamic>> items;
  try {
    try {
      text = utf8.decode(await file.readAsBytes());
    } on FormatException {
      if (context.mounted) showMessage(l10n.csvEncodingError);
      return null;
    }
    items = UtilCsv.toItems(text);
  } on CsvFormatError catch (e) {
    if (context.mounted) showMessage(_csvErrorText(l10n, e));
    return null;
  } catch (e) {
    if (context.mounted) showMessage('Error: $e');
    return null;
  }
  if (!context.mounted) return null;
  final defaultName = file.name.replaceFirst(
    RegExp(r'\.csv$', caseSensitive: false),
    '',
  );
  final String? name = await _showCollectionNameDialog(
    context,
    l10n,
    defaultName,
  );
  if (name == null || !context.mounted) return null;
  final exists = localDB.findCollection(name) != null;
  if (exists && !await _confirmReplace(context, l10n, name)) return null;

  final now = DateTime.now().toUtc();
  final cause = Cause(
    who: Actor(EnumActorType.system, "DeltaTraceStudio"),
    when: TemporalTrace(
      nodes: [TimestampNode(timestamp: now, location: "DeltaTraceStudio App")],
    ),
    what: "Importing a CSV file is performed through user UI actions.",
    why: "Run CSV import function.",
    from: "DeltaTraceStudio App",
  );
  final Query q = exists
      ? QueryBuilder.clearAddCsv(
          target: name,
          csvText: text,
          cause: cause,
        ).build()
      : QueryBuilder.addCsv(target: name, csvText: text, cause: cause).build();
  final r = localDB.executeQuery(q);
  if (!r.isSuccess) {
    if (context.mounted) showMessage(l10n.listOperationFailed);
    return null;
  }
  appliedQueries.add(QueryWithTime(q.toDict(), now));
  if (context.mounted) {
    showMessage(l10n.csvImportSuccess(items.length, name));
  }
  return name;
}

/// (en) Returns the message for a CSV error.
///
/// (ja) CSV のエラーに対応するメッセージを返します。
///
/// * [l10n] : The localizations.
/// * [e] : The CSV error.
String _csvErrorText(AppLocalizations l10n, CsvFormatError e) {
  switch (e.kind) {
    case EnumCsvErrorKind.header:
      return l10n.csvHeaderError;
    case EnumCsvErrorKind.columnCount:
      return l10n.csvColumnCountError(e.line);
    case EnumCsvErrorKind.format:
      return l10n.csvFormatError(e.line);
  }
}

/// (en) Asks the user for the target collection name.
///
/// (ja) 取り込み先のコレクション名をユーザーに入力してもらいます。
///
/// * [context] : The context used to show the dialog.
/// * [l10n] : The localizations.
/// * [initial] : The initial name.
///
/// Returns the entered name, or null if cancelled.
Future<String?> _showCollectionNameDialog(
  BuildContext context,
  AppLocalizations l10n,
  String initial,
) {
  String name = initial;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(l10n.csvCollectionNameTitle),
        content: TextFormField(
          initialValue: initial,
          autofocus: true,
          onChanged: (v) => setState(() => name = v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: name.isEmpty
                ? null
                : () => Navigator.pop(dialogContext, name),
            child: Text(l10n.ok),
          ),
        ],
      ),
    ),
  );
}

/// (en) Asks the user whether to replace an existing collection.
///
/// (ja) 既存のコレクションを置き換えるかをユーザーに確認します。
///
/// * [context] : The context used to show the dialog.
/// * [l10n] : The localizations.
/// * [name] : The collection name.
///
/// Returns true if the user chose to replace it.
Future<bool> _confirmReplace(
  BuildContext context,
  AppLocalizations l10n,
  String name,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(l10n.csvConfirmReplace(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
  return ok ?? false;
}
