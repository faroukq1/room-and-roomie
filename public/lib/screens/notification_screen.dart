import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final storage = const FlutterSecureStorage();
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      final userData = await storage.read(key: 'user_data');
      if (userData == null) {
        setState(() {
          notifications = [];
          isLoading = false;
        });
        return;
      }
      final user = jsonDecode(userData);
      final userId = user['id'];
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          notifications =
              data.map((item) => NotificationModel.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          notifications = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        notifications = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFCCDEF9),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
              ? const Center(child: Text('Aucune notification pour le moment.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(
                        Icons.notifications,
                        color: Colors.blueAccent,
                      ),
                      title: Text(notif.titre),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (notif.logementId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Card(
                                color: Colors.blue[50],
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          notif.logementPhotos != null &&
                                                  notif
                                                      .logementPhotos!
                                                      .isNotEmpty
                                              ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  notif.logementPhotos!
                                                      .split(',')
                                                      .first,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                              : Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.home,
                                                  size: 40,
                                                ),
                                              ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  notif.logementTitre ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (notif.logementAdresse !=
                                                    null)
                                                  Text(
                                                    'Adresse: ${notif.logementAdresse}',
                                                  ),
                                                if (notif.logementVille != null)
                                                  Text(
                                                    'Ville: ${notif.logementVille}',
                                                  ),
                                                if (notif.logementLoyer != null)
                                                  Text(
                                                    'Loyer: ${notif.logementLoyer} €/mois',
                                                  ),
                                                if (notif.logementSuperficie !=
                                                    null)
                                                  Text(
                                                    'Superficie: ${notif.logementSuperficie} m²',
                                                  ),
                                                if (notif
                                                        .logementNombrePieces !=
                                                    null)
                                                  Text(
                                                    'Pièces: ${notif.logementNombrePieces}',
                                                  ),
                                                if (notif.logementMeuble !=
                                                    null)
                                                  Text(
                                                    'Meublé: ${notif.logementMeuble! ? "Oui" : "Non"}',
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      Row(
                                        children: [
                                          notif.ownerPhoto != null &&
                                                  notif.ownerPhoto!.isNotEmpty
                                              ? CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                  notif.ownerPhoto!,
                                                ),
                                                radius: 20,
                                              )
                                              : const CircleAvatar(
                                                child: Icon(Icons.person),
                                                radius: 20,
                                              ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Propriétaire: ${notif.ownerNom ?? ''} ${notif.ownerPrenom ?? ''}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (notif.ownerEmail != null)
                                                  Text(
                                                    'Email: ${notif.ownerEmail}',
                                                  ),
                                                if (notif.ownerTelephone !=
                                                    null)
                                                  Text(
                                                    'Téléphone: ${notif.ownerTelephone}',
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          // TODO: Implement navigation to logement details screen
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Localiser le logement: ${notif.logementTitre}',
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Voir le logement'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (notif.contenu.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(notif.contenu),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Reçue le: ${notif.dateEnvoi.toLocal().toString().substring(0, 16).replaceAll("T", " ")}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
    );
  }
}
