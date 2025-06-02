import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _allItems = [
    'Anubia',
    'Central Park',
    'La Défense',
    'Montmartre',
    'Colocataire 1',
    'Colocataire 2',
    'Colocataire 3',
  ]; // Example data, replace with your data source

  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems; // Show all initially
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _allItems
          .where((item) => item.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher...',
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.blue,
      ),
      body: _filteredItems.isEmpty
          ? const Center(child: Text('Aucun résultat trouvé'))
          : ListView.builder(
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return ListTile(
            title: Text(item),
            onTap: () {
              // Example action on tap, maybe return the selected item
              Navigator.pop(context, item);
            },
          );
        },
      ),
    );
  }
}
