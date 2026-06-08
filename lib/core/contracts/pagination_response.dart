class PaginationSummary {
  const PaginationSummary({
    this.total = 0,
    this.paid = 0,
    this.pending = 0,
    this.cancelled = 0,
  });

  final int total;
  final int paid;
  final int pending;
  final int cancelled;

  factory PaginationSummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return PaginationSummary(
      total: asInt(json['total']),
      paid: asInt(json['paid']),
      pending: asInt(json['pending']),
      cancelled: asInt(json['cancelled']),
    );
  }
}

class PaginationResponse<T> {
  const PaginationResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.nextCursor,
    this.hasMore = false,
    this.summary,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final String? nextCursor;
  final bool hasMore;
  final PaginationSummary? summary;
}
