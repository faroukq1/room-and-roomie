import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class ProprietaireColocsScreen extends StatefulWidget {
  const ProprietaireColocsScreen({super.key});

  @override
  State<ProprietaireColocsScreen> createState() =>
      _ProprietaireColocsScreenState();
}

class _ProprietaireColocsScreenState extends State<ProprietaireColocsScreen> {
  List<dynamic> colocations = [];
  List<dynamic> candidatures = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchColocationsAndCandidatures();
  }

  Future<void> fetchColocationsAndCandidatures() async {
    final storage = const FlutterSecureStorage();
    final userDataStr = await storage.read(key: 'user_data');
    int? proprietaireId;
    if (userDataStr != null) {
      try {
        final userData = jsonDecode(userDataStr);
        proprietaireId = userData['id'];
      } catch (e) {}
    }
    if (proprietaireId == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    final url = Uri.parse('$baseUrl/api/colocs/proprietaire/$proprietaireId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        colocations = data['colocations'] ?? [];
        candidatures = data['candidatures'] ?? [];
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _handleCandidatureAction(
    int candidatureId,
    String action,
  ) async {
    setState(() {
      loading = true;
    });
    final url = Uri.parse(
      '$baseUrl/api/colocs/candidature/$candidatureId/action',
    );
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      );
      if (response.statusCode == 200) {
        final msg =
            action == 'accept' ? 'Candidature acceptée' : 'Candidature refusée';
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
        await fetchColocationsAndCandidatures();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur: ${jsonDecode(response.body)['error'] ?? response.body}',
              ),
            ),
          );
        }
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur réseau ou serveur.')));
      }
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Colocations & Candidatures')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [Tab(text: 'Colocataires'), Tab(text: 'Candidatures')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Colocataires Tab
                  colocations.isEmpty
                      ? const Center(child: Text('Aucun colocataire trouvé.'))
                      : ListView.builder(
                        itemCount: colocations.length,
                        itemBuilder: (context, index) {
                          final c = colocations[index];
                          return ListTile(
                            leading: const Icon(Icons.group),
                            title: Text(
                              '${c['prenom'] ?? ''} ${c['nom'] ?? ''}',
                            ),
                            subtitle: Text(
                              'Logement: ${c['logement_titre'] ?? ''}\nEntrée: ${c['date_entree'] ?? '-'}',
                            ),
                            trailing:
                                (c['date_sortie'] != null)
                                    ? Text('Sortie: ${c['date_sortie']}')
                                    : const Text('Actuel'),
                          );
                        },
                      ),
                  // Candidatures Tab
                  candidatures.isEmpty
                      ? const Center(
                        child: Text('Aucune candidature en attente.'),
                      )
                      : ListView.builder(
                        itemCount: candidatures.length,
                        itemBuilder: (context, index) {
                          final c = candidatures[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.person_add),
                              title: Text(
                                '${c['prenom'] ?? ''} ${c['nom'] ?? ''}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Logement: ${c['logement_titre'] ?? ''}',
                                  ),
                                  Text('Message: ${c['message'] ?? ''}'),
                                  Text(
                                    'Date: ${c['date_postulation']?.toString().split('T').first ?? ''}',
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Accepter',
                                    onPressed:
                                        () => _handleCandidatureAction(
                                          c['candidature_id'],
                                          'accept',
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Refuser',
                                    onPressed:
                                        () => _handleCandidatureAction(
                                          c['candidature_id'],
                                          'refuse',
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
