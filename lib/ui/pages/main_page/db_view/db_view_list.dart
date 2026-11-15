import 'dart:convert';

import 'package:delta_trace_studio/main.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/collection_actions.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/convert_type_flow.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/date_range_filter.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/filter_data.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/filter_dialog.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/filtered_item.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/db_view_list/list_widgets.dart';
import 'package:delta_trace_studio/ui/pages/main_page/db_view/pagination_widget.dart';
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
  final _tecSearch = TextEditingController();

  final List<FilteredItem> _filteredItem = [];
  FilterData _filterData = FilterData(null, null);
  String _searchQuery = '';

  DateRangeFilter _dateFilter = const DateRangeFilter();

  String? _sortKey;
  bool _sortAscending = true;
  FilterFormState? _filterFormState;

  bool get _isDateFilterActive => _dateFilter.isActive;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _scCtrl.dispose();
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
      chips.add(ActiveChip(
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
      chips.add(ActiveChip(
        label: l10n.listFilter,
        onDeleted: () => setState(() {
          _filterData = FilterData(null, null);
          _filterFormState = null;
          _pageIndex = 0;
        }),
      ));
    }
    if (_isDateFilterActive) {
      chips.add(ActiveChip(
        label: '${l10n.dateFilterTitle}: ${_dateFilter.key}',
        onDeleted: () => setState(() {
          _dateFilter = DateRangeFilter(useLocal: _dateFilter.useLocal);
          _pageIndex = 0;
        }),
      ));
    }

    if (selectedTarget == null) {
      return chips.isEmpty ? const SizedBox.shrink() : ChipsRow(chips: chips);
    }
    final total = localDB.collection(selectedTarget!).length;
    final countText = useFiltered
        ? l10n.listItemCountFiltered(_filteredItem.length, total)
        : l10n.listItemCount(total);
    return ChipsRow(chips: chips, countText: countText);
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
              onPressed: _openDateRangeFilter,
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
              icon: const Icon(Icons.transform),
              tooltip: l10n.listConvertType,
              onPressed: selectedTarget == null
                  ? null
                  : () async {
                      final changed = await convertTypeFlow(
                        context,
                        selectedTarget!,
                        _collectKeys().toList()..sort(),
                      );
                      if (changed && mounted) setState(_searchFilter);
                    },
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
    _dateFilter = const DateRangeFilter();
    _sortKey = null;
    _sortAscending = true;
    _filterFormState = null;
  }

  bool _matchesSearch(Map<String, dynamic> item) {
    if (_searchQuery.isEmpty) return true;
    return jsonEncode(item).toLowerCase().contains(_searchQuery);
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
      if (passesFilter && _matchesSearch(i) && _dateFilter.matches(i)) {
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

  Future<void> _openDateRangeFilter() async {
    final result = await showDateRangeFilterDialog(
      context,
      keys: _collectKeys().toList()..sort(),
      initial: _dateFilter,
    );
    if (result == null) return;
    setState(() {
      _dateFilter = result;
      _pageIndex = 0;
    });
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
      return ItemCard(
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
      return ItemCard(
        itemNum: originalIndex + 1,
        jsonStr: jsonStr,
        onEdit: () => _editItem(target, originalIndex, jsonStr),
        onCopy: () => _copyToClipboard(jsonStr),
      );
    }).toList();
  }

  Future<void> _editItem(String target, int index, String jsonStr) async {
    final newItem = await showEditItemDialog(context, jsonStr);
    if (newItem == null || !mounted) return;
    setState(() {
      localDB.collection(target).raw[index] = newItem;
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.listCopied)),
    );
  }

  Future<void> _merge() async {
    final String? output = await mergeFlow(context, selectedTarget);
    if (output == null || !mounted) return;
    setState(() => selectedTarget = output);
  }

  Future<void> _removeCollection() async {
    if (!await removeCollectionFlow(context, selectedTarget!) || !mounted) {
      return;
    }
    setState(() {
      selectedTarget = null;
      _resetFilter();
    });
  }
}
