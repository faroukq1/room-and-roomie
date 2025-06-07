import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddNewPropertyScreen extends StatefulWidget {
  const AddNewPropertyScreen({super.key});

  @override
  State<AddNewPropertyScreen> createState() => _AddNewPropertyScreenState();
}

class _AddNewPropertyScreenState extends State<AddNewPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final String baseUrl =
      'http://10.0.2.2:3000'; // Replace with your server's IP (e.g., 192.168.1.100 or 10.0.2.2 for emulator)

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _codePostalController = TextEditingController();
  final TextEditingController _superficieController = TextEditingController();
  final TextEditingController _nombrePiecesController = TextEditingController();
  final TextEditingController _nombreColocController = TextEditingController();
  final TextEditingController _loyerController = TextEditingController();
  final TextEditingController _dateDispoController = TextEditingController();

  String _typeLogement = 'appartement';
  bool _chargesIncluses = false;
  bool _meuble = false;

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      setState(() => _isSubmitting = false);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Load user data similar to _loadUserData
      String? userDataJson = await _storage.read(key: 'user_data');

      StringBuffer buffer = StringBuffer();
      if (userDataJson != null) {
        buffer.writeln('user_data: $userDataJson');
      }
      print(buffer.toString());

      int userId = 0;
      Map<String, dynamic>? userData;
      if (userDataJson != null) {
        try {
          userData = jsonDecode(userDataJson);
          userId = userData?['id'] ?? 0;
        } catch (e) {
          print('Error parsing user_data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erreur lors de la lecture des données utilisateur',
              ),
            ),
          );
          setState(() => _isSubmitting = false);
          return;
        }
      }

      if (userId == 0) {
        print('Invalid userId: $userId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID utilisateur manquant')),
        );
        setState(() => _isSubmitting = false);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final Map<String, dynamic> newProperty = {
        "proprietaire_id": userId,
        "titre": _titleController.text,
        "description": _descriptionController.text,
        "adresse": _adresseController.text,
        "ville": _villeController.text,
        "code_postal": _codePostalController.text,
        "superficie": double.tryParse(_superficieController.text) ?? 0.0,
        "nombre_pieces": int.tryParse(_nombrePiecesController.text) ?? 0,
        "nombre_coloc_max": int.tryParse(_nombreColocController.text) ?? 0,
        "type_logement": _typeLogement,
        "loyer": double.tryParse(_loyerController.text) ?? 0.0,
        "charges_incluses": _chargesIncluses,
        "meuble": _meuble,
        "disponible_a_partir": _dateDispoController.text,
      };

      final url = '$baseUrl/api/logements/create';
      print('Request URL: $url');
      print('Request Payload: ${jsonEncode(newProperty)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newProperty),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      setState(() => _isSubmitting = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propriété ajoutée avec succès')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${response.statusCode} - ${response.body}'),
          ),
        );
      }
    } catch (e) {
      print('Error during request: $e');
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion au serveur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une propriété')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(labelText: 'Adresse'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _villeController,
                decoration: const InputDecoration(labelText: 'Ville'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _codePostalController,
                decoration: const InputDecoration(labelText: 'Code postal'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _superficieController,
                decoration: const InputDecoration(labelText: 'Superficie (m²)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Champ requis';
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Veuillez entrer un nombre valide supérieur à 0';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nombrePiecesController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de pièces',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Champ requis';
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Veuillez entrer un nombre valide supérieur à 0';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nombreColocController,
                decoration: const InputDecoration(
                  labelText: 'Capacité de colocataires',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Champ requis';
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Veuillez entrer un nombre valide supérieur à 0';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _loyerController,
                decoration: const InputDecoration(labelText: 'Loyer (DA)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Champ requis';
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Veuillez entrer un nombre valide supérieur à 0';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _typeLogement,
                decoration: const InputDecoration(
                  labelText: 'Type de logement',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'appartement',
                    child: Text('Appartement'),
                  ),
                  DropdownMenuItem(value: 'maison', child: Text('Maison')),
                  DropdownMenuItem(value: 'studio', child: Text('Studio')),
                  DropdownMenuItem(value: 'chambre', child: Text('Chambre')),
                ],
                onChanged: (value) => setState(() => _typeLogement = value!),
                validator: (value) => value == null ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _dateDispoController,
                decoration: const InputDecoration(
                  labelText: 'Disponible à partir',
                ),
                readOnly: true,
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Champ requis' : null,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    _dateDispoController.text =
                        date.toIso8601String().split('T')[0];
                  }
                },
              ),
              SwitchListTile(
                value: _chargesIncluses,
                onChanged: (val) => setState(() => _chargesIncluses = val),
                title: const Text('Charges incluses'),
              ),
              SwitchListTile(
                value: _meuble,
                onChanged: (val) => setState(() => _meuble = val),
                title: const Text('Meublé'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _superficieController.dispose();
    _nombrePiecesController.dispose();
    _nombreColocController.dispose();
    _loyerController.dispose();
    _dateDispoController.dispose();
    super.dispose();
  }
}
