import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final storage = const FlutterSecureStorage();
  bool _isLoading = true;
  String? _errorMessage;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _showPassword = false;
  bool _showNewPassword = false;

  // Form controllers
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _villeController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  DateTime? _dateNaissance;
  String? _sexe;
  String? _currentPhotoUrl;
  final _formKey = GlobalKey<FormState>();

  // Add variables to store original values
  String _originalNom = '';
  String _originalPrenom = '';
  String _originalEmail = '';
  String _originalTelephone = '';
  String _originalVille = '';
  DateTime? _originalDateNaissance;
  String? _originalSexe;
  String? _originalPhotoUrl;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Add listeners to all text controllers to detect changes
    _nomController.addListener(_checkForChanges);
    _prenomController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _telephoneController.addListener(_checkForChanges);
    _villeController.addListener(_checkForChanges);
    _newPasswordController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    // Remove listeners
    _nomController.removeListener(_checkForChanges);
    _prenomController.removeListener(_checkForChanges);
    _emailController.removeListener(_checkForChanges);
    _telephoneController.removeListener(_checkForChanges);
    _villeController.removeListener(_checkForChanges);
    _newPasswordController.removeListener(_checkForChanges);

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    bool hasChanges = false;

    // Check each field for changes, but only if they're not empty
    if (_nomController.text.isNotEmpty && _nomController.text != _originalNom) {
      hasChanges = true;
    }
    if (_prenomController.text.isNotEmpty &&
        _prenomController.text != _originalPrenom) {
      hasChanges = true;
    }
    if (_emailController.text.isNotEmpty &&
        _emailController.text != _originalEmail) {
      hasChanges = true;
    }
    if (_telephoneController.text != _originalTelephone) {
      hasChanges = true;
    }
    if (_villeController.text != _originalVille) {
      hasChanges = true;
    }

    // Check date change - compare dates properly
    bool dateChanged = false;
    if (_dateNaissance != null && _originalDateNaissance != null) {
      dateChanged = !_isSameDay(_dateNaissance!, _originalDateNaissance!);
    } else if (_dateNaissance != _originalDateNaissance) {
      dateChanged = true;
    }
    if (dateChanged) {
      hasChanges = true;
    }

    // Check sex change
    if (_sexe != _originalSexe) {
      hasChanges = true;
    }

    if (_imageFile != null) {
      hasChanges = true;
    }
    if (_newPasswordController.text.isNotEmpty) {
      hasChanges = true;
    }

    setState(() {
      _hasChanges = hasChanges;
    });
  }

  // Helper method to compare dates ignoring time
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await storage.read(key: 'auth_token');
      final userData = await storage.read(key: 'user_data');

      if (token == null || userData == null) {
        setState(() {
          _errorMessage = 'Veuillez vous connecter pour accéder aux paramètres';
          _isLoading = false;
        });
        return;
      }

      final user = jsonDecode(userData);
      final userId = user['id'];

      final response = await http.get(
        Uri.parse('$baseUrl/api/utilisateurs/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);

        // Store original values
        _originalNom = userData['nom'] ?? '';
        _originalPrenom = userData['prenom'] ?? '';
        _originalEmail = userData['email'] ?? '';
        _originalTelephone = userData['telephone'] ?? '';
        _originalVille = userData['ville'] ?? '';
        _originalDateNaissance =
            userData['date_naissance'] != null
                ? DateTime.parse(userData['date_naissance'])
                : null;
        _originalSexe = userData['sexe'];
        _originalPhotoUrl = userData['photo_profil'];

        // Set controller values
        setState(() {
          _nomController.text = _originalNom;
          _prenomController.text = _originalPrenom;
          _emailController.text = _originalEmail;
          _telephoneController.text = _originalTelephone;
          _villeController.text = _originalVille;
          _dateNaissance = _originalDateNaissance;
          _sexe = _originalSexe;
          _currentPhotoUrl = _originalPhotoUrl;
          _isLoading = false;
          _hasChanges = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des données';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur';
        _isLoading = false;
      });
      print('Error loading user data: $e');
    }
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await storage.read(key: 'auth_token');
      final userData = await storage.read(key: 'user_data');

      if (token == null || userData == null) {
        setState(() {
          _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
          _isLoading = false;
        });
        return;
      }

      final user = jsonDecode(userData);
      final userId = user['id'];

      // Create a map for the request body
      Map<String, dynamic> requestBody = {};

      // Add fields that have changed and are not empty
      if (_nomController.text.isNotEmpty &&
          _nomController.text != _originalNom) {
        requestBody['nom'] = _nomController.text;
      }
      if (_prenomController.text.isNotEmpty &&
          _prenomController.text != _originalPrenom) {
        requestBody['prenom'] = _prenomController.text;
      }
      if (_emailController.text.isNotEmpty &&
          _emailController.text != _originalEmail) {
        requestBody['email'] = _emailController.text;
      }
      if (_telephoneController.text != _originalTelephone) {
        requestBody['telephone'] = _telephoneController.text;
      }
      if (_villeController.text != _originalVille) {
        requestBody['ville'] = _villeController.text;
      }
      if (_dateNaissance != null &&
          _dateNaissance?.toIso8601String() !=
              _originalDateNaissance?.toIso8601String()) {
        requestBody['date_naissance'] = _dateNaissance!.toIso8601String();
      }
      if (_sexe != _originalSexe && _sexe != null) {
        requestBody['sexe'] = _sexe;
      }
      if (_newPasswordController.text.isNotEmpty) {
        requestBody['mot_de_passe'] = _newPasswordController.text;
      }

      // Check if we have any changes to send
      if (requestBody.isEmpty && _imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune modification n\'a été effectuée'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // If we have an image, use MultipartRequest
      if (_imageFile != null) {
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse('$baseUrl/api/utilisateurs/$userId'),
        );

        request.headers.addAll({'Authorization': 'Bearer $token'});

        // Add all fields from requestBody
        requestBody.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        // Add the image file
        request.files.add(
          await http.MultipartFile.fromPath('photo_profil', _imageFile!.path),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        _handleResponse(response);
      } else {
        // If no image, use regular PUT request
        final response = await http.put(
          Uri.parse('$baseUrl/api/utilisateurs/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        );
        _handleResponse(response);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur';
        _isLoading = false;
      });
      print('Error updating user data: $e');
    }
  }

  // Helper method to handle the response
  void _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final updatedUserData = jsonDecode(response.body);

      // Update original values after successful update
      _originalNom = _nomController.text;
      _originalPrenom = _prenomController.text;
      _originalEmail = _emailController.text;
      _originalTelephone = _telephoneController.text;
      _originalVille = _villeController.text;
      _originalDateNaissance = _dateNaissance;
      _originalSexe = _sexe;
      _originalPhotoUrl = _currentPhotoUrl;

      // Update stored user data
      storage.write(
        key: 'user_data',
        value: jsonEncode(updatedUserData['user']),
      );

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();

      setState(() {
        _hasChanges = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );
    } else {
      final errorData = jsonDecode(response.body);
      setState(() {
        _errorMessage =
            errorData['error'] ?? 'Erreur lors de la mise à jour du profil';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCDEF9),
      appBar: AppBar(
        title: const Text('Paramètres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.circle, color: Colors.blue, size: 12),
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
                      onPressed: _loadUserData,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Photo
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : _currentPhotoUrl != null
                                      ? NetworkImage(_currentPhotoUrl!)
                                      : null,
                              child:
                                  (_imageFile == null &&
                                          _currentPhotoUrl == null)
                                      ? const Icon(Icons.person, size: 60)
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Personal Information Form
                      const Text(
                        'Informations Personnelles',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _prenomController,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre prénom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!value.contains('@')) {
                            return 'Veuillez entrer un email valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telephoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _villeController,
                        decoration: const InputDecoration(
                          labelText: 'Ville',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date de naissance
                      const Text(
                        'Date de naissance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _dateNaissance ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            locale: const Locale('fr', 'FR'),
                          );
                          if (picked != null) {
                            setState(() {
                              _dateNaissance = picked;
                            });
                            _checkForChanges(); // Trigger change detection
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _dateNaissance != null
                                    ? '${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}'
                                    : 'Sélectionner une date',
                                style: TextStyle(
                                  color:
                                      _dateNaissance != null
                                          ? Colors.black
                                          : Colors.grey[600],
                                ),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sexe
                      const Text(
                        'Sexe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _sexe = 'homme';
                                });
                                _checkForChanges(); // Trigger change detection
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _sexe == 'homme'
                                          ? Colors.blue
                                          : Colors.transparent,
                                  border: Border.all(
                                    color:
                                        _sexe == 'homme'
                                            ? Colors.blue
                                            : Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Homme',
                                    style: TextStyle(
                                      color:
                                          _sexe == 'homme'
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _sexe = 'femme';
                                });
                                _checkForChanges(); // Trigger change detection
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _sexe == 'femme'
                                          ? Colors.blue
                                          : Colors.transparent,
                                  border: Border.all(
                                    color:
                                        _sexe == 'femme'
                                            ? Colors.blue
                                            : Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Femme',
                                    style: TextStyle(
                                      color:
                                          _sexe == 'femme'
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Password Change Section
                      const Text(
                        'Changer le mot de passe',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _currentPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe actuel',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: !_showPassword,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Nouveau mot de passe',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _showNewPassword = !_showNewPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: !_showNewPassword,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Le mot de passe doit contenir au moins 6 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _hasChanges ? _updateUserData : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _hasChanges ? Colors.blue : Colors.grey[300],
                            foregroundColor:
                                _hasChanges ? Colors.white : Colors.grey[600],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _hasChanges
                                ? 'Enregistrer les modifications'
                                : 'Aucune modification',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
