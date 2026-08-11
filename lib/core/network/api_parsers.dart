/// Single contract for backend list payloads.
///
/// The backend returns paginated endpoints as:
///   `data: { list: [...], pagination: { total, page, limit, total_pages } }`
/// Some legacy endpoints still return a raw `data: [...]`.
/// Everything else (null, missing keys) degrades to an empty list instead
/// of throwing — the previous ad-hoc `raw['data'] as List?` casts crashed
/// silently on the `{list, pagination}` shape, breaking ICD searches.
library;

class ApiPage {
  final List<Map<String, dynamic>> list;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const ApiPage({
    required this.list,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory ApiPage.fromPayload(dynamic payload) {
    if (payload is Map) {
      final rawList = payload['list'];
      if (rawList is List) {
        final pagination = payload['pagination'];
        int page = 1;
        int limit = 20;
        int total = 0;
        int totalPages = 1;
        if (pagination is Map) {
          page = _toInt(pagination['page']) ?? page;
          limit = _toInt(pagination['limit']) ?? limit;
          total = _toInt(pagination['total']) ?? 0;
          totalPages = _toInt(pagination['total_pages']) ?? 1;
        }
        return ApiPage(
          list: _toMapList(rawList),
          page: page,
          limit: limit,
          total: total,
          totalPages: totalPages,
        );
      }
      // Nested known containers (e.g. harian-dokter returns {data: [...]}).
      final nested = payload['data'];
      if (nested is List) {
        return ApiPage(
          list: _toMapList(nested),
          page: 1,
          limit: nested.length,
          total: nested.length,
          totalPages: 1,
        );
      }
    }
    return const ApiPage(list: [], page: 1, limit: 20, total: 0, totalPages: 1);
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<Map<String, dynamic>> _toMapList(List raw) {
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

/// Returns the list portion of a backend payload:
///  - Map with `list` key      -> its items
///  - Map with nested `data`   -> those items
///  - plain List               -> itself
///  - otherwise                -> [] (never throws)
List<Map<String, dynamic>> parseListPayload(dynamic payload) {
  return ApiPage.fromPayload(payload).list;
}