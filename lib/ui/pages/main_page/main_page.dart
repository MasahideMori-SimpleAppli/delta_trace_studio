import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/infrastructure/encryption/aes_gcm.dart';
import 'package:delta_trace_studio/infrastructure/encryption/enum_encryption_formats.dart';
import 'package:delta_trace_studio/infrastructure/file/util_export_dtdb.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/enum_view_mode.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:delta_trace_studio/main.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _isLocalTime = true;
  bool _useMicroseconds = false;
  bool _useAesGcm = false;

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
      final String? hexKey = await _showHEXKeyInputDialog();
      if (hexKey == null || !mounted) return;
      try {
        final decrypted = AesGcm().decryptJson(bytes, hexKey);
        final pretty = const JsonEncoder.withIndent('  ').convert(decrypted);
        if (!mounted) return;
        await _showDecryptResultDialog(file.name, pretty);
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

  Future<void> _showDecryptResultDialog(String fileName, String content) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_l10n.decryptResultTitle),
          content: SizedBox(
            width: 640,
            height: 480,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  fileName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        content,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Mono',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: Text(_l10n.copyToClipboard),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: content));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_l10n.copiedToClipboard),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_l10n.close),
            ),
          ],
        );
      },
    );
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
      final EnumEncryptionFormats? format = await _showLoadFormatDialog();
      if (format == null) return;
      try {
        if (format == EnumEncryptionFormats.noEncryption) {
          final jsonStr = utf8.decode(bytes);
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final newDB = DeltaTraceDatabase.fromDict(data);
          setState(() {
            localDB = newDB;
            dbFileName = file.name;
            selectedTarget =
                newDB.raw.keys.isNotEmpty ? newDB.raw.keys.first : null;
            appliedQueries.clear();
            _currentViewMode = EnumViewMode.listView;
          });
        } else if (format == EnumEncryptionFormats.aesGcm) {
          if (!mounted) return;
          final String? hexKey = await _showHEXKeyInputDialog();
          if (hexKey != null) {
            final decrypted = AesGcm().decryptJson(bytes, hexKey);
            final newDB = DeltaTraceDatabase.fromDict(decrypted);
            setState(() {
              localDB = newDB;
              dbFileName = file.name;
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

  Future<void> _exportDB() async {
    try {
      final result = await _showExportOptionsDialog();
      if (result == null) return;
      bool saved;
      if (result.useAesGcm) {
        if (!mounted) return;
        final String? hexKey = await _showHEXKeyInputDialog();
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

  Future<({bool isLocalTime, bool useMicroseconds, bool useAesGcm})?>
  _showExportOptionsDialog() {
    return showDialog<({bool isLocalTime, bool useMicroseconds, bool useAesGcm})>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(_l10n.exportDatabaseTitle),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  minWidth: 320,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_l10n.exportDatabaseDescription),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(_l10n.useLocalTime),
                      subtitle: Text(_l10n.useLocalTimeSubtitle),
                      value: _isLocalTime,
                      onChanged: (v) =>
                          setDialogState(() => _isLocalTime = v),
                    ),
                    SwitchListTile(
                      title: Text(_l10n.useMicroseconds),
                      subtitle: Text(_l10n.useMicrosecondsSubtitle),
                      value: _useMicroseconds,
                      onChanged: (v) =>
                          setDialogState(() => _useMicroseconds = v),
                    ),
                    SwitchListTile(
                      title: Text(_l10n.useAesGcm),
                      subtitle: Text(_l10n.useAesGcmSubtitle),
                      value: _useAesGcm,
                      onChanged: (v) =>
                          setDialogState(() => _useAesGcm = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: Text(_l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, (
                      isLocalTime: _isLocalTime,
                      useMicroseconds: _useMicroseconds,
                      useAesGcm: _useAesGcm,
                    ));
                  },
                  child: Text(_l10n.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<EnumEncryptionFormats?> _showLoadFormatDialog() {
    return showDialog<EnumEncryptionFormats>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text(_l10n.dialog_fileFormatTitle),
          children: [
            SimpleDialogOption(
              child: Text(_l10n.dialog_loadJson),
              onPressed: () => Navigator.pop(
                dialogContext,
                EnumEncryptionFormats.noEncryption,
              ),
            ),
            SimpleDialogOption(
              child: Text(_l10n.dialog_decryptAesGcm),
              onPressed: () => Navigator.pop(
                dialogContext,
                EnumEncryptionFormats.aesGcm,
              ),
            ),
            SimpleDialogOption(
              child: Text(_l10n.cancel),
              onPressed: () => Navigator.pop(dialogContext, null),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showHEXKeyInputDialog() {
    bool obscure = true;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? keyError;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(_l10n.dialog_aesGcmTitle),
              content: TextField(
                controller: aesGcmKeyController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: "Hex key: 32 / 48 / 64 chars (= 16 / 24 / 32 bytes)",
                  errorText: keyError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscure = !obscure),
                  ),
                ),
                onChanged: (_) {
                  if (keyError != null) {
                    setDialogState(() => keyError = null);
                  }
                },
                maxLines: 1,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: Text(_l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    final key = aesGcmKeyController.text.trim();
                    if (key.isNotEmpty &&
                        key.length != 32 &&
                        key.length != 48 &&
                        key.length != 64) {
                      setDialogState(() => keyError = _l10n.aesKeyLengthError);
                      return;
                    }
                    Navigator.pop(dialogContext, key);
                  },
                  child: Text(_l10n.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
