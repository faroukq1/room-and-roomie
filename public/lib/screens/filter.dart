import 'package:flutter/material.dart';

class PropertyFilterPage extends StatefulWidget {
  const PropertyFilterPage({Key? key}) : super(key: key);

  @override
  State<PropertyFilterPage> createState() => _PropertyFilterPageState();
}

class _PropertyFilterPageState extends State<PropertyFilterPage> {
  double _priceRangeValue = 50.0;
  RangeValues _priceSearchValues = const RangeValues(20, 80);
  int _selectedRooms = 1;

  // Toggle state for filter type buttons
  bool _isLogsSelected = true;

  final TextEditingController _minPriceController = TextEditingController(text: "Minimum");
  final TextEditingController _maxPriceController = TextEditingController(text: "Maximum");

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('filter', style: TextStyle(color: Colors.grey)),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un lieu...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Logs/Colocs toggle buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLogsSelected = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLogsSelected ? Colors.blue[700] : Colors.white,
                      foregroundColor: _isLogsSelected ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Logs'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLogsSelected = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isLogsSelected ? Colors.blue[700] : Colors.white,
                      foregroundColor: !_isLogsSelected ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Colocs'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Price range section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price range',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbColor: Colors.white,
                      activeTrackColor: Colors.black,
                      inactiveTrackColor: Colors.grey[300],
                      trackHeight: 2.0,
                    ),
                    child: Slider(
                      value: _priceRangeValue,
                      min: 0,
                      max: 100,
                      onChanged: (value) {
                        setState(() {
                          _priceRangeValue = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Min-Max price inputs
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _minPriceController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        border: InputBorder.none,
                        hintText: 'Minimum',
                      ),
                      keyboardType: TextInputType.number,
                      onTap: () {
                        if (_minPriceController.text == "Minimum") {
                          _minPriceController.clear();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('-', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _maxPriceController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        border: InputBorder.none,
                        hintText: 'Maximum',
                      ),
                      keyboardType: TextInputType.number,
                      onTap: () {
                        if (_maxPriceController.text == "Maximum") {
                          _maxPriceController.clear();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Price search slider
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price search',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RangeSlider(
                    values: _priceSearchValues,
                    min: 0,
                    max: 100,
                    activeColor: Colors.black,
                    inactiveColor: Colors.grey[300],
                    onChanged: (values) {
                      setState(() {
                        _priceSearchValues = values;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Rooms selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rooms',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [1, 2, 3, 4].map((room) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRooms = room;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _selectedRooms == room ? Colors.grey[300] : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Center(
                          child: Text(
                            room.toString(),
                            style: TextStyle(
                              fontWeight: _selectedRooms == room ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const Spacer(),

            // Confirm button
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    // Apply filters
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}