import 'dart:convert';

import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/filter_data.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/filter_dialog.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/filtered_item.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/merge_dialog.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/pagination_widget.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_with_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DbViewList extends StatefulWidget {
  const DbViewList({super.key});

  @override
  State createState() => _DbViewListState();
}

class _DbViewListState extends State<DbViewList> {
  static const int _defItemsPerPage = 10;
  int _itemsPerPage = _defItemsPerPage;
  int _pageIndex = 0;
  final ScrollController _scCtrl = ScrollController();
  final _tecEdit = TextEditingController();
  final _tecSearch = TextEditingController();

  final List<FilteredItem> _filteredItem = [];
  FilterData _filterData = FilterData(null, null);
  String _searchQuery = '';

  String? _dateFilterKey;
  DateTime? _dateFilterStart;
  DateTime? _dateFilterEnd;
  bool _dateFilterUseLocal = false;

  String? _sortKey;
  bool _sortAscending = true;
  FilterFormState? _filterFormState;

  bool get _isDateFilterActive =>
      _dateFilterKey != null &&
      _dateFilterKey!.isNotEmpty &&
      (_dateFilterStart != null || _dateFilterEnd != null);

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _scCtrl.dispose();
    _tecEdit.dispose();
    _tecSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _searchFilter();
    final totalPages = _getTotalPages();
    final useFiltered =
        _filterData.isFilterEnabled() ||
        _searchQuery.isNotEmpty ||
        _isDateFilterActive;

    return Column(
      children: [
        _buildToolbar(),
        _buildSearchBar(),
        _buildStatusBar(useFiltered),
        Expanded(
          child: ListView(
            controller: _scCtrl,
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: useFiltered
                ? _getCollectionItemsForFilter(selectedTarget)
                : _getCollectionItemsNonFilter(selectedTarget),
          ),
        ),
        PaginationWidget(
          pageNum: _pageIndex + 1,
          totalPages: totalPages,
          callback: (int selectedPageNum) {
            setState(() {
              _scCtrl.jumpTo(0);
              _pageIndex = selectedPageNum - 1;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusBar(bool useFiltered) {
    final l10n = _l10n;
    final chips = <Widget>[];
    if (_searchQuery.isNotEmpty) {
      chips.add(_activeChip(
        label: '"$_searchQuery"',
        onDeleted: () {
          _tecSearch.clear();
          setState(() {
            _searchQuery = '';
            _pageIndex = 0;
          });
        },
      ));
    }
    if (_filterData.isFilterEnabled()) {
      chips.add(_activeChip(
        label: l10n.listFilter,
        onDeleted: () => setState(() {
          _filterData = FilterData(null, null);
          _filterFormState = null;
          _pageIndex = 0;
        }),
      ));
    }
    if (_isDateFilterActive) {
      chips.add(_activeChip(
        label: '${l10n.dateFilterTitle}: $_dateFilterKey',
        onDeleted: () => setState(() {
          _dateFilterKey = null;
          _dateFilterStart = null;
          _dateFilterEnd = null;
          _pageIndex = 0;
        }),
      ));
    }

    if (selectedTarget == null) {
      return chips.isEmpty ? const SizedBox.shrink() : _chipsRow(chips, null);
    }
    final total = localDB.collection(selectedTarget!).length;
    final countText = useFiltered
        ? l10n.listItemCountFiltered(_filteredItem.length, total)
        : l10n.listItemCount(total);
    return _chipsRow(chips, countText);
  }

  Widget _chipsRow(List<Widget> chips, String? countText) {
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
              countText,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _activeChip({required String label, required VoidCallback onDeleted}) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDeleted,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildToolbar() {
    final l10n = _l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Text(l10n.listTarget),
            const SizedBox(width: 8),
            _buildStringDropdown(
              items: localDB.raw.keys.toList(),
              selectedValue: selectedTarget,
              hintText: l10n.listPleaseSelect,
              onChanged: (String? s) {
                setState(() {
                  selectedTarget = s;
                  _resetFilter();
                });
              },
            ),
            const SizedBox(width: 12),
            Text(l10n.listPerPage),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _itemsPerPage,
              items: const [10, 20, 50, 100, 200]
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (int? v) {
                if (v != null) {
                  setState(() {
                    _itemsPerPage = v;
                    _pageIndex = 0;
                  });
                }
              },
            ),
            _toolbarDivider(),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _filterData.isFilterEnabled()
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              tooltip: l10n.listFilter,
              onPressed: () async {
                final result = await showDialog<
                    ({FilterData filterData, FilterFormState formState})>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => FilterDialog(
                    initial: _filterFormState,
                    availableKeys: (_collectKeys().toList()..sort()),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _filterData = result.filterData;
                    _filterFormState = result.formState;
                    _pageIndex = 0;
                  });
                }
              },
            ),
            IconButton(
              icon: Icon(
                Icons.calendar_month,
                color: _isDateFilterActive
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              tooltip: l10n.dateFilterTitle,
              onPressed: _showDateRangeFilterDialog,
            ),
            _toolbarDivider(),
            Text(l10n.listSortBy),
            const SizedBox(width: 4),
            DropdownButton<String?>(
              value: _collectKeys().contains(_sortKey) ? _sortKey : null,
              hint: const Text('-'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('-'),
                ),
                ...(_collectKeys().toList()..sort()).map(
                  (k) => DropdownMenuItem<String?>(value: k, child: Text(k)),
                ),
              ],
              onChanged: (v) => setState(() {
                _sortKey = v;
                _pageIndex = 0;
              }),
            ),
            if (_sortKey != null)
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: _sortAscending ? l10n.sortAscending : l10n.sortDescending,
                onPressed: () => setState(() {
                  _sortAscending = !_sortAscending;
                  _pageIndex = 0;
                }),
              ),
            _toolbarDivider(),
            IconButton(
              icon: const Icon(Icons.merge_type),
              tooltip: l10n.listMerge,
              onPressed: () => _merge(),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: selectedTarget != null
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
              tooltip: l10n.listRemoveCollection,
              onPressed: selectedTarget == null ? null : _removeCollection,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = _l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: _tecSearch,
        decoration: InputDecoration(
          hintText: l10n.listSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _tecSearch.clear();
                    setState(() {
                      _searchQuery = '';
                      _pageIndex = 0;
                    });
                  },
                )
              : null,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onChanged: (v) {
          setState(() {
            _searchQuery = v.trim().toLowerCase();
            _pageIndex = 0;
          });
        },
      ),
    );
  }

  void _resetFilter() {
    _pageIndex = 0;
    _filteredItem.clear();
    _filterData = FilterData(null, null);
    _searchQuery = '';
    _tecSearch.clear();
    _dateFilterKey = null;
    _dateFilterStart = null;
    _dateFilterEnd = null;
    _dateFilterUseLocal = false;
    _sortKey = null;
    _sortAscending = true;
    _filterFormState = null;
  }

  bool _matchesSearch(Map<String, dynamic> item) {
    if (_searchQuery.isEmpty) return true;
    return jsonEncode(item).toLowerCase().contains(_searchQuery);
  }

  bool _matchesDateRange(Map<String, dynamic> item) {
    if (!_isDateFilterActive) return true;
    final val = item[_dateFilterKey!];
    if (val == null) return false;
    final dt = DateTime.tryParse(val.toString());
    if (dt == null) return false;
    if (_dateFilterStart != null && dt.isBefore(_dateFilterStart!)) return false;
    if (_dateFilterEnd != null && dt.isAfter(_dateFilterEnd!)) return false;
    return true;
  }

  void _searchFilter() {
    if (!_filterData.isFilterEnabled() &&
        _searchQuery.isEmpty &&
        !_isDateFilterActive) {
      return;
    }
    _filteredItem.clear();
    if (selectedTarget == null) return;
    int index = 0;
    for (Map<String, dynamic> i in localDB.collection(selectedTarget!).raw) {
      bool passesFilter = true;
      if (_filterData.isFilterEnabled()) {
        if (_filterData.node1 != null && _filterData.node2 == null) {
          passesFilter = _filterData.node1!.evaluate(i);
        } else if (_filterData.node1 == null && _filterData.node2 != null) {
          passesFilter = _filterData.node2!.evaluate(i);
        } else if (_filterData.node1 != null && _filterData.node2 != null) {
          passesFilter =
              _filterData.node1!.evaluate(i) && _filterData.node2!.evaluate(i);
        }
      }
      if (passesFilter && _matchesSearch(i) && _matchesDateRange(i)) {
        _filteredItem.add(FilteredItem(index, i));
      }
      index += 1;
    }
  }

  Set<String> _collectKeys() {
    if (selectedTarget == null) return {};
    final keys = <String>{};
    for (final item in localDB.collection(selectedTarget!).raw) {
      keys.addAll(item.keys);
    }
    return keys;
  }

  int _compareValues(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    if (a is num && b is num) return a.compareTo(b);
    return a.toString().compareTo(b.toString());
  }

  List<FilteredItem> _sortedFilteredItems() {
    if (_sortKey == null) return _filteredItem;
    final sorted = List<FilteredItem>.from(_filteredItem);
    sorted.sort((a, b) =>
        _compareValues(a.item[_sortKey!], b.item[_sortKey!]) *
        (_sortAscending ? 1 : -1));
    return sorted;
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return _l10n.dateFilterNotSet;
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }

  Future<DateTime?> _pickDateTime(DateTime? initial, {required bool useLocal}) async {
    final now = DateTime.now();
    final initialLocal = initial?.toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: initialLocal ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;
    if (!mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: initialLocal != null
          ? TimeOfDay.fromDateTime(initialLocal)
          : TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (time == null) return null;
    if (useLocal) {
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } else {
      return DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);
    }
  }

  void _showDateRangeFilterDialog() {
    final availableKeys = _collectKeys().toList()..sort();
    String key = _dateFilterKey ?? '';
    DateTime? start = _dateFilterStart;
    DateTime? end = _dateFilterEnd;
    bool useLocal = _dateFilterUseLocal;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(_l10n.dateFilterTitle),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: _l10n.dateFilterKey,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: availableKeys.contains(key) ? key : null,
                          hint: Text(_l10n.dateFilterKeyHint),
                          isExpanded: true,
                          isDense: true,
                          items: availableKeys
                              .map(
                                (k) =>
                                    DropdownMenuItem(value: k, child: Text(k)),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => key = v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _l10n.dateFilterUseLocalTime,
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: useLocal,
                      onChanged: (v) => setDialogState(() {
                        useLocal = v ?? false;
                        start = null;
                        end = null;
                      }),
                    ),
                    const SizedBox(height: 8),
                    _buildDateTimeRow(
                      label: _l10n.dateFilterStart,
                      value: start,
                      onPick: () async {
                        final dt = await _pickDateTime(start, useLocal: useLocal);
                        if (dt != null) setDialogState(() => start = dt);
                      },
                      onClear: () => setDialogState(() => start = null),
                    ),
                    const SizedBox(height: 12),
                    _buildDateTimeRow(
                      label: _l10n.dateFilterEnd,
                      value: end,
                      onPick: () async {
                        final dt = await _pickDateTime(end, useLocal: useLocal);
                        if (dt != null) setDialogState(() => end = dt);
                      },
                      onClear: () => setDialogState(() => end = null),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    setState(() {
                      _dateFilterKey = null;
                      _dateFilterStart = null;
                      _dateFilterEnd = null;
                      _dateFilterUseLocal = useLocal;
                      _pageIndex = 0;
                    });
                  },
                  child: Text(_l10n.dateFilterClear),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(_l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: (key.isNotEmpty &&
                          (start != null || end != null))
                      ? () {
                          Navigator.pop(dialogContext);
                          setState(() {
                            _dateFilterKey = key;
                            _dateFilterStart = start;
                            _dateFilterEnd = end;
                            _dateFilterUseLocal = useLocal;
                            _pageIndex = 0;
                          });
                        }
                      : null,
                  child: Text(_l10n.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateTimeRow({
    required String label,
    required DateTime? value,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              alignment: Alignment.centerLeft,
            ),
            onPressed: onPick,
            child: Text(
              _formatDateTime(value),
              style: const TextStyle(fontFamily: 'Noto Sans Mono', fontSize: 13),
            ),
          ),
        ),
        if (value != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: onClear,
          )
        else
          const SizedBox(width: 40),
      ],
    );
  }

  Widget _toolbarDivider() => Container(
        width: 1,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Theme.of(context).colorScheme.outlineVariant,
      );

  Widget _buildStringDropdown({
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    required String hintText,
  }) {
    return DropdownButton<String>(
      value: selectedValue,
      hint: Text(hintText),
      isExpanded: false,
      items: items
          .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
          .toList(),
      onChanged: onChanged,
    );
  }

  int _getTotalPages() {
    final useFiltered =
        _filterData.isFilterEnabled() ||
        _searchQuery.isNotEmpty ||
        _isDateFilterActive;
    int total = selectedTarget == null
        ? 1
        : useFiltered
            ? (_filteredItem.length / _itemsPerPage).ceil()
            : (localDB.collection(selectedTarget!).length / _itemsPerPage)
                .ceil();
    return total == 0 ? 1 : total;
  }

  List<Widget> _getCollectionItemsForFilter(String? target) {
    if (target == null) {
      return [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(_l10n.listPleaseSelectCollection),
        ),
      ];
    }
    final offset = _pageIndex * _itemsPerPage;
    final items =
        _sortedFilteredItems().skip(offset).take(_itemsPerPage).toList();
    return items.map((item) {
      final itemNumInDb = item.index + 1;
      final jsonStr = const JsonEncoder.withIndent('  ').convert(item.item);
      return _buildItemCard(
        itemNum: itemNumInDb,
        jsonStr: jsonStr,
        onEdit: () => _editItem(target, item.index, jsonStr),
        onCopy: () => _copyToClipboard(jsonStr),
      );
    }).toList();
  }

  List<Widget> _getCollectionItemsNonFilter(String? target) {
    if (target == null) {
      return [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(_l10n.listPleaseSelectCollection),
        ),
      ];
    }
    final raw = localDB.collection(target).raw;
    final indexed = List.generate(raw.length, (i) => (i, raw[i]));
    if (_sortKey != null) {
      indexed.sort((a, b) =>
          _compareValues(a.$2[_sortKey!], b.$2[_sortKey!]) *
          (_sortAscending ? 1 : -1));
    }
    final offset = _pageIndex * _itemsPerPage;
    final page = indexed.skip(offset).take(_itemsPerPage).toList();
    return page.map((entry) {
      final originalIndex = entry.$1;
      final item = entry.$2;
      final jsonStr = const JsonEncoder.withIndent('  ').convert(item);
      return _buildItemCard(
        itemNum: originalIndex + 1,
        jsonStr: jsonStr,
        onEdit: () => _editItem(target, originalIndex, jsonStr),
        onCopy: () => _copyToClipboard(jsonStr),
      );
    }).toList();
  }

  Widget _buildItemCard({
    required int itemNum,
    required String jsonStr,
    required VoidCallback onEdit,
    required VoidCallback onCopy,
  }) {
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

  Future<void> _editItem(String target, int index, String jsonStr) async {
    final l10n = _l10n;
    _tecEdit.text = jsonStr;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? jsonError;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.listEditJson),
              content: SizedBox(
                width: 600,
                height: 400,
                child: TextField(
                  controller: _tecEdit,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    errorText: jsonError,
                  ),
                  onChanged: (_) {
                    if (jsonError != null) {
                      setDialogState(() => jsonError = null);
                    }
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    try {
                      final newItem =
                          jsonDecode(_tecEdit.text) as Map<String, dynamic>;
                      Navigator.pop(dialogContext);
                      setState(() {
                        localDB.collection(target).raw[index] = newItem;
                      });
                    } catch (_) {
                      setDialogState(() => jsonError = l10n.listInvalidJson);
                    }
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.listCopied)),
    );
  }

  Future<void> _merge() async {
    final l10n = _l10n;
    final source = [...localDB.raw.keys].where((x) => x != selectedTarget);
    final MergeQueryParams? mqp = await showMergeQueryParamsDialog(
      context,
      initial: MergeQueryParams(
        base: selectedTarget ?? "",
        source: source.toList(),
        relationKey: "",
        sourceKeys: [],
        output: "output_collection_name",
        dslTmp: {},
        serialBase: selectedTarget,
      ),
    );
    if (mqp != null) {
      final now = DateTime.now().toUtc();
      final Query mergeQuery = RawQueryBuilder.merge(
        mergeQueryParams: mqp,
        cause: Cause(
          who: Actor(EnumActorType.system, "DeltaTraceStudio"),
          when: TemporalTrace(
            nodes: [
              TimestampNode(timestamp: now, location: "DeltaTraceStudio App"),
            ],
          ),
          what: "Merging collections is performed through user UI actions.",
          why: "Run merge function.",
          from: "DeltaTraceStudio App",
        ),
      ).build();
      final r = localDB.executeQuery(mergeQuery);
      if (r.isSuccess) {
        setState(() {
          selectedTarget = mqp.output;
          appliedQueries.add(QueryWithTime(mergeQuery.toDict(), now));
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.listOperationFailed),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _removeCollection() {
    final l10n = _l10n;
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(l10n.listConfirmTitle),
          content: Text(l10n.listConfirmRemoveBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.no),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  if (selectedTarget != null) {
                    final now = DateTime.now().toUtc();
                    final removeQuery = RawQueryBuilder.removeCollection(
                      target: selectedTarget!,
                      cause: Cause(
                        who: Actor(EnumActorType.system, "DeltaTraceStudio"),
                        when: TemporalTrace(
                          nodes: [
                            TimestampNode(
                              timestamp: now,
                              location: "DeltaTraceStudio App",
                            ),
                          ],
                        ),
                        what:
                            "removeCollections is performed through user UI actions.",
                        why: "Run removeCollection function.",
                        from: "DeltaTraceStudio App",
                      ),
                    ).build();
                    final r = localDB.executeQuery(removeQuery);
                    if (r.isSuccess) {
                      appliedQueries.add(
                        QueryWithTime(removeQuery.toDict(), now),
                      );
                      selectedTarget = null;
                      _resetFilter();
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.listOperationFailed),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                });
              },
              child: Text(l10n.yes),
            ),
          ],
        );
      },
    );
  }
}
