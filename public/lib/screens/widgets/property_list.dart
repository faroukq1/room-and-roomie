import 'package:flutter/material.dart';
import '../models/coloc_model.dart';

class PropertyList extends StatelessWidget {
  final List<Map<String, dynamic>> properties;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool hasMorePages;

  const PropertyList({
    super.key,
    required this.properties,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.hasMorePages,
  });

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final proprietaire = property['proprietaire'] as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            property['images'][0],
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        title: Text(property['titre']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propriétaire: ${proprietaire['nom']} ${proprietaire['prenom']}'),
            Text('Prix: ${property['loyer']} DA'),
          ],
        ),
        onTap: () {
          // Navigate to property detail
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: properties.length + (hasMorePages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= properties.length) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildPropertyCard(properties[index]);
            },
          ),
        ),
        if (hasMorePages && !isLoadingMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: onLoadMore,
              child: const Text('Charger plus'),
            ),
          ),
      ],
    );
  }
}
