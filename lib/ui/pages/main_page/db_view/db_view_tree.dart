import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:flutter/material.dart';

class DbViewTree extends StatefulWidget {
  const DbViewTree({super.key});

  @override
  State createState() => _DbViewTreeState();
}

class _DbViewTreeState extends State<DbViewTree> {
  int _samplingNum = 3;
  int _textLength = 50;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text(l10n.treeSampling),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _samplingNum,
                  items: const [1, 3, 5]
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _samplingNum = v);
                  },
                ),
                const SizedBox(width: 16),
                Text(l10n.treeTextLength),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _textLength,
                  items: const [25, 50, 75, 100, 200]
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _textLength = v);
                  },
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: SelectableText(
              _mapToTextTree(
                localDB.raw,
                noDataLabel: l10n.noData,
                maxFieldLength: _textLength,
                maxSamplesPerDb: _samplingNum,
              ).join('\n'),
              style: const TextStyle(fontFamily: 'Noto Sans Mono'),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _mapToTextTree(
    Map<String, Collection> dbData, {
    required String noDataLabel,
    int maxFieldLength = 50,
    int maxSamplesPerDb = 1,
  }) {
    if (dbData.isEmpty) return [noDataLabel];
    final List<String> r = [];
    dbData.forEach((String collectionName, Collection collection) {
      r.add('📂 $collectionName');
      final sampleCount = (maxSamplesPerDb > 0)
          ? collection.length.clamp(0, maxSamplesPerDb)
          : collection.length;
      for (int i = 0; i < sampleCount; i++) {
        final record = collection.raw[i];
        String jsonString = jsonEncode(record);
        if (jsonString.length > maxFieldLength) {
          jsonString = '${jsonString.substring(0, maxFieldLength)}...}';
        }
        if (collection.length <= maxSamplesPerDb && i == (sampleCount - 1)) {
          r.add('   └─ #${i + 1} $jsonString');
        } else {
          r.add('   ├─ #${i + 1} $jsonString');
        }
      }
      if (collection.length > maxSamplesPerDb) {
        final remaining = collection.length - maxSamplesPerDb;
        final itemWord = remaining == 1 ? 'item' : 'items';
        r.add('   └─ ... ($remaining more $itemWord)');
      }
    });
    return r;
  }
}
