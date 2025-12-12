class ApiResponse<T> {
  final int page;
  final List<T> results;
  final int totalPages;
  final int totalResults;

  ApiResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse<T>(
      page: json['page'] ?? 1,
      results:
          (json['results'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalPages: json['total_pages'] ?? 0,
      totalResults: json['total_results'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'results': results,
      'total_pages': totalPages,
      'total_results': totalResults,
    };
  }
}
