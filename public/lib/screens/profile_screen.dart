import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'privacy_policy_screen.dart';
import 'settings_screen.dart';
import 'ProprietaireDashboard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3;
  String? _name;
  String? _email;
  String? _avatarUrl;
  int? _properties;
  int? _favorites;
  String _storageData = 'Loading...';
  final storage = FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:3000/api';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      String? userDataJson = await storage.read(key: 'user_data');
      String? token = await storage.read(key: 'auth_token');

      StringBuffer buffer = StringBuffer();
      buffer.writeln('auth_token: $token');
      if (userDataJson != null) {
        buffer.writeln('user_data: $userDataJson');
      }

      int userId = 0;
      Map<String, dynamic>? userData;
      if (userDataJson != null) {
        userData = jsonDecode(userDataJson);
        userId = userData?['id'] ?? 0;
      }

      Map<String, dynamic>? stats;
      if (token != null && userId != 0) {
        final response = await http.get(
          Uri.parse('$baseUrl/stats/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          stats = jsonDecode(response.body);
        } else {
          buffer.writeln(
            'Failed to fetch stats: ${response.statusCode} ${response.body}',
          );
        }
      }

      setState(() {
        if (stats != null) {
          _name = stats['name'] ?? 'Unknown User';
          _email = stats['email'] ?? 'No email';
          _avatarUrl = stats['avatar_url'];
          _properties = stats['properties'] ?? 0;
          _favorites = stats['favorites'] ?? 0;
        } else if (userData != null) {
          _name = userData['nom'] ?? 'Unknown User';
          _email = userData['email'] ?? 'No email';
          _avatarUrl = null;
          _properties = 0;
          _favorites = 0;
        } else {
          _name = 'Unknown User';
          _email = 'No email';
          _avatarUrl = null;
          _properties = 0;
          _favorites = 0;
        }
        _storageData =
            buffer.isEmpty ? 'No data in storage' : buffer.toString();
      });
    } catch (e) {
      setState(() {
        _storageData = 'Error loading storage data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCDEF9),
      body: SafeArea(
        child: Column(
          children: [
            // Profile header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar and edit button
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : null,
                        child:
                            _avatarUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            // Implement edit functionality
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // User name
                  Text(
                    _name ?? 'Loading...',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Text(
                    _email ?? 'Loading...',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildStat(
                          'Propriétés',
                          _properties?.toString() ?? '0',
                        ),
                      ),
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                      Expanded(
                        child: _buildStat(
                          'Favoris',
                          _favorites?.toString() ?? '0',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16)),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildMenuItem(Icons.dashboard, 'Dashboard', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProprietaireDashboard(),
                      ),
                    );
                  }),
                  _buildMenuItem(Icons.settings, 'Paramètres', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  }),
                  _buildMenuItem(
                    Icons.privacy_tip_outlined,
                    'Confidentialité',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildMenuItem(Icons.logout, 'Déconnexion', () async {
                    await storage.deleteAll();
                    Navigator.pushReplacementNamed(context, '/welcome');
                  }, isRed: true),
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
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isRed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: isRed ? Colors.red : Colors.blue),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isRed ? Colors.red : Colors.black,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/favorites');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/inbox');
        } else if (index == 3) {
          setState(() {
            _currentIndex = index;
          });
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
