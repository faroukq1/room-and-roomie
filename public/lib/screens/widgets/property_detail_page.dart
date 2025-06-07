import 'package:flutter/material.dart';

class PropertyDetailPage extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyDetailPage({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final proprietaire = property['proprietaire'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text(property['titre'])),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                property['images'][0],
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: Text('Image non disponible')),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['titre'],
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Propriétaire: ${proprietaire['nom']} ${proprietaire['prenom']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description: ${property['description']}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
