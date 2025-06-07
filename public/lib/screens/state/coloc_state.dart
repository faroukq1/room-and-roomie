import 'package:memo/screens/home_screen.dart';

class ColocState {
  final int currentPage;
  final int limit;
  final bool hasMorePages;
  final bool isLoadingMore;
  final List<ColocModel> colocs;

  ColocState({
    required this.currentPage,
    required this.limit,
    required this.hasMorePages,
    required this.isLoadingMore,
    required this.colocs,
  });

  ColocState copyWith({
    int? currentPage,
    int? limit,
    bool? hasMorePages,
    bool? isLoadingMore,
    List<ColocModel>? colocs,
  }) {
    return ColocState(
      currentPage: currentPage ?? this.currentPage,
      limit: limit ?? this.limit,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      colocs: colocs ?? this.colocs,
    );
  }
}
