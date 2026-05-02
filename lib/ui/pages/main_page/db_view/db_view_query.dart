import 'dart:convert';

import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_with_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DbViewQuery extends StatefulWidget {
  const DbViewQuery({super.key});

  @override
  State<DbViewQuery> createState() => _DbViewQueryState();
}

class _DbViewQueryState extends State<DbViewQuery> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(child: _buildQuerySection(l10n)),
        const Divider(height: 1),
        Expanded(child: _buildResultSection(l10n)),
      ],
    );
  }

  Widget _buildQuerySection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Text(
            l10n.queryLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: queryTextController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{"type": "getAll", "target": "collection_name"}',
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: OutlinedButton(
              onPressed: () => _runQuery(l10n),
              child: Text(l10n.runQuery),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(AppLocalizations l10n) {
    return ValueListenableBuilder<String>(
      valueListenable: queryResultNotifier,
      builder: (_, result, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  Text(
                    l10n.resultLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: l10n.copyToClipboard,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: result));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.copiedToClipboard),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(result),
              ),
            ),
          ],
        );
      },
    );
  }

  void _runQuery(AppLocalizations l10n) {
    try {
      final Map<String, dynamic> jsonObj = jsonDecode(queryTextController.text);
      final result = localDB.executeQueryObject(jsonObj);
      if (selectedTarget != null) {
        if (localDB.findCollection(selectedTarget!) == null) {
          selectedTarget = null;
        }
      }
      queryResultNotifier.value =
          JsonEncoder.withIndent('  ').convert(result.toDict());
      if (result.isSuccess) {
        appliedQueries.add(QueryWithTime(jsonObj, DateTime.now().toUtc()));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isSuccess ? l10n.querySucceeded : l10n.queryFailed,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      queryResultNotifier.value = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
