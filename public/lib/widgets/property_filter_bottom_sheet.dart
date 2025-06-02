import 'package:flutter/material.dart';

class PropertyFilterBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>)? onApplyFilters;

  const PropertyFilterBottomSheet({
    Key? key,
    this.onApplyFilters,
  }) : super(key: key);

  @override
  State<PropertyFilterBottomSheet> createState() => _PropertyFilterBottomSheetState();
}

class _PropertyFilterBottomSheetState extends State<PropertyFilterBottomSheet> {
  String _propertyType = 'Résidentielle'; // Résidentielle or Commercial
  String _propertySubType = ''; // Appartement, Maison, Villa, etc.
  RangeValues _priceRange = const RangeValues(0, 100000); // Default price range
  String _selectedBedrooms = ''; // Studio, 1, 2, 3, 4, 5
  RangeValues _areaRange = const RangeValues(0, 500); // Default area range in m²

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
          // Header
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type de propriété
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Text(
                      'Type de propriété',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildTypeButton('Résidentielle', isSelected: _propertyType == 'Résidentielle'),
                            _buildTypeButton('Commercial', isSelected: _propertyType == 'Commercial'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_propertyType == 'Résidentielle')
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSubTypeButton('Appartement', isSelected: _propertySubType == 'Appartement'),
                              _buildSubTypeButton('Maison', isSelected: _propertySubType == 'Maison'),
                              _buildSubTypeButton('Villa', isSelected: _propertySubType == 'Villa'),
                              _buildSubTypeButton('Chambre', isSelected: _propertySubType == 'Chambre'),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const Divider(height: 24),

                  // Prix
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'Prix',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Min',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Max',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 24),

                  // Chambres
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'Chambres',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _buildBedButton('Studio'),
                        _buildBedButton('1'),
                        _buildBedButton('2'),
                        _buildBedButton('3'),
                        _buildBedButton('4'),
                        _buildBedButton('5'),
                      ],
                    ),
                  ),

                  const Divider(height: 24),

                  // Superficie
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'Superficie',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Min',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Max',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Apply filters button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // Collect all filter values
                final filters = {
                  'propertyType': _propertyType,
                  'propertySubType': _propertySubType,
                  'priceRange': _priceRange,
                  'bedrooms': _selectedBedrooms,
                  'areaRange': _areaRange,
                };

                // Call the callback if provided
                if (widget.onApplyFilters != null) {
                  widget.onApplyFilters!(filters);
                }

                // Close the bottom sheet
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Chercher',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8), // Space for bottom safe area
        ],
      ),
    );
  }

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
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
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
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildBedButton(String count) {
    final isSelected = _selectedBedrooms == count;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBedrooms = count;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          count,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}