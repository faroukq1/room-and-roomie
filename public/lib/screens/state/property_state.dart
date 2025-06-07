class PropertyState {
  final int currentPage;
  final int limit;
  final bool hasMorePages;
  final bool isLoadingMore;
  final List<Map<String, dynamic>> properties;

  PropertyState({
    required this.currentPage,
    required this.limit,
    required this.hasMorePages,
    required this.isLoadingMore,
    required this.properties,
  });

  PropertyState copyWith({
    int? currentPage,
    int? limit,
    bool? hasMorePages,
    bool? isLoadingMore,
    List<Map<String, dynamic>>? properties,
  }) {
    return PropertyState(
      currentPage: currentPage ?? this.currentPage,
      limit: limit ?? this.limit,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      properties: properties ?? this.properties,
    );
  }
}
