import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:flutter/material.dart';

class QueryWidget extends StatefulWidget {
  final int index;
  final Query query;
  final void Function(int index, Query? newQuery) onChanged;

  const QueryWidget({
    required this.index,
    required this.query,
    required this.onChanged,
    super.key,
  });

  @override
  State<QueryWidget> createState() => _QueryWidgetState();
}

class _QueryWidgetState extends State<QueryWidget> {
  final _tecTarget = TextEditingController(text: "");
  EnumQueryType _qType = EnumQueryType.add;

  @override
  void initState() {
    super.initState();
    _qType = widget.query.type;
  }

  @override
  void dispose() {
    _tecTarget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Target 入力
            SizedBox(
              width: 120,
              child: TextField(
                decoration: InputDecoration(labelText: "Target"),
                controller: _tecTarget,
              ),
            ),

            // QueryType 選択
            SizedBox(width: 12),
            DropdownButton<EnumQueryType>(
              value: _qType,
              items: EnumQueryType.values.map((qt) {
                return DropdownMenuItem(value: qt, child: Text(qt.name));
              }).toList(),
              onChanged: (qt) {
                if (qt != null) {
                  setState(() => _qType = qt);
                }
              },
            ),

            // QueryType に応じた追加フィールド
            Expanded(child: _buildExtraFields()),

            // 削除ボタン
            IconButton(
              onPressed: () {
                widget.onChanged(widget.index, null);
              },
              icon: Icon(Icons.delete_outline_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraFields() {
    return Container();
    // switch (_qType) {
    //   case QueryType.text:
    //     return CheckboxListTile(
    //       title: Text("部分一致"),
    //       value: widget.query.extra ?? false,
    //       onChanged: (val) {
    //         widget.onChanged(widget.query..extra = val);
    //       },
    //     );
    //   case QueryType.number:
    //     return Row(
    //       children: [
    //         Expanded(
    //           child: TextField(decoration: InputDecoration(labelText: "最小値")),
    //         ),
    //         SizedBox(width: 8),
    //         Expanded(
    //           child: TextField(decoration: InputDecoration(labelText: "最大値")),
    //         ),
    //       ],
    //     );
    //   case QueryType.date:
    //     return ElevatedButton(
    //       child: Text("日付を選択"),
    //       onPressed: () async {
    //         final picked = await showDatePicker(
    //           context: context,
    //           firstDate: DateTime(2000),
    //           lastDate: DateTime(2100),
    //           initialDate: DateTime.now(),
    //         );
    //         if (picked != null) {
    //           widget.onChanged(widget.query..extra = picked);
    //         }
    //       },
    //     );
    // }
  }
}
