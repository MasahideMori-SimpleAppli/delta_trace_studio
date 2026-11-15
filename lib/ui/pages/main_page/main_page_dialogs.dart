import 'package:delta_trace_studio/infrastructure/encryption/enum_encryption_formats.dart';
import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// (en) The options for exporting a database. The export dialog changes
/// these values directly, so the choices are kept even if it is cancelled.
///
/// (ja) データベースの書き出しの設定です。書き出しダイアログがこの値を直接変更するため、
/// キャンセルしても選択内容は保持されます。
class ExportOptions {
  /// (en) Whether to use local time in the file name.
  ///
  /// (ja) ファイル名にローカル時刻を使うかどうか。
  bool isLocalTime = true;

  /// (en) Whether to include microseconds in the file name.
  ///
  /// (ja) ファイル名にマイクロ秒を含めるかどうか。
  bool useMicroseconds = false;

  /// (en) Whether to encrypt the file with AES-GCM.
  ///
  /// (ja) ファイルを AES-GCM で暗号化するかどうか。
  bool useAesGcm = false;
}

/// (en) Shows the decrypted content of a file.
///
/// (ja) ファイルを復号した内容を表示します。
///
/// * [context] : The context used to show the dialog and messages.
/// * [fileName] : The name of the decrypted file.
/// * [content] : The decrypted content.
Future<void> showDecryptResultDialog(
  BuildContext context,
  String fileName,
  String content,
) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.decryptResultTitle),
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
            label: Text(l10n.copyToClipboard),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.copiedToClipboard),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}

/// (en) Asks the user for the export options.
///
/// (ja) 書き出しの設定をユーザーに選んでもらいます。
///
/// * [context] : The context used to show the dialog.
/// * [options] : The options, changed directly by the dialog.
///
/// Returns true if the user chose OK.
Future<bool> showExportOptionsDialog(
  BuildContext context,
  ExportOptions options,
) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(l10n.exportDatabaseTitle),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, minWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.exportDatabaseDescription),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(l10n.useLocalTime),
                    subtitle: Text(l10n.useLocalTimeSubtitle),
                    value: options.isLocalTime,
                    onChanged: (v) =>
                        setDialogState(() => options.isLocalTime = v),
                  ),
                  SwitchListTile(
                    title: Text(l10n.useMicroseconds),
                    subtitle: Text(l10n.useMicrosecondsSubtitle),
                    value: options.useMicroseconds,
                    onChanged: (v) =>
                        setDialogState(() => options.useMicroseconds = v),
                  ),
                  SwitchListTile(
                    title: Text(l10n.useAesGcm),
                    subtitle: Text(l10n.useAesGcmSubtitle),
                    value: options.useAesGcm,
                    onChanged: (v) =>
                        setDialogState(() => options.useAesGcm = v),
                  ),
                ],
              ),
            ),
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
          );
        },
      );
    },
  );
  return ok ?? false;
}

/// (en) Asks the user for the format of the database file to load.
///
/// (ja) 読み込むデータベースファイルの形式をユーザーに選んでもらいます。
///
/// * [context] : The context used to show the dialog.
///
/// Returns the chosen format, or null if cancelled.
Future<EnumEncryptionFormats?> showLoadFormatDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<EnumEncryptionFormats>(
    context: context,
    builder: (dialogContext) {
      return SimpleDialog(
        title: Text(l10n.dialog_fileFormatTitle),
        children: [
          SimpleDialogOption(
            child: Text(l10n.dialog_loadJson),
            onPressed: () =>
                Navigator.pop(dialogContext, EnumEncryptionFormats.noEncryption),
          ),
          SimpleDialogOption(
            child: Text(l10n.dialog_decryptAesGcm),
            onPressed: () =>
                Navigator.pop(dialogContext, EnumEncryptionFormats.aesGcm),
          ),
          SimpleDialogOption(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(dialogContext, null),
          ),
        ],
      );
    },
  );
}

/// (en) Asks the user for an AES-GCM key in hexadecimal.
/// The input is kept in aesGcmKeyController.
///
/// (ja) AES-GCM の鍵を16進数でユーザーに入力してもらいます。
/// 入力内容は aesGcmKeyController に保持されます。
///
/// * [context] : The context used to show the dialog.
///
/// Returns the entered key (empty or 32 / 48 / 64 characters),
/// or null if cancelled.
Future<String?> showHEXKeyInputDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  bool obscure = true;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      String? keyError;
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(l10n.dialog_aesGcmTitle),
            content: TextField(
              controller: aesGcmKeyController,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: "Hex key: 32 / 48 / 64 chars (= 16 / 24 / 32 bytes)",
                errorText: keyError,
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setDialogState(() => obscure = !obscure),
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
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  final key = aesGcmKeyController.text.trim();
                  if (key.isNotEmpty &&
                      key.length != 32 &&
                      key.length != 48 &&
                      key.length != 64) {
                    setDialogState(() => keyError = l10n.aesKeyLengthError);
                    return;
                  }
                  Navigator.pop(dialogContext, key);
                },
                child: Text(l10n.ok),
              ),
            ],
          );
        },
      );
    },
  );
}
