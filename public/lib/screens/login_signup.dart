import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoginMode = true;
  bool _isLoading = false;
  String _errorMessage = '';
  final storage = FlutterSecureStorage();

  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  // API URL - Update with your actual server address
  final String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator

  // Login function
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'mot_de_passe': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      print(data);
      if (response.statusCode == 200 && data['token'] != null) {
        // Store token and user data
        await storage.write(key: 'auth_token', value: data['token']);
        await storage.write(key: 'user_data', value: jsonEncode(data['user']));

        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Échec de la connexion';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur';
      });
      print('Login error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Signup function
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': _nameController.text.trim(),
          'prenom': _prenomController.text.trim(),
          'email': _emailController.text.trim(),
          'mot_de_passe': _passwordController.text.trim(),
          // Optionally include phone if your API supports it
          'telephone': _phoneController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Show success message and switch to login mode
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie! Veuillez vous connecter'),
          ),
        );
        setState(() {
          _isLoginMode = true;
          _emailController.text = ''; // Clear fields
          _passwordController.text = '';
          _nameController.text = '';
          _phoneController.text = '';
          // NEW: Clear prenom field
          _prenomController.text = '';
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? "Erreur lors de l'inscription";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur';
      });
      print('Signup error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Continue as guest function
  void _continueAsGuest() async {
    // For now, just navigate to home
    // You might want to set some flag to indicate guest mode
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'user_data');
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCDEF9), // Light blue background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // App logo
                  Center(child: Image.asset('assets/logo.jpg', width: 120)),
                  const SizedBox(height: 16),

                  // App name
                  const Center(
                    child: Text(
                      'ROOM & ROOMIE',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Toggle buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoginMode = true;
                              _errorMessage = '';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isLoginMode ? Colors.blue : Colors.white,
                            foregroundColor:
                                _isLoginMode ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Connexion',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoginMode = false;
                              _errorMessage = '';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                !_isLoginMode ? Colors.blue : Colors.white,
                            foregroundColor:
                                !_isLoginMode ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'S\'inscrire',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Form fields
                  if (!_isLoginMode) ...[
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'Nom',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // NEW: Added prenom text field
                    _buildTextField(
                      controller: _prenomController,
                      hintText: 'Prénom',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre prénom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      hintText: 'Numéro de téléphone',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre numéro de téléphone';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Mot de passe',
                    icon: Icons.lock,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      if (!_isLoginMode && value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),

                  if (_isLoginMode) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Implement forgot password
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité à venir'),
                            ),
                          );
                        },
                        child: const Text(
                          'Mot de passe oublié?',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                  ],

                  // Error message display
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Main action button
                  ElevatedButton(
                    onPressed:
                        _isLoading ? null : (_isLoginMode ? _login : _signup),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              _isLoginMode ? 'Se connecter' : 'S\'inscrire',
                              style: const TextStyle(fontSize: 16),
                            ),
                  ),

                  const SizedBox(height: 24),

                  // Skip for now button
                  TextButton(
                    onPressed: _continueAsGuest,
                    child: const Text(
                      'Continuer sans compte',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Social login options
                  const Center(child: Text('Ou connectez-vous avec')),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(Icons.facebook, Colors.blue[800]!),
                      const SizedBox(width: 20),
                      _buildSocialButton(Icons.g_mobiledata, Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          errorStyle: const TextStyle(height: 0),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fonctionnalité à venir')));
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
