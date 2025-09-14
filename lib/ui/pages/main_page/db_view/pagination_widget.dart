import 'package:flutter/material.dart';
import 'dart:math';

class PaginationWidget extends StatelessWidget {
  final int pageNum; // 現在のページ番号
  final int totalPages; // 総ページ数
  final void Function(int selectedPageNum) callback;

  const PaginationWidget({
    super.key,
    required this.pageNum,
    required this.totalPages,
    required this.callback,
  });

  List<int?> _buildPageList() {
    if (totalPages <= 5) {
      return List.generate(totalPages, (i) => i + 1);
    }

    const visibleRange = 2; // 現在ページの前後に何ページ見せるか
    final List<int?> pages = [];

    // 先頭ページ
    pages.add(1);

    // 現在ページの前に飛びがあれば "..." を追加
    if (pageNum - visibleRange > 2) {
      pages.add(null);
    }

    // 現在ページの前後を追加
    final start = max(2, pageNum - visibleRange);
    final end = min(totalPages - 1, pageNum + visibleRange);
    for (int i = start; i <= end; i++) {
      pages.add(i);
    }

    // 現在ページの後に飛びがあれば "..." を追加
    if (pageNum + visibleRange < totalPages - 1) {
      pages.add(null);
    }

    // 最後のページ
    pages.add(totalPages);

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPageList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: pageNum > 1 ? () => callback(pageNum - 1) : null,
        ),
        Row(
          children: pages.map((p) {
            if (p == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text("..."),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: p == pageNum ? null : () => callback(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: p == pageNum
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300],
                  foregroundColor: p == pageNum ? Colors.white : Colors.black,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(36, 36), // 最小サイズを設定
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text("$p"),
              ),
            );
          }).toList(),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: pageNum < totalPages ? () => callback(pageNum + 1) : null,
        ),
      ],
    );
  }
}
