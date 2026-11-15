import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/infrastructure/encryption/aes_gcm.dart';
import 'package:delta_trace_studio/infrastructure/encryption/enum_encryption_formats.dart';
import 'package:delta_trace_studio/infrastructure/file/util_export_dtdb.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/pages/main_page/csv_import_flow.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/enum_view_mode.dart';
import 'package:delta_trace_studio/ui/pages/main_page/main_page_dialogs.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:delta_trace_studio/main.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final ExportOptions _exportOptions = ExportOptions();

  EnumViewMode _currentViewMode = EnumViewMode.listView;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    final loaded = dbFileName != null;
    return Column(
      children: [
        _buildHeader(loaded),
        const Divider(height: 1),
        Expanded(
          child: loaded
              ? DbView(viewMode: _currentViewMode)
              : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildHeader(bool loaded) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _l10n.dbData,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (dbFileName != null)
                Text(
                  dbFileName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withAlpha(180),
                  ),
                ),
            ],
          ),
          if (loaded) ...[
            const SizedBox(width: 16),
            Text(_l10n.viewModeLabel),
            const SizedBox(width: 8),
            DropdownButton<EnumViewMode>(
              value: _currentViewMode,
              items: [
                DropdownMenuItem(
                  value: EnumViewMode.listView,
                  child: Text(_l10n.viewModeList),
                ),
                DropdownMenuItem(
                  value: EnumViewMode.treeView,
                  child: Text(_l10n.viewModeTree),
                ),
                DropdownMenuItem(
                  value: EnumViewMode.queryView,
                  child: Text(_l10n.viewModeQuery),
                ),
              ],
              onChanged: (EnumViewMode? mode) {
                if (mode != null) setState(() => _currentViewMode = mode);
              },
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.lock_open),
            tooltip: _l10n.decryptFile,
            onPressed: _decryptFile,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: _l10n.importDb,
            onPressed: _importDB,
          ),
          IconButton(
            icon: const Icon(Icons.table_view),
            tooltip: _l10n.importCsv,
            onPressed: _importCsv,
          ),
          if (loaded)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: _l10n.exportDb,
              onPressed: _exportDB,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storage_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
          ),
          const SizedBox(height: 16),
          Text(
            _l10n.noDbLoaded,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _l10n.importDbHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file),
            label: Text(_l10n.importDb),
            onPressed: _importDB,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.table_view),
            label: Text(_l10n.importCsv),
            onPressed: _importCsv,
          ),
        ],
      ),
    );
  }

  Future<void> _decryptFile() async {
    try {
      final XFile? file = await openFile();
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final String? hexKey = await showHEXKeyInputDialog(context);
      if (hexKey == null || !mounted) return;
      try {
        final decrypted = AesGcm().decryptJson(bytes, hexKey);
        final pretty = const JsonEncoder.withIndent('  ').convert(decrypted);
        if (!mounted) return;
        await showDecryptResultDialog(context, file.name, pretty);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _importDB() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Database files',
        extensions: ['dtdb'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final EnumEncryptionFormats? format = await showLoadFormatDialog(context);
      if (format == null) return;
      try {
        if (format == EnumEncryptionFormats.noEncryption) {
          final jsonStr = utf8.decode(bytes);
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final newDB = DeltaTraceDatabase.fromDict(data);
          setState(() {
            localDB = newDB;
            dbFileName = file.name;
            dbVersion++;
            selectedTarget =
                newDB.raw.keys.isNotEmpty ? newDB.raw.keys.first : null;
            appliedQueries.clear();
            _currentViewMode = EnumViewMode.listView;
          });
        } else if (format == EnumEncryptionFormats.aesGcm) {
          if (!mounted) return;
          final String? hexKey = await showHEXKeyInputDialog(context);
          if (hexKey != null) {
            final decrypted = AesGcm().decryptJson(bytes, hexKey);
            final newDB = DeltaTraceDatabase.fromDict(decrypted);
            setState(() {
              localDB = newDB;
              dbFileName = file.name;
              dbVersion++;
              selectedTarget =
                  newDB.raw.keys.isNotEmpty ? newDB.raw.keys.first : null;
              appliedQueries.clear();
              _currentViewMode = EnumViewMode.listView;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// (en) Imports a CSV file as a collection of the current database and
  /// shows it. If no database is open, the current empty database is used
  /// and shown as a new database.
  ///
  /// (ja) CSV ファイルを現在のデータベースのコレクションとして取り込み、表示します。
  /// データベースを開いていない場合は、現在の空のデータベースを使い、
  /// 新規データベースとして表示します。
  Future<void> _importCsv() async {
    final String? name = await importCsvFlow(context);
    if (name == null || !mounted) return;
    setState(() {
      dbFileName ??= _l10n.newDbName;
      dbVersion++;
      selectedTarget = name;
      _currentViewMode = EnumViewMode.listView;
    });
  }

  Future<void> _exportDB() async {
    try {
      if (!await showExportOptionsDialog(context, _exportOptions)) return;
      final result = _exportOptions;
      bool saved;
      if (result.useAesGcm) {
        if (!mounted) return;
        final String? hexKey = await showHEXKeyInputDialog(context);
        if (hexKey == null) return;
        saved = await UtilExportDTDB.exportDTDB(
          AesGcm().encryptJson(localDB.toDict(), hexKey).toList(),
          result.isLocalTime,
          result.useMicroseconds,
        );
      } else {
        saved = await UtilExportDTDB.exportDTDB(
          utf8.encode(jsonEncode(localDB.toDict())).toList(),
          result.isLocalTime,
          result.useMicroseconds,
        );
      }
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l10n.exportSuccess),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
