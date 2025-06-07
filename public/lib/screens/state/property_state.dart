import 'package:flutter/material.dart';
import '../models/property_model.dart';

class PropertyState {
  final int currentPage;
  final int limit;
  final bool hasMorePages;
  final bool isLoadingMore;
  final List<PropertyModel> properties;

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
    List<PropertyModel>? properties,
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
