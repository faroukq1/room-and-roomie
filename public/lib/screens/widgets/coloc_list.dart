import 'package:flutter/material.dart';
import '../models/coloc_model.dart';

class ColocList extends StatelessWidget {
  final List<ColocModel> colocs;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool hasMorePages;

  const ColocList({
    super.key,
    required this.colocs,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.hasMorePages,
  });

  Widget _buildColocCard(ColocModel coloc) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            coloc.photoProfil,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person),
            ),
          ),
        ),
        title: Text('${coloc.prenom} ${coloc.nom}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ville: ${coloc.userVille}'),
            Text('Logement: ${coloc.logementTitre}'),
          ],
        ),
        onTap: () {
          // Navigate to coloc detail
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
            itemCount: colocs.length + (hasMorePages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= colocs.length) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildColocCard(colocs[index]);
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
