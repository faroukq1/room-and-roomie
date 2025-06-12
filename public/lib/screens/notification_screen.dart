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
  List<NotificationModel> notifications = [];

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
                ],
              ),
    );
  }
}
