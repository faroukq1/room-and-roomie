import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'edit_property_screen.dart';

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

  Future<void> _deleteProperty(int propertyId) async {
    print('Deleting property with ID: $propertyId');
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette propriété ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/logements/$propertyId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propriété supprimée avec succès')),
        );
        // Refresh your property list after deletion
        _fetchUserProperties();
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Propriété non trouvée')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la suppression : ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion au serveur : $e')),
      );
    }
  }

  void _editProperty(int propertyId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPropertyScreen(propertyId: propertyId),
      ),
    );
    if (result == true) {
      _fetchUserProperties();
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
                      top: -5,
                      left: 0,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Supprimer cette annonce',
                        onPressed: () => _deleteProperty(property.id),
                      ),
                    ),
                    Positioned(
                      top: -5,
                      left: 40,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Modifier cette annonce',
                        onPressed: () => _editProperty(property.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.titre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${property.nombrePieces} pièce${property.nombrePieces != 1 ? 's' : ''} • ${property.superficie} m²',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${property.adresse}, ${property.ville} ${property.codePostal}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loyer: ${property.loyer} €${property.chargesIncluses ? ' (charges incluses)' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Disponible à partir du: ${property.disponibleAPartir.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(label: Text('Favoris: ${property.nombreFavoris}')),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          'Candidatures en attente: ${property.candidaturesEnAttente}',
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes propriétés')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              )
              : _properties.isEmpty
              ? Center(
                child: Text(
                  'Vous n\'avez pas encore publié d\'annonces.\nAppuyez sur le bouton "+" pour en ajouter.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  _currentPage = 1;
                  await _fetchUserProperties();
                },
                child: ListView.builder(
                  itemCount: _properties.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _properties.length) {
                      return _buildPaginationControls();
                    }
                    final property = _properties[index];
                    return _buildPropertyCard(property);
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProperty,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PropertyDetailPage extends StatelessWidget {
  final Map<String, dynamic> property;
  const PropertyDetailPage({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    // Implement your property details page here
    return Scaffold(
      appBar: AppBar(
        title: Text(property['title'] ?? 'Détails de la propriété'),
      ),
      body: Center(child: Text('Détails complets ici...')),
    );
  }
}
