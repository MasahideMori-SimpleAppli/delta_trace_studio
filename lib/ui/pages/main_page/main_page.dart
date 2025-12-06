import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/infrastructure/encryption/aes_gcm.dart';
import 'package:delta_trace_studio/infrastructure/encryption/enum_encryption_formats.dart';
import 'package:delta_trace_studio/infrastructure/file/util_export_dtdb.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/view_mode.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/enum_view_mode.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_with_time.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_locale/simple_locale.dart';
import 'package:simple_managers/simple_managers.dart';
import 'package:simple_widget_markup/simple_widget_markup.dart';

import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/ui/pages/main_page/enum_db_collection.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // The manager class for SpWML.
  final StateManager _sm = StateManager();

  final _tecJSON = TextEditingController(text: "");
  final _tecAesGcmKey = TextEditingController();

  // DBの出力名のフォーマットスイッチ関係
  bool isLocalTime = true; // default
  bool useMicroseconds = false; // default
  bool useAesGcm = false; // default (平文JSONが基準)

  // result code.
  String _resultStr = "Empty.";

  @override
  void initState() {
    super.initState();
    _sm.tsm.setSelection("queryMode", "Json");
  }

  @override
  void dispose() {
    _sm.dispose();
    _tecJSON.dispose();
    _tecAesGcmKey.dispose();
    super.dispose();
  }

  String? _getLayout(BuildContext context) {
    final String lang = LocaleManager.of(context)?.getLanguageCode() ?? "en";
    // page name
    const String pageName = "main_page";
    const String windowClass = "any";
    // loading SpWML file name
    const String fileName = "main_page";
    final String path =
        "assets/layout/$lang/$pageName/$windowClass/$fileName.spwml";
    return SpWMLLayoutManager().getAssets(
      path,
      () {
        if (mounted) {
          setState(() {});
        }
      },
      (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("SpWMLLoadingError"),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Widget _wrap(Widget w) {
    return Scaffold(body: SafeArea(child: w));
  }

  @override
  Widget build(BuildContext context) {
    final layout = _getLayout(context);
    if (layout == null) {
      return _wrap(const Center(child: CircularProgressIndicator()));
    } else {
      SpWMLBuilder b = SpWMLBuilder(layout, padding: EdgeInsets.zero);
      // Various manager classes are automatically configured using the SID set in SpWML.
      b.setStateManager(_sm);
      _initViewAndCallbacks(b);
      return _wrap(b.build(context));
    }
  }

  /// create query widgets.
  Widget _createQWidgets() {
    // now JSON only.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Text(AppLocalizations.of(context)!.enterQueryCode),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(controller: _tecJSON, maxLines: null),
            ),
          ),
        ),
      ],
    );
  }

  /// This is where you set up view initialization, button callbacks, etc.
  void _initViewAndCallbacks(SpWMLBuilder b) {
    // query view
    b.replace("queryView", _createQWidgets());

    // run query button
    BtnElement btn3 = b.getElement("runQuery") as BtnElement;
    btn3.setCallback(() {
      // Json
      final Map<String, dynamic> jsonObj = jsonDecode(_tecJSON.text);
      setState(() {
        try {
          final result = localDB.executeQueryObject(jsonObj);
          // 存在しないコレクションを参照しようとした場合は参照をnullにリセットする。
          if(selectedTarget!=null){
            if(localDB.findCollection(selectedTarget!) == null){
              selectedTarget = null;
            }
          }
          _resultStr = JsonEncoder.withIndent('  ').convert(result.toDict());
          if (result.isSuccess) {
            appliedQueries.add(QueryWithTime(jsonObj, DateTime.now().toUtc()));
          }
        } catch (e) {
          _resultStr = e.toString();
        }
      });
    });

    // left bottom
    BtnElement btn5 = b.getElement("resultCopy") as BtnElement;
    btn5.setCallback(() async {
      await _setToClipboard(_resultStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Copied to clipboard."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
    TextElement elm2 = b.getElement("queryResult") as TextElement;
    elm2.setContentText(_resultStr);

    // right top
    BtnElement importDB = b.getElement("importDB") as BtnElement;
    importDB.setCallback(() async {
      try {
        const XTypeGroup typeGroup = XTypeGroup(
          label: 'Database files',
          extensions: ['dtdb'],
        );
        final XFile? result = await openFile(acceptedTypeGroups: [typeGroup]);
        // キャンセル時用。
        if (result == null) {
          return;
        }
        final bytes = await result.readAsBytes();
        // ダイアログで選択してもらう
        if (mounted) {
          final EnumEncryptionFormats? format = await showLoadFormatDialog(
            context,
          );
          if (format == null) {
            return;
          }
          try {
            if (format == EnumEncryptionFormats.noEncryption) {
              final jsonStr = utf8.decode(bytes);
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              setState(() {
                selectedTarget = null;
                localDB = DeltaTraceDatabase.fromDict(data);
                appliedQueries.clear();
              });
            } else if (format == EnumEncryptionFormats.aesGcm) {
              if (mounted) {
                final String? hexKey = await showHEXKeyInputDialog(context);
                if (hexKey != null) {
                  final decrypted = AesGcm().decryptJson(bytes, hexKey);
                  setState(() {
                    selectedTarget = null;
                    localDB = DeltaTraceDatabase.fromDict(decrypted);
                    appliedQueries.clear();
                  });
                }
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Error: $e")));
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
    BtnElement exportDB = b.getElement("exportDB") as BtnElement;
    exportDB.setCallback(() async {
      try {
        final result = await showExportOptionsDialog(context);
        if (result == null) return; // canceled
        // AES-GCM を使う場合はキー入力ダイアログへ
        if (result.useAesGcm) {
          if (mounted) {
            final String? hexKey = await showHEXKeyInputDialog(context);
            if (hexKey == null) return; // キャンセル
            await UtilExportDTDB.exportDTDB(
              AesGcm().encryptJson(localDB.toDict(), hexKey).toList(),
              result.isLocalTime,
              result.useMicroseconds,
            );
          }
        } else {
          await UtilExportDTDB.exportDTDB(
            utf8.encode(jsonEncode(localDB.toDict())).toList(),
            result.isLocalTime,
            result.useMicroseconds,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });

    DropdownBtnElement dropDownBtn3 =
        b.getElement("viewMode") as DropdownBtnElement;
    dropDownBtn3.setCallback((int selectedIndex) {
      stateDB.executeQuery(
        QueryBuilder.clearAdd(
          target: EnumDbCollection.dbViewMode.name,
          addData: [ViewMode(EnumViewMode.values.elementAt(selectedIndex))],
        ).build(),
      );
    });

    // right bottom
    b.replace("dbView", DbView());
  }

  Future<({bool isLocalTime, bool useMicroseconds, bool useAesGcm})?>
  showExportOptionsDialog(BuildContext context) {
    return showDialog<
      ({bool isLocalTime, bool useMicroseconds, bool useAesGcm})
    >(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.exportDatabaseTitle),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600, minWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.exportDatabaseDescription,
                    ),

                    const SizedBox(height: 16),

                    // ---- Switch 1: Local time? ----
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.useLocalTime),
                      subtitle: Text(
                        AppLocalizations.of(context)!.useLocalTimeSubtitle,
                      ),
                      value: isLocalTime,
                      onChanged: (v) {
                        setState(() => isLocalTime = v);
                      },
                    ),

                    // ---- Switch 2: Microseconds? ----
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)!.useMicroseconds,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.useMicrosecondsSubtitle,
                      ),
                      value: useMicroseconds,
                      onChanged: (v) {
                        setState(() => useMicroseconds = v);
                      },
                    ),

                    // ---- Switch 3: AES-GCM encryption? ----
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.useAesGcm),
                      subtitle: Text(
                        AppLocalizations.of(context)!.useAesGcmSubtitle,
                      ),
                      value: useAesGcm,
                      onChanged: (v) {
                        setState(() => useAesGcm = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, (
                      isLocalTime: isLocalTime,
                      useMicroseconds: useMicroseconds,
                      useAesGcm: useAesGcm,
                    ));
                  },
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<EnumEncryptionFormats?> showLoadFormatDialog(
    BuildContext context,
  ) async {
    return showDialog<EnumEncryptionFormats>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(AppLocalizations.of(context)!.dialog_fileFormatTitle),
          children: [
            SimpleDialogOption(
              child: Text(AppLocalizations.of(context)!.dialog_loadJson),
              onPressed: () =>
                  Navigator.pop(context, EnumEncryptionFormats.noEncryption),
            ),
            SimpleDialogOption(
              child: Text(AppLocalizations.of(context)!.dialog_decryptAesGcm),
              onPressed: () =>
                  Navigator.pop(context, EnumEncryptionFormats.aesGcm),
            ),
            SimpleDialogOption(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.pop(context, null),
            ),
          ],
        );
      },
    );
  }

  Future<String?> showHEXKeyInputDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.dialog_aesGcmTitle),
          content: TextField(
            controller: _tecAesGcmKey,
            decoration: InputDecoration(
              labelText: "Hex key (16 / 24 / 32 bytes)",
            ),
            maxLines: 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _tecAesGcmKey.text.trim()),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
