import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';

class PropertyPhoto {
  final String url;
  final bool estPrincipale;

  PropertyPhoto.fromJson(Map<String, dynamic> json)
    : url = json['url'] ?? '',
      estPrincipale = json['est_principale'] ?? false;
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
    : id = json['id'] ?? 0,
      titre = json['titre'] ?? '',
      description = json['description'] ?? '',
      adresse = json['adresse'] ?? '',
      ville = json['ville'] ?? '',
      codePostal = json['code_postal'] ?? '',
      superficie =
          double.tryParse(json['superficie']?.toString() ?? '0') ?? 0.0,
      nombrePieces = json['nombre_pieces'] ?? 0,
      nombreColocMax = json['nombre_coloc_max'] ?? 0,
      typeLogement = json['type_logement'] ?? '',
      loyer = double.tryParse(json['loyer']?.toString() ?? '0') ?? 0.0,
      chargesIncluses = json['charges_incluses'] ?? false,
      meuble = json['meuble'] ?? false,
      disponibleAPartir =
          DateTime.tryParse(json['disponible_a_partir'] ?? '') ??
          DateTime.now(),
      dateCreation =
          DateTime.tryParse(json['date_creation'] ?? '') ?? DateTime.now(),
      estActif = json['est_actif'] ?? false,
      capaciteMaxColocataires = json['capacite_max_colocataires'] ?? 0,
      proprietaireId = json['proprietaire_id'] ?? 0,
      photos =
          (json['photos'] as List<dynamic>?)
              ?.map((photo) => PropertyPhoto.fromJson(photo))
              .toList() ??
          [],
      nombreFavoris =
          int.tryParse(json['nombre_favoris']?.toString() ?? '0') ?? 0,
      candidaturesEnAttente =
          int.tryParse(json['candidatures_en_attente']?.toString() ?? '0') ?? 0;
}

class UserPropertiesScreen extends StatefulWidget {
  const UserPropertiesScreen({super.key});

  @override
  State<UserPropertiesScreen> createState() => _UserPropertiesScreenState();
}

class _UserPropertiesScreenState extends State<UserPropertiesScreen> {
  final storage = const FlutterSecureStorage();
  final String baseUrl =
      'http://10.0.2.2:3000'; // Replace with your server's IP

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
      final userData = await storage.read(key: 'user_data');

      if (userData == null) {
        setState(() {
          _errorMessage = 'Veuillez vous connecter pour voir vos propriétés';
          _isLoading = false;
          _isLoadingMore = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      Map<String, dynamic> user;
      try {
        user = jsonDecode(userData);
      } catch (e) {
        setState(() {
          _errorMessage = 'Erreur lors de la lecture des données utilisateur';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final userId = user['id'];
      if (userId == null) {
        setState(() {
          _errorMessage = 'ID utilisateur manquant';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/utilisateurs/$userId/logements?page=$_currentPage&limit=$_limit',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> properties = responseData['logements'] ?? [];
        final Map<String, dynamic> pagination =
            responseData['pagination'] ?? {};
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
          _errorMessage =
              'Erreur lors du chargement des propriétés: ${response.statusCode}';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
      print('Error fetching user properties: $e');
    }
  }

  void _addNewProperty() {
    Navigator.pushNamed(
      context,
      '/addnewproperty',
    ).then((_) => _fetchUserProperties());
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
                      setState(() => _currentPage--);
                      await _fetchUserProperties();
                    }
                    : null,
            child: const Row(
              children: [
                Icon(Icons.arrow_back),
                SizedBox(width: 4),
                Text('Précédent'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Page $_currentPage'),
          ),
          ElevatedButton(
            onPressed:
                _hasMorePages
                    ? () async {
                      setState(() => _currentPage++);
                      await _fetchUserProperties();
                    }
                    : null,
            child: const Row(
              children: [
                Text('Suivant'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ],
      ),
    );
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
        property.photos.isNotEmpty
            ? property.photos
                .firstWhere(
                  (photo) => photo.estPrincipale,
                  orElse:
                      () => PropertyPhoto.fromJson({
                        'url': _getPlaceholderImage(property.id),
                        'est_principale': true,
                      }),
                )
                .url
            : _getPlaceholderImage(property.id);

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
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Row(
                        children: [
                          _buildBadge(
                            Icons.favorite,
                            '${property.nombreFavoris}',
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            Icons.people,
                            '${property.candidaturesEnAttente}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                    style: const TextStyle(color: Colors.blue),
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
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        StringExtension(property.typeLogement).capitalize(),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        property.meuble ? Icons.chair : Icons.chair_outlined,
                        size: 16,
                        color: Colors.grey[600],
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

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white)),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: _addNewProperty,
            tooltip: 'Add New Property',
          ),
        ],
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
                      onPressed: () => _fetchUserProperties(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
              : _properties.isEmpty
              ? const Center(
                child: Text('Vous n\'avez pas encore de propriétés'),
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
                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ),
                  if (!_isLoadingMore) _buildPaginationControls(),
                ],
              ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
