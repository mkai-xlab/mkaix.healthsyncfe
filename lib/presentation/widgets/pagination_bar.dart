import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  static const List<int> pageSizeOptions = [5, 10, 20];

  final int currentPage;
  final int totalPages;
  final int totalElements;
  final int pageSize;
  final bool isLoading;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final String itemLabel;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.pageSize,
    required this.isLoading,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.itemLabel = 'mục',
  });

  @override
  Widget build(BuildContext context) {
    final safeTotalPages = totalPages <= 0 ? 1 : totalPages;
    final displayPage = currentPage.clamp(0, safeTotalPages - 1) + 1;
    final canGoBack = !isLoading && currentPage > 0;
    final canGoForward = !isLoading && currentPage < safeTotalPages - 1;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Tổng $totalElements $itemLabel',
            style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
          ),
          const SizedBox(width: 8),
          const Text(
            'Hiển thị',
            style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
          ),
          SizedBox(
            height: 34,
            child: DropdownButton<int>(
              value: pageSizeOptions.contains(pageSize)
                  ? pageSize
                  : pageSizeOptions.first,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(8),
              items: pageSizeOptions
                  .map(
                    (size) => DropdownMenuItem<int>(
                      value: size,
                      child: Text('$size'),
                    ),
                  )
                  .toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value != null) onPageSizeChanged(value);
                    },
            ),
          ),
          Text(
            'dòng/trang',
            style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
          ),
          const SizedBox(width: 8),
          Text(
            'Trang $displayPage / $safeTotalPages',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B3C),
            ),
          ),
          IconButton(
            onPressed: canGoBack ? () => onPageChanged(currentPage - 1) : null,
            tooltip: 'Trang trước',
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: canGoForward
                ? () => onPageChanged(currentPage + 1)
                : null,
            tooltip: 'Trang sau',
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
