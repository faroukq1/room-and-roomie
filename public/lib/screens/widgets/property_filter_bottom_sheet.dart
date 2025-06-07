import 'package:flutter/material.dart';

class PropertyFilterBottomSheet extends StatefulWidget {
  const PropertyFilterBottomSheet({super.key});

  @override
  State<PropertyFilterBottomSheet> createState() => _PropertyFilterBottomSheetState();
}

class _PropertyFilterBottomSheetState extends State<PropertyFilterBottomSheet> {
  String _propertyType = 'Résidentielle';
  String _propertySubType = '';
  RangeValues _priceRange = const RangeValues(0, 100000);
  String _selectedBedrooms = '';
  RangeValues _areaRange = const RangeValues(0, 500);

  Widget _buildTypeButton(String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _propertyType = label;
          _propertySubType = '';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSubTypeButton(String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _propertySubType = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBedButton(String count) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBedrooms = count;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedBedrooms == count ? Colors.blue : Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          count,
          style: TextStyle(
            color: _selectedBedrooms == count ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
                const Text(
                  'Filtres',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _propertyType = 'Résidentielle';
                      _propertySubType = '';
                      _priceRange = const RangeValues(0, 100000);
                      _selectedBedrooms = '';
                      _areaRange = const RangeValues(0, 500);
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Add your filter UI implementation here
        ],
      ),
    );
  }
}
