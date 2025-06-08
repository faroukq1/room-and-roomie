import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'paymentpage.dart';
import 'widgets/apply_coloc_dialog.dart';

// Coloc Model
class ColocModel {
  final int userId;
  final String nom;
  final String prenom;
  final String photoProfil;
  final String userVille;
  final String sexe;
  final DateTime? dateEntree;
  final DateTime? dateSortie;
  final int logementId;
  final String logementTitre;
  final String logementVille;
  final double loyer;
  final String typeLogement;
  final DateTime disponibleAPartir;
  final double superficie;
  final int nombrePieces;
  final bool meuble;
  final int colocationId;

  ColocModel({
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.photoProfil,
    required this.userVille,
    required this.sexe,
    this.dateEntree,
    this.dateSortie,
    required this.logementId,
    required this.logementTitre,
    required this.logementVille,
    required this.loyer,
    required this.typeLogement,
    required this.disponibleAPartir,
    required this.superficie,
    required this.nombrePieces,
    required this.meuble,
    required this.colocationId,
  });

  factory ColocModel.fromJson(Map<String, dynamic> json) {
    try {
      return ColocModel(
        userId: json['user_id'] ?? 0,
        nom: json['nom'] ?? '',
        prenom: json['prenom'] ?? '',
        photoProfil: json['photo_profil'] ?? '',
        userVille: json['user_ville'] ?? '',
        sexe: json['sexe'] ?? '',
        dateEntree:
            json['date_entree'] != null
                ? DateTime.parse(json['date_entree'])
                : null,
        dateSortie:
            json['date_sortie'] != null
                ? DateTime.parse(json['date_sortie'])
                : null,
        logementId: json['logement_id'] ?? 0,
        logementTitre: json['logement_titre'] ?? '',
        logementVille: json['logement_ville'] ?? '',
        loyer: double.parse((json['loyer'] ?? '0').toString()),
        typeLogement: json['type_logement'] ?? '',
        disponibleAPartir: DateTime.parse(
          json['disponible_a_partir'] ?? DateTime.now().toIso8601String(),
        ),
        superficie: double.parse((json['superficie'] ?? '0').toString()),
        nombrePieces: json['nombre_pieces'] ?? 0,
        meuble: json['meuble'] ?? false,
        colocationId: json['colocation_id'] ?? 0,
      );
    } catch (e, stackTrace) {
      print('Error creating ColocModel: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String baseUrl = "http://10.0.2.2:3000";
  final storage = const FlutterSecureStorage();
  int _currentIndex = 0;
  bool _showLogs = true;
  bool _showLocationSearch = false;
  bool _showPropertyList = false;
  String _selectedLocation = '';
  final TextEditingController _searchController = TextEditingController();

  // Pagination state for properties
  int _currentPage = 1;
  final int _limit = 5;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  // Pagination state for colocs
  int _currentColocsPage = 1;
  final int _colocsLimit = 5;
  bool _hasMoreColocsPages = true;
  bool _isLoadingMoreColocs = false;

  // Filter state variables
  String _currentPropertyType = 'Résidentielle';
  String _currentPropertySubType = '';
  String _currentBedrooms = '';
  RangeValues _currentPriceRange = const RangeValues(0, 100000);
  RangeValues _currentAreaRange = const RangeValues(0, 500);

  // API data
  List<Map<String, dynamic>> _properties = [];
  List<ColocModel> _colocs = [];
  bool _isLoading = true;
  bool _isLoadingColocs = true;
  String? _errorMessage;
  String? _errorMessageColocs;

  // Placeholder image URLs
  final List<String> _imageUrls = [
    'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6?ixlib=rb-4.0.3',
    'https://images.unsplash.com/photo-1554995207-c18c203602cb?ixlib=rb-4.0.3',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3',
    'https://images.unsplash.com/photo-1565183997392-2f6f122e5912?ixlib=rb-4.0.3',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProperties();
    _fetchColocs();
    _fetchFavorites();
    _searchController.addListener(() {
      setState(() {
        _showLocationSearch = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProperties() async {
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
      final response = await http.get(
        Uri.parse('$baseUrl/api/logements?page=$_currentPage&limit=$_limit'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // Extract properties from logements array
        final List<dynamic> properties = responseData['logements'] ?? [];

        // Extract pagination info
        final Map<String, dynamic> pagination = responseData['pagination'];
        final bool hasNextPage = pagination['hasNextPage'] ?? false;
        final int totalPages = pagination['totalPages'] ?? 1;
        final int currentPage = pagination['currentPage'] ?? 1;
        final newProperties =
            properties
                .map(
                  (item) => {
                    'id': item['id'],
                    'title': item['titre'],
                    'price': double.parse(item['loyer'].toString()),
                    'details':
                        '${item['nombre_pieces']} pièce${item['nombre_pieces'] != 1 ? 's' : ''} / ${item['superficie']} m²',
                    'location': '${item['adresse']}, ${item['ville']}',
                    'type': item['type_logement'].toString().capitalize(),
                    'bedrooms': item['nombre_pieces'].toString(),
                    'area': double.parse(item['superficie'].toString()),
                    'images': [_imageUrls[item['id'] % _imageUrls.length]],
                    'description': item['description'],
                    'disponible_a_partir': item['disponible_a_partir'],
                    'est_actif': item['est_actif'],
                    'isFavorite': false,
                    'code_postal': item['code_postal'],
                    'charges_incluses': item['charges_incluses'],
                    'meuble': item['meuble'],
                    'capacite_max_colocataires':
                        item['capacite_max_colocataires'],
                    'proprietaire': item['proprietaire'],
                  },
                )
                .toList();

        setState(() {
          // Always replace the properties with new ones
          _properties = newProperties;
          _hasMorePages = hasNextPage;
          _currentPage = currentPage;
          _isLoading = false;
          _isLoadingMore = false;
        });

        // Fetch favorites after properties are loaded
        _fetchFavorites();
      } else {
        setState(() {
          _errorMessage = 'Failed to load properties: ${response.statusCode}';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching properties: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _fetchColocs() async {
    if (_currentColocsPage == 1) {
      setState(() {
        _isLoadingColocs = true;
        _errorMessageColocs = null;
      });
    } else {
      setState(() {
        _isLoadingMoreColocs = true;
      });
    }

    try {
      final token = await storage.read(key: 'auth_token');
      final userData = await storage.read(key: 'user_data');

      if (token == null || userData == null) {
        setState(() {
          _errorMessageColocs = 'Non authentifié. Veuillez vous connecter.';
          _isLoadingColocs = false;
          _isLoadingMoreColocs = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/colocs?page=$_currentColocsPage&limit=$_colocsLimit',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Extract colocs data using the correct key 'colocataires'
        final List<dynamic> colocs = responseData['colocataires'] ?? [];

        // Extract pagination info
        final Map<String, dynamic> pagination = responseData['pagination'];
        final bool hasNextPage = pagination['hasNextPage'] ?? false;
        final int totalPages = pagination['totalPages'] ?? 1;
        final int currentPage = pagination['currentPage'] ?? 1;

        final List<ColocModel> newColocs =
            colocs.map<ColocModel>((item) {
              return ColocModel.fromJson(item);
            }).toList();

        setState(() {
          _colocs = newColocs;
          _hasMoreColocsPages = hasNextPage;
          _currentColocsPage = currentPage;
          _isLoadingColocs = false;
          _isLoadingMoreColocs = false;
        });
      } else {
        setState(() {
          _errorMessageColocs = 'Failed to load colocs: ${response.statusCode}';
          _isLoadingColocs = false;
          _isLoadingMoreColocs = false;
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _errorMessageColocs = 'Error fetching colocs: $e';
        _isLoadingColocs = false;
        _isLoadingMoreColocs = false;
      });
    }
  }

  Future<void> _fetchFavorites() async {
    try {
      final token = await storage.read(key: 'auth_token');
      final userDataStr = await storage.read(key: 'user_data');

      if (token == null || userDataStr == null) {
        return; // Silent return as user might not be logged in
      }

      final userData = jsonDecode(userDataStr);
      final userId = userData['id'];

      final response = await http.get(
        Uri.parse('$baseUrl/api/logements/favorites/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> favorites = jsonDecode(response.body);
        setState(() {
          // Update isFavorite status for each property
          for (var property in _properties) {
            property['isFavorite'] = favorites.any(
              (fav) => fav['logement_id'] == property['id'],
            );
          }
        });
      }
    } catch (e) {}
  }

  Future<void> _toggleFavorite(int logementId) async {
    try {
      final token = await storage.read(key: 'auth_token');
      final userDataStr = await storage.read(key: 'user_data');

      if (token == null || userDataStr == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez vous connecter pour ajouter aux favoris'),
          ),
        );
        return;
      }

      // Parse user data to get ID
      final userData = jsonDecode(userDataStr);
      final userId = userData['id'];
      final response = await http.post(
        Uri.parse('$baseUrl/api/logements/favorites/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'logementId': logementId, 'userId': userId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          final propertyIndex = _properties.indexWhere(
            (p) => p['id'] == logementId,
          );
          if (propertyIndex != -1) {
            _properties[propertyIndex]['isFavorite'] = true;
          }
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ajouté aux favoris')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'ajout aux favoris: ${response.statusCode} - ${response.body}',
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => PropertyFilterBottomSheet(
            onApplyFilters: (filters) {
              setState(() {
                _currentPropertyType = filters['propertyType'] as String;
                _currentPropertySubType = filters['propertySubType'] as String;
                _currentBedrooms = filters['bedrooms'] as String;
                _currentPriceRange = filters['priceRange'] as RangeValues;
                _currentAreaRange = filters['areaRange'] as RangeValues;
              });
            },
          ),
    );
  }

  List<Map<String, dynamic>> _getFilteredProperties() {
    return _properties.where((property) {
      // Location filter
      if (_selectedLocation.isNotEmpty &&
          !property['location'].toString().toLowerCase().contains(
            _selectedLocation.toLowerCase(),
          )) {
        return false;
      }
      // Property type filter
      if (_currentPropertyType == 'Résidentielle' &&
          _currentPropertySubType.isNotEmpty &&
          _currentPropertySubType.toLowerCase() !=
              property['type'].toString().toLowerCase()) {
        return false;
      }
      // Price filter
      if (property['price'] < _currentPriceRange.start ||
          property['price'] > _currentPriceRange.end) {
        return false;
      }
      // Bedrooms filter
      if (_currentBedrooms.isNotEmpty &&
          _currentBedrooms != property['bedrooms']) {
        return false;
      }
      // Area filter
      if (property['area'] < _currentAreaRange.start ||
          property['area'] > _currentAreaRange.end) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildPersonCard(ColocModel coloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.network(
                      coloc.photoProfil,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 40),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${coloc.prenom} ${coloc.nom}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Propose ${coloc.typeLogement}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              coloc.logementVille,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
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
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Budget',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${coloc.loyer.toStringAsFixed(2)} DA',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Disponibilité',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            coloc.disponibleAPartir.toString().split(' ')[0],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    coloc.logementTitre,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          () =>
                              Navigator.pushReplacementNamed(context, '/inbox'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Contacter'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailPage(property: property),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        property['images'][0],
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Text('Image non disponible'),
                              ),
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          property['isFavorite'] == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              property['isFavorite'] == true
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                        onPressed: () {
                          if (property['id'] == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Erreur: ID du logement non trouvé',
                                ),
                              ),
                            );
                            return;
                          }
                          _toggleFavorite(property['id']);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            property['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${property['price'].toStringAsFixed(2)} DA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      property['details'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property['location'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PropertyDetailPage(property: property),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Voir détails'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCDEF9),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Search bar with filter button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  _showLogs
                                      ? 'Rechercher un lieu...'
                                      : 'Rechercher un colocataire...',
                              border: InputBorder.none,
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.grey,
                          ),
                          onPressed: _showFilterBottomSheet,
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _showLogs = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _showLogs ? Colors.blue : Colors.white,
                            foregroundColor:
                                _showLogs ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Logs',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _showLogs = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                !_showLogs ? Colors.blue : Colors.white,
                            foregroundColor:
                                !_showLogs ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Colocs',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child:
                      _showLogs
                          ? _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _errorMessage != null
                              ? Center(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                              : _getFilteredProperties().isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.home_work_outlined,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucune propriété disponible${_selectedLocation.isNotEmpty ? ' à $_selectedLocation' : ''}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchProperties,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Réessayer'),
                                    ),
                                  ],
                                ),
                              )
                              : _buildPropertyList()
                          : _isLoadingColocs
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessageColocs != null
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _errorMessageColocs!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentColocsPage = 1;
                                    });
                                    _fetchColocs();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          )
                          : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _colocs.length,
                                  itemBuilder:
                                      (context, index) =>
                                          _buildPersonCard(_colocs[index]),
                                ),
                              ),
                              if (!_isLoadingMoreColocs)
                                _buildColocsPaginationControls(),
                              if (_isLoadingMoreColocs)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            ],
                          ),
                ),

                // Bottom Navigation Bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home, 'Home'),
                      _buildNavItem(1, Icons.favorite_border, 'Favoris'),
                      _buildNavItem(2, Icons.article_outlined, 'Inbox'),
                      _buildNavItem(3, Icons.person_outline, 'Profile'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == 0) {
          setState(() => _currentIndex = index);
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/favorites');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/inbox');
        } else if (index == 3) {
          Navigator.pushReplacementNamed(context, '/profile');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.black : Colors.grey),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColocsPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed:
                _currentColocsPage > 1
                    ? () async {
                      setState(() {
                        _currentColocsPage--;
                      });
                      await _fetchColocs();
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
              'Page $_currentColocsPage',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed:
                _hasMoreColocsPages
                    ? () async {
                      setState(() {
                        _currentColocsPage++;
                      });
                      await _fetchColocs();
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

  Widget _buildPropertyList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentPage = 1;
                });
                _fetchProperties();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final filteredProperties = _getFilteredProperties();

    if (filteredProperties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_work_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucune propriété disponible${_selectedLocation.isNotEmpty ? ' à $_selectedLocation' : ''}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: filteredProperties.length,
            itemBuilder:
                (context, index) =>
                    _buildPropertyCard(filteredProperties[index]),
          ),
        ),
        if (!_isLoadingMore) _buildPaginationControls(),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
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
                      await _fetchProperties();
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
                      await _fetchProperties();
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
}

class PropertyDetailPage extends StatefulWidget {
  final Map<String, dynamic> property;

  const PropertyDetailPage({super.key, required this.property});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  bool _isApplying = false;
  bool _hasApplied = false;
  int? _userId;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkIfAppliedOrOwner();
  }

  Future<void> _checkIfAppliedOrOwner() async {
    final storage = const FlutterSecureStorage();
    final userDataStr = await storage.read(key: 'user_data');
    if (userDataStr != null) {
      final userData = jsonDecode(userDataStr);
      setState(() {
        _userId = userData['id'];
        _isOwner =
            widget.property['proprietaire'] != null &&
            widget.property['proprietaire']['id'] == userData['id'];
      });
      // Check if already applied
      if (widget.property['candidatures'] != null && _userId != null) {
        final List<dynamic> candidatures = widget.property['candidatures'];
        final applied = candidatures.any(
          (c) =>
              c['locataire_id'] == _userId &&
              (c['statut'] == 'en_attente' || c['statut'] == 'acceptee'),
        );
        setState(() {
          _hasApplied = applied;
        });
      }
    }
  }

  void _showApplyDialog() {
    showDialog(
      context: context,
      builder:
          (context) => ApplyColocDialog(
            isLoading: _isApplying,
            onSubmit: (msg) {
              Navigator.pop(context);
              _applyForColoc(msg);
            },
          ),
    );
  }

  Future<void> _applyForColoc(String message) async {
    setState(() => _isApplying = true);
    final storage = const FlutterSecureStorage();
    final userDataStr = await storage.read(key: 'user_data');
    int? userId;
    if (userDataStr != null) {
      final userData = jsonDecode(userDataStr);
      userId = userData['id'];
    }
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté.')),
      );
      setState(() => _isApplying = false);
      return;
    }
    final url = Uri.parse('http://10.0.2.2:3000/api/colocs/candidature');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'logement_id': widget.property['id'],
          'locataire_id': userId,
          'message': message,
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Candidature envoyée !')));
        setState(() {
          _hasApplied = true;
        });
      } else {
        final err = jsonDecode(response.body)['error'] ?? response.body;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $err')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau ou serveur.')),
      );
    }
    setState(() => _isApplying = false);
  }

  void _buyProperty(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer l\'achat'),
            content: Text(
              'Voulez-vous acheter la propriété "${widget.property['title']}" pour ${widget.property['price'].toStringAsFixed(2)} DA ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Achat de "${widget.property['title']}" en cours...',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Confirmer'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proprietaire =
        widget.property['proprietaire'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(title: Text(widget.property['title'] ?? 'Propriété')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                (widget.property['images'] != null &&
                        widget.property['images'].isNotEmpty)
                    ? widget.property['images'][0]
                    : 'https://via.placeholder.com/400',
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
                    widget.property['title'] ?? 'Sans titre',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${(widget.property['price'] ?? 0.0).toStringAsFixed(2)} DA',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.property['charges_incluses'] == true)
                        Text(
                          ' (charges incluses)',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.property['location'] ?? 'Non spécifié',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  Text(
                    'Code Postal: ${widget.property['code_postal'] ?? 'Non spécifié'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Caractéristiques',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.property['details'] ?? 'Non spécifié',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  Text(
                    'Type: ${widget.property['type'] ?? 'Non spécifié'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  Text(
                    'Meublé: ${widget.property['meuble'] == true ? 'Oui' : 'Non'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  Text(
                    'Capacité max. colocataires: ${widget.property['capacite_max_colocataires'] ?? 0}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.property['description'] ?? 'Aucune description',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Propriétaire',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${proprietaire['prenom'] ?? 'Inconnu'} ${proprietaire['nom'] ?? ''}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Tél: ${proprietaire['telephone'] ?? 'Non spécifié'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Email: ${proprietaire['email'] ?? 'Non spécifié'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Disponible à partir du: ${widget.property['disponible_a_partir']?.toString().split('T')[0] ?? 'Non spécifié'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _isOwner
                                  ? null
                                  : () {
                                    // Place your contact logic here (e.g., open chat, send request, etc.)
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isOwner ? Colors.grey : Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child:
                              _hasApplied
                                  ? const Text('Candidature envoyée')
                                  : _isApplying
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    _isOwner ? 'ma colocation' : 'Contacter',
                                  ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _isOwner || _hasApplied || _isApplying
                                  ? null
                                  : _showApplyDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child:
                              _isOwner
                                  ? const Text('ma propriété')
                                  : _hasApplied
                                  ? const Text('Candidature envoyée')
                                  : _isApplying
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text('rejoindre'),
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
}

class PropertyFilterBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>)? onApplyFilters;

  const PropertyFilterBottomSheet({super.key, this.onApplyFilters});

  @override
  State<PropertyFilterBottomSheet> createState() =>
      _PropertyFilterBottomSheetState();
}

class _PropertyFilterBottomSheetState extends State<PropertyFilterBottomSheet> {
  String _propertyType = 'Résidentielle';
  String _propertySubType = '';
  RangeValues _priceRange = const RangeValues(0, 100000);
  String _selectedBedrooms = '';
  RangeValues _areaRange = const RangeValues(0, 500);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
                const Text(
                  'Filtres',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap:
                      () => setState(() {
                        _propertyType = 'Résidentielle';
                        _propertySubType = '';
                        _priceRange = const RangeValues(0, 100000);
                        _selectedBedrooms = '';
                        _areaRange = const RangeValues(0, 500);
                      }),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Text(
                      'Type de propriété',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildTypeButton(
                              'Résidentielle',
                              isSelected: _propertyType == 'Résidentielle',
                            ),
                            _buildTypeButton(
                              'Commercial',
                              isSelected: _propertyType == 'Commercial',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_propertyType == 'Résidentielle')
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSubTypeButton(
                                'Appartement',
                                isSelected: _propertySubType == 'Appartement',
                              ),
                              _buildSubTypeButton(
                                'Maison',
                                isSelected: _propertySubType == 'Maison',
                              ),
                              _buildSubTypeButton(
                                'Studio',
                                isSelected: _propertySubType == 'Studio',
                              ),
                              _buildSubTypeButton(
                                'Chambre',
                                isSelected: _propertySubType == 'Chambre',
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'Prix',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_priceRange.start.round()} DA',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_priceRange.end.round()} DA',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 100000,
                      divisions: 10,
                      labels: RangeLabels(
                        '${_priceRange.start.round()} DA',
                        '${_priceRange.end.round()} DA',
                      ),
                      onChanged:
                          (values) => setState(() => _priceRange = values),
                    ),
                  ),
                  const Divider(height: 24),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'Chambres',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ), // Fixed this line
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _buildBedButton('Studio'),
                        _buildBedButton('1'),
                        _buildBedButton('2'),
                        _buildBedButton('3'),
                        _buildBedButton('4'),
                        _buildBedButton('5'),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ... (previous widgets: Type de propriété, Prix, Chambres)
                      const Divider(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: const Text(
                          'Superficie',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_areaRange.start.round()} m²',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_areaRange.end.round()} m²',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: RangeSlider(
                          values: _areaRange,
                          min: 0,
                          max: 500,
                          divisions: 20,
                          labels: RangeLabels(
                            '${_areaRange.start.round()} m²',
                            '${_areaRange.end.round()} m²',
                          ),
                          onChanged:
                              (values) => setState(() => _areaRange = values),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ... (remaining widgets)
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RangeSlider(
                      values: _areaRange,
                      min: 0,
                      max: 500,
                      divisions: 20,
                      labels: RangeLabels(
                        '${_areaRange.start.round()} m²',
                        '${_areaRange.end.round()} m²',
                      ),
                      onChanged:
                          (values) => setState(() => _areaRange = values),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                final filters = {
                  'propertyType': _propertyType,
                  'propertySubType': _propertySubType,
                  'priceRange': _priceRange,
                  'bedrooms': _selectedBedrooms,
                  'areaRange': _areaRange,
                };
                if (widget.onApplyFilters != null) {
                  widget.onApplyFilters!(filters);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Chercher',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, {required bool isSelected}) {
    return GestureDetector(
      onTap:
          () => setState(() {
            _propertyType = label;
            _propertySubType = '';
          }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildSubTypeButton(String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () => setState(() => _propertySubType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildBedButton(String count) {
    final isSelected = _selectedBedrooms == count;
    return GestureDetector(
      onTap: () => setState(() => _selectedBedrooms = count),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          count,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
