class PaginationResponse<T> {
  const PaginationResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final String? nextCursor;
  final bool hasMore;
}
