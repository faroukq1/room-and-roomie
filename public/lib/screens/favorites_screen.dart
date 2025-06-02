import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';

class FavoriteProperty {
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
  final DateTime favorisDate;
  final Map<String, dynamic> proprietaire;

  FavoriteProperty.fromJson(Map<String, dynamic> json)
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
      favorisDate = DateTime.parse(json['favoris_date']),
      proprietaire = json['proprietaire'];
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _currentIndex = 1;
  final storage = const FlutterSecureStorage();
  List<FavoriteProperty> _favorites = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      final userData = await storage.read(key: 'user_data');

      if (token == null || userData == null) {
        setState(() {
          _errorMessage = 'Veuillez vous connecter pour voir vos favoris';
          _isLoading = false;
        });
        return;
      }

      // Parse user data to get ID
      final user = jsonDecode(userData);
      final userId = user['id'];

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/logements/favorites/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _favorites =
              data.map((item) => FavoriteProperty.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des favoris';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur';
        _isLoading = false;
      });
      print('Error fetching favorites: $e');
    }
  }

  Future<void> _removeFavorite(int propertyId) async {
    try {
      final token = await storage.read(key: 'auth_token');
      final userDataStr = await storage.read(key: 'user_data');

      if (token == null || userDataStr == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez vous connecter pour gérer vos favoris'),
          ),
        );
        return;
      }

      print('Removing favorite for property ID: $propertyId');

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:3000/api/logements/favorites/$propertyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _favorites.removeWhere((property) => property.id == propertyId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Retiré des favoris')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la suppression: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error removing favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la suppression du favori'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCDEF9),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Favoris',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchFavorites,
                  ),
                ],
              ),
            ),

            // Favorites content
            Expanded(
              child:
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
                              onPressed: _fetchFavorites,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                      : _favorites.isEmpty
                      ? const Center(
                        child: Text(
                          'Aucun favori pour le moment',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          final property = _favorites[index];
                          return _buildFavoriteItem(property);
                        },
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
      ),
    );
  }

  Widget _buildFavoriteItem(FavoriteProperty property) {
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
      'images': [_getPlaceholderImage(property.id)],
      'type': property.typeLogement,
      'bedrooms': property.nombrePieces.toString(),
      'area': property.superficie,
      'code_postal': property.codePostal,
      'charges_incluses': property.chargesIncluses,
      'meuble': property.meuble,
      'capacite_max_colocataires': property.capaciteMaxColocataires,
      'proprietaire': property.proprietaire,
      'isFavorite': true,
    };

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailPage(property: propertyData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Property Type Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Icon(
                property.typeLogement == 'maison'
                    ? Icons.house
                    : Icons.apartment,
                size: 40,
                color: Colors.grey[600],
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.titre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${property.loyer.toStringAsFixed(2)} DA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${property.nombrePieces} pièces • ${property.superficie} m²',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      property.ville,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            // Favorite icon
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () => _removeFavorite(property.id),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (index == 1) {
          setState(() => _currentIndex = index);
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
}
