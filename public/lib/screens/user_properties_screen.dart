import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';

class PropertyPhoto {
  final String url;
  final bool estPrincipale;

  PropertyPhoto.fromJson(Map<String, dynamic> json)
    : url = json['url'],
      estPrincipale = json['est_principale'];
}

class UserProperty {
  final int id;
  final String titre;
  final String description;
  final String adresse;
  final String ville;
  final String codePostal;
  final double superficie;
  final int nombrePieces;
  final int nombreColocMax;
  final String typeLogement;
  final double loyer;
  final bool chargesIncluses;
  final bool meuble;
  final DateTime disponibleAPartir;
  final DateTime dateCreation;
  final bool estActif;
  final int capaciteMaxColocataires;
  final int proprietaireId;
  final List<PropertyPhoto> photos;
  final int nombreFavoris;
  final int candidaturesEnAttente;

  UserProperty.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      titre = json['titre'],
      description = json['description'],
      adresse = json['adresse'],
      ville = json['ville'],
      codePostal = json['code_postal'],
      superficie = double.parse(json['superficie']),
      nombrePieces = json['nombre_pieces'],
      nombreColocMax = json['nombre_coloc_max'],
      typeLogement = json['type_logement'],
      loyer = double.parse(json['loyer']),
      chargesIncluses = json['charges_incluses'],
      meuble = json['meuble'],
      disponibleAPartir = DateTime.parse(json['disponible_a_partir']),
      dateCreation = DateTime.parse(json['date_creation']),
      estActif = json['est_actif'],
      capaciteMaxColocataires = json['capacite_max_colocataires'],
      proprietaireId = json['proprietaire_id'],
      photos =
          (json['photos'] as List<dynamic>)
              .map((photo) => PropertyPhoto.fromJson(photo))
              .toList(),
      nombreFavoris = int.parse(json['nombre_favoris']),
      candidaturesEnAttente = int.parse(json['candidatures_en_attente']);
}

class UserPropertiesScreen extends StatefulWidget {
  const UserPropertiesScreen({super.key});

  @override
  State<UserPropertiesScreen> createState() => _UserPropertiesScreenState();
}

class _UserPropertiesScreenState extends State<UserPropertiesScreen> {
  final storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:3000';

  List<UserProperty> _properties = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Pagination state
  int _currentPage = 1;
  final int _limit = 5;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProperties();
  }

  Future<void> _fetchUserProperties() async {
    if (_currentPage == 1) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final token = await storage.read(key: 'auth_token');
      final userData = await storage.read(key: 'user_data');

      if (token == null || userData == null) {
        setState(() {
          _errorMessage = 'Veuillez vous connecter pour voir vos propriétés';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final user = jsonDecode(userData);
      final userId = user['id'];

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/utilisateurs/$userId/logements?page=$_currentPage&limit=$_limit',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> properties = responseData['logements'] ?? [];

        // Extract pagination info
        final Map<String, dynamic> pagination = responseData['pagination'];
        final bool hasNextPage = pagination['hasNextPage'] ?? false;
        final int currentPage = pagination['currentPage'] ?? 1;

        final List<UserProperty> newProperties =
            properties
                .map<UserProperty>((item) => UserProperty.fromJson(item))
                .toList();

        setState(() {
          _properties = newProperties;
          _hasMorePages = hasNextPage;
          _currentPage = currentPage;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des propriétés';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur';
        _isLoading = false;
        _isLoadingMore = false;
      });
      print('Error fetching user properties: $e');
    }
  }

  String _getPlaceholderImage(int id) {
    final List<String> imageUrls = [
      'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6?ixlib=rb-4.0.3',
      'https://images.unsplash.com/photo-1554995207-c18c203602cb?ixlib=rb-4.0.3',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3',
      'https://images.unsplash.com/photo-1565183997392-2f6f122e5912?ixlib=rb-4.0.3',
    ];
    return imageUrls[id % imageUrls.length];
  }

  Widget _buildPropertyCard(UserProperty property) {
    final propertyData = {
      'id': property.id,
      'title': property.titre,
      'price': property.loyer,
      'location': '${property.adresse}, ${property.ville}',
      'details':
          '${property.nombrePieces} pièce${property.nombrePieces != 1 ? 's' : ''} / ${property.superficie} m²',
      'description': property.description,
      'disponible_a_partir': property.disponibleAPartir.toIso8601String(),
      'est_actif': property.estActif,
      'images': property.photos.map((photo) => photo.url).toList(),
      'type': property.typeLogement,
      'bedrooms': property.nombrePieces.toString(),
      'area': property.superficie,
      'code_postal': property.codePostal,
      'charges_incluses': property.chargesIncluses,
      'meuble': property.meuble,
      'capacite_max_colocataires': property.capaciteMaxColocataires,
    };

    String mainPhotoUrl =
        property.photos
            .firstWhere(
              (photo) => photo.estPrincipale,
              orElse: () => property.photos.first,
            )
            .url;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailPage(property: propertyData),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(mainPhotoUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Status indicator (Active/Inactive)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: property.estActif ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          property.estActif ? 'Actif' : 'Inactif',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    // Stats indicators (Favorites and Applications)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${property.nombreFavoris}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.people,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${property.candidaturesEnAttente}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Property Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.titre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${property.loyer.toStringAsFixed(2)} DA',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${property.adresse}, ${property.ville}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${property.nombrePieces} pièces • ${property.superficie} m²',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        property.typeLogement == 'maison'
                            ? Icons.house
                            : Icons.apartment,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        property.typeLogement.capitalize(),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        property.meuble ? Icons.chair : Icons.chair_outlined,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        property.meuble ? 'Meublé' : 'Non meublé',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed:
                _currentPage > 1
                    ? () async {
                      setState(() {
                        _currentPage--;
                      });
                      await _fetchUserProperties();
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.arrow_back, size: 16),
                SizedBox(width: 4),
                Text('Précédent'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Page $_currentPage',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed:
                _hasMorePages
                    ? () async {
                      setState(() {
                        _currentPage++;
                      });
                      await _fetchUserProperties();
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Text('Suivant'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCDEF9),
      appBar: AppBar(
        title: const Text('Mes Propriétés'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentPage = 1;
                        });
                        _fetchUserProperties();
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
              : _properties.isEmpty
              ? const Center(
                child: Text(
                  'Vous n\'avez pas encore de propriétés',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _properties.length,
                      itemBuilder:
                          (context, index) =>
                              _buildPropertyCard(_properties[index]),
                    ),
                  ),
                  if (!_isLoadingMore) _buildPaginationControls(),
                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
    );
  }
}
