import 'package:flutter/material.dart';

class FilterState {
  final String propertyType;
  final String propertySubType;
  final String bedrooms;
  final RangeValues priceRange;
  final RangeValues areaRange;

  FilterState({
    required this.propertyType,
    required this.propertySubType,
    required this.bedrooms,
    required this.priceRange,
    required this.areaRange,
  });

  FilterState copyWith({
    String? propertyType,
    String? propertySubType,
    String? bedrooms,
    RangeValues? priceRange,
    RangeValues? areaRange,
  }) {
    return FilterState(
      propertyType: propertyType ?? this.propertyType,
      propertySubType: propertySubType ?? this.propertySubType,
      bedrooms: bedrooms ?? this.bedrooms,
      priceRange: priceRange ?? this.priceRange,
      areaRange: areaRange ?? this.areaRange,
    );
  }
}
