import 'package:flutter/material.dart';
import '../models/coloc_model.dart';

import '../ChatScreen.dart';

class ColocList extends StatelessWidget {
  final List<ColocModel> colocs;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool hasMorePages;
  final int? currentUserId;

  const ColocList({
    super.key,
    required this.colocs,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.hasMorePages,
    required this.currentUserId,
  });

  Widget _buildColocCard(ColocModel coloc, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('Contacter'),
                onPressed: () {
                  if (currentUserId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          currentUserId: currentUserId,
                          otherUserId: coloc.userId,
                          otherUserName: '${coloc.prenom} ${coloc.nom}',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vous devez être connecté.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
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
              return _buildColocCard(colocs[index], context);
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
