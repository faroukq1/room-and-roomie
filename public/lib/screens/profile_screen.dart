import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'privacy_policy_screen.dart';
import 'settings_screen.dart';
import 'ProprietaireDashboard.dart';
import 'notification_screen.dart';
import '../constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  int _currentIndex = 3;
  String? _name;
  String? _email;
  String? _avatarUrl;
  int? _properties;
  int? _favorites;
  String _storageData = 'Loading...';
  final storage = const FlutterSecureStorage();

  // Helper to ensure avatar URL is always a server URL, not a file path
  String _getAvatarUrl(String url) {
    if (url.startsWith('http')) return url;
    // If it's a local path, extract filename and build server URL
    final RegExp fileNameReg = RegExp(r'[/\\]([\w\-\.]+)$');
    final match = fileNameReg.firstMatch(url);
    if (match != null) {
      final fileName = match.group(1);
      return '$baseUrl/downloads/$fileName';
    }
    return url;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes properly
    if (state == AppLifecycleState.resumed) {
      // Dismiss any open keyboards when returning to the app
      FocusScope.of(context).unfocus();
    }
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

      int propertiesCount = 0;
      int favoritesCount = 0;
      String? name;
      String? email;
      String? avatarUrl;

      if (token != null && userId != 0) {
        try {
          // Fetch properties count
          final propertiesResponse = await http
              .get(
                Uri.parse('$baseUrl/api/utilisateurs/$userId/logements'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              )
              .timeout(const Duration(seconds: 10));

          if (propertiesResponse.statusCode == 200) {
            final propertiesData = jsonDecode(propertiesResponse.body);
            final List<dynamic> properties = propertiesData['logements'] ?? [];
            propertiesCount = properties.length;
          }

          // Fetch favorites count
          final favoritesResponse = await http
              .get(
                Uri.parse('$baseUrl/api/logements/favorites/$userId'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              )
              .timeout(const Duration(seconds: 10));

          if (favoritesResponse.statusCode == 200) {
            final favoritesData = jsonDecode(favoritesResponse.body);
            if (favoritesData is List) {
              favoritesCount = favoritesData.length;
            }
          }
        } catch (e) {
          // If either API fails, leave counts as 0
          debugPrint('Error loading user stats: $e');
        }

        // Use userData for name/email/avatar
        if (userData != null) {
          name = userData['nom'] ?? 'Unknown User';
          email = userData['email'] ?? 'No email';
          avatarUrl = userData['avatar_url'];
        }
      }

      if (mounted) {
        setState(() {
          _name = name ?? userData?['nom'] ?? 'Unknown User';
          _email = email ?? userData?['email'] ?? 'No email';
          _avatarUrl = avatarUrl ?? userData?['avatar_url'];
          _properties = propertiesCount;
          _favorites = favoritesCount;
          _storageData =
              buffer.isEmpty ? 'No data in storage' : buffer.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _storageData = 'Error loading storage data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // Properly handle back navigation
        if (didPop) {
          // Dismiss keyboard if open
          FocusScope.of(context).unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      },
      child: Scaffold(
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
                    // Top row with notification bell
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none,
                            color: Colors.blueAccent,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => const NotificationScreen(),
                              ),
                            );
                          },
                          tooltip: 'Notifications',
                        ),
                      ],
                    ),
                    // Avatar and edit button
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? NetworkImage(_getAvatarUrl(_avatarUrl!))
                                  : null,
                          child:
                              _avatarUrl == null || _avatarUrl!.isEmpty
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
                            icon:
                                _isUploading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            onPressed:
                                _isUploading ? null : _pickAndUploadImage,
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
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: _buildStat(
                            'Favoris',
                            _favorites?.toString() ?? '0',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Menu items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    _buildMenuItem(Icons.dashboard, 'Dashboard', () {
                      _navigateToScreen(() => const ProprietaireDashboard());
                    }),
                    _buildMenuItem(Icons.settings, 'Paramètres', () {
                      _navigateToScreen(() => const SettingsScreen());
                    }),
                    _buildMenuItem(
                      Icons.privacy_tip_outlined,
                      'Confidentialité',
                      () {
                        _navigateToScreen(() => const PrivacyPolicyScreen());
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildMenuItem(Icons.logout, 'Déconnexion', () async {
                      await _handleLogout();
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
        borderRadius: BorderRadius.circular(10),
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
      onTap: () => _handleNavigation(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      ),
    );
  }

  void _handleNavigation(int index) {
    // Dismiss keyboard before navigation
    FocusScope.of(context).unfocus();

    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/favorites');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/inbox');
        break;
      case 3:
        // Already on profile screen
        break;
    }
  }

  void _navigateToScreen(Widget Function() screenBuilder) {
    // Dismiss keyboard before navigation
    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screenBuilder()),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Déconnexion',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        // Dismiss keyboard
        FocusScope.of(context).unfocus();

        // Clear storage
        await storage.deleteAll();

        // Navigate to welcome screen
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/welcome',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
          );
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      // Dismiss keyboard first
      FocusScope.of(context).unfocus();

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      setState(() {
        _isUploading = true;
      });

      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      // Use correct endpoint (should match backend: /api/user/upload-picture)
      // Use new backend endpoint with userId in URL
      String? userDataJson = await storage.read(key: 'user_data');
      int? userId;
      if (userDataJson != null) {
        Map<String, dynamic> userData = jsonDecode(userDataJson);
        if (userData['id'] != null) {
          userId = userData['id'];
        }
      }
      if (userId == null) {
        throw Exception('User ID manquant dans le stockage local.');
      }
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/utilisateurs/upload-picture/$userId'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('picture', pickedFile.path),
      );

      var response = await request.send().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final respJson = jsonDecode(respStr);

        // Update avatar URL if returned by backend
        String? newAvatarUrl;
        if (respJson['url'] != null &&
            respJson['url'].toString().startsWith('http')) {
          newAvatarUrl = respJson['url'];
        } else if (respJson['filename'] != null) {
          newAvatarUrl = '$baseUrl/downloads/${respJson['filename']}';
          print("Avatar URL from filename: $newAvatarUrl");
        } else if (respJson['avatar_url'] != null &&
            respJson['avatar_url'].toString().startsWith('http')) {
          newAvatarUrl = respJson['avatar_url'];
        }
        if (newAvatarUrl != null && mounted) {
          setState(() {
            _avatarUrl = newAvatarUrl;
          });
          print("Avatar URL updated: $newAvatarUrl");
          // Update stored user data
          String? userDataJson = await storage.read(key: 'user_data');
          if (userDataJson != null) {
            Map<String, dynamic> userData = jsonDecode(userDataJson);
            userData['avatar_url'] = newAvatarUrl;
            await storage.write(key: 'user_data', value: jsonEncode(userData));
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo de profil mise à jour!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Échec du téléchargement: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
