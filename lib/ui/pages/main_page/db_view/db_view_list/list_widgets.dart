import 'dart:convert';

import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:flutter/material.dart';

/// (en) A card that shows one item as JSON, with edit and copy buttons.
///
/// (ja) 1つの要素を JSON で表示し、編集とコピーのボタンを持つカードです。
class ItemCard extends StatelessWidget {
  /// (en) The 1-based position of the item in the collection.
  ///
  /// (ja) コレクション内での要素の位置（1始まり）。
  final int itemNum;

  /// (en) The item as formatted JSON.
  ///
  /// (ja) 整形済み JSON の要素。
  final String jsonStr;

  /// (en) Called when the edit button is pressed.
  ///
  /// (ja) 編集ボタンが押されたときに呼ばれます。
  final VoidCallback onEdit;

  /// (en) Called when the copy button is pressed.
  ///
  /// (ja) コピーボタンが押されたときに呼ばれます。
  final VoidCallback onCopy;

  /// * [itemNum] : The 1-based position of the item in the collection.
  /// * [jsonStr] : The item as formatted JSON.
  /// * [onEdit] : Called when the edit button is pressed.
  /// * [onCopy] : Called when the copy button is pressed.
  const ItemCard({
    super.key,
    required this.itemNum,
    required this.jsonStr,
    required this.onEdit,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#$itemNum',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: onCopy,
                ),
              ],
            ),
            const Divider(height: 8),
            SelectableText(
              jsonStr,
              style: const TextStyle(fontFamily: 'Noto Sans Mono', fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// (en) A row of chips for the active filters, with the item count on the right.
///
/// (ja) 有効なフィルタのチップを並べ、右側に件数を表示する行です。
class ChipsRow extends StatelessWidget {
  /// (en) The chips to show.
  ///
  /// (ja) 表示するチップ。
  final List<Widget> chips;

  /// (en) The item count text, or null to hide it.
  ///
  /// (ja) 件数の文字列。表示しない場合は null。
  final String? countText;

  /// * [chips] : The chips to show.
  /// * [countText] : The item count text, or null to hide it.
  const ChipsRow({super.key, required this.chips, this.countText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: chips.isEmpty
                ? const SizedBox.shrink()
                : Wrap(spacing: 6, runSpacing: 4, children: chips),
          ),
          if (countText != null)
            Text(
              countText!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// (en) A chip for an active filter, removed with its delete button.
///
/// (ja) 有効なフィルタを表すチップで、削除ボタンで解除できます。
class ActiveChip extends StatelessWidget {
  /// (en) The label of the chip.
  ///
  /// (ja) チップのラベル。
  final String label;

  /// (en) Called when the delete button is pressed.
  ///
  /// (ja) 削除ボタンが押されたときに呼ばれます。
  final VoidCallback onDeleted;

  /// * [label] : The label of the chip.
  /// * [onDeleted] : Called when the delete button is pressed.
  const ActiveChip({super.key, required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDeleted,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// (en) Asks the user to edit an item as JSON.
///
/// (ja) 要素を JSON としてユーザーに編集してもらいます。
///
/// * [context] : The context used to show the dialog.
/// * [jsonStr] : The current item as JSON.
///
/// Returns the edited item, or null if cancelled.
Future<Map<String, dynamic>?> showEditItemDialog(
  BuildContext context,
  String jsonStr,
) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _EditItemDialog(jsonStr: jsonStr),
  );
}

/// (en) The dialog for editing an item. It owns its text controller so that
/// the controller is disposed only after the dialog is removed.
///
/// (ja) 要素を編集するダイアログです。ダイアログが取り除かれた後で破棄されるよう、
/// テキストコントローラを自身で持ちます。
class _EditItemDialog extends StatefulWidget {
  final String jsonStr;

  const _EditItemDialog({required this.jsonStr});

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.jsonStr,
  );
  String? _jsonError;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.listEditJson),
      content: SizedBox(
        width: 600,
        height: 400,
        child: TextField(
          controller: _ctrl,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            errorText: _jsonError,
          ),
          onChanged: (_) {
            if (_jsonError != null) setState(() => _jsonError = null);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            try {
              final newItem = jsonDecode(_ctrl.text) as Map<String, dynamic>;
              Navigator.pop(context, newItem);
            } catch (_) {
              setState(() => _jsonError = l10n.listInvalidJson);
            }
          },
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
