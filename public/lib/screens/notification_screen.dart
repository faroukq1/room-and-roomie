import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification.dart';
import '../models/accepted_colocation.dart';
import '../screens/paymentpage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _fullImageUrl(String path) {
    path = path.trim();
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) {
      return baseUrl + path;
    } else {
      return baseUrl + '/' + path;
    }
  }

  final storage = const FlutterSecureStorage();
  List<NotificationModel> notifications = [];
  List<AcceptedColocation> acceptedColocations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => isLoading = true);
    try {
      final userData = await storage.read(key: 'user_data');
      if (userData == null) {
        setState(() {
          notifications = [];
          acceptedColocations = [];
          isLoading = false;
        });
        return;
      }
      final user = jsonDecode(userData);
      final userId = user['id'];
      // Fetch accepted colocations
      final colocsResponse = await http.get(
        Uri.parse('$baseUrl/api/notifications/accepted-colocations/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      List<AcceptedColocation> colocs = [];
      if (colocsResponse.statusCode == 200) {
        final List<dynamic> colocData = jsonDecode(colocsResponse.body);
        colocs =
            colocData.map((item) => AcceptedColocation.fromJson(item)).toList();
      }
      setState(() {
        acceptedColocations = colocs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        acceptedColocations = [];
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
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (acceptedColocations.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mes Colocations Acceptées',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...acceptedColocations.map(
                          (coloc) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PaymentPage(
                                          title: coloc.logementTitre,
                                          price: coloc.logementLoyer,
                                          imageUrl: _fullImageUrl(
                                            coloc.logementPhotos != null &&
                                                    coloc
                                                        .logementPhotos!
                                                        .isNotEmpty
                                                ? coloc.logementPhotos!
                                                    .split(',')
                                                    .first
                                                : '',
                                          ),
                                          details: coloc.logementDescription,
                                          location: coloc.logementAdresse,
                                          logementId: coloc.logementId,
                                        ),
                                  ),
                                );
                              },
                              child: ListTile(
                                leading:
                                    (coloc.logementPhotos != null &&
                                            coloc.logementPhotos!.isNotEmpty)
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            _fullImageUrl(
                                              coloc.logementPhotos!
                                                  .split(',')
                                                  .first,
                                            ),
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: Colors.grey[300],
                                                      width: 60,
                                                      height: 60,
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                      ),
                                                    ),
                                          ),
                                        )
                                        : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.home,
                                            size: 32,
                                          ),
                                        ),
                                title: Text(coloc.logementTitre),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(coloc.logementAdresse),
                                    Text('Ville: ${coloc.logementVille}'),
                                    Text(
                                      'Loyer: ${coloc.logementLoyer} €/mois',
                                    ),
                                    if (coloc.ownerNom.isNotEmpty)
                                      Text(
                                        'Propriétaire: ${coloc.ownerNom} ${coloc.ownerPrenom}',
                                      ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 32),
                      ],
                    ),
                  if (notifications.isEmpty)
                    const Center(
                      child: Text('Aucune notification pour le moment.'),
                    )
                  else ...[
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...notifications.map(
                      (notif) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading:
                              (notif.logementPhotos != null &&
                                      notif.logementPhotos!.isNotEmpty)
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _fullImageUrl(
                                        notif.logementPhotos!.split(',').first,
                                      ),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[300],
                                                width: 80,
                                                height: 80,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                ),
                                              ),
                                    ),
                                  )
                                  : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.notifications,
                                      size: 40,
                                    ),
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
                                                  ? SizedBox(
                                                    width: 100,
                                                    height: 80,
                                                    child: ListView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      children:
                                                          notif.logementPhotos!
                                                              .split(',')
                                                              .where(
                                                                (url) =>
                                                                    url
                                                                        .trim()
                                                                        .isNotEmpty,
                                                              )
                                                              .map(
                                                                (
                                                                  url,
                                                                ) => Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        right:
                                                                            4,
                                                                      ),
                                                                  child: ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    child: Image.network(
                                                                      url,
                                                                      width: 80,
                                                                      height:
                                                                          80,
                                                                      fit:
                                                                          BoxFit
                                                                              .cover,
                                                                      errorBuilder:
                                                                          (
                                                                            context,
                                                                            error,
                                                                            stackTrace,
                                                                          ) => Container(
                                                                            color:
                                                                                Colors.grey[300],
                                                                            width:
                                                                                80,
                                                                            height:
                                                                                80,
                                                                            child: const Icon(
                                                                              Icons.broken_image,
                                                                            ),
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    if (notif.logementAdresse !=
                                                        null)
                                                      Text(
                                                        'Adresse: ${notif.logementAdresse}',
                                                      ),
                                                    if (notif.logementVille !=
                                                        null)
                                                      Text(
                                                        'Ville: ${notif.logementVille}',
                                                      ),
                                                    if (notif.logementLoyer !=
                                                        null)
                                                      Text(
                                                        'Loyer: ${notif.logementLoyer} €/mois',
                                                      ),
                                                    if (notif
                                                            .logementSuperficie !=
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
                                                      notif
                                                          .ownerPhoto!
                                                          .isNotEmpty
                                                  ? CircleAvatar(
                                                    backgroundImage:
                                                        NetworkImage(
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
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    if (notif.ownerEmail !=
                                                        null)
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
                                            child: const Text(
                                              'Voir le logement',
                                            ),
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
                      ),
                    ),
                  ],
                ],
              ),
    );
  }
}
