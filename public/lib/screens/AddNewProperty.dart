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
  final String baseUrl = 'http://10.0.2.2:3000';

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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final token = await _storage.read(key: 'auth_token');
    final userData = await _storage.read(key: 'user_data');

    if (token == null || userData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter')));
      return;
    }

    final user = jsonDecode(userData);
    final userId = user['id'];

    final Map<String, dynamic> newProperty = {
      "titre": _titleController.text,
      "description": _descriptionController.text,
      "adresse": _adresseController.text,
      "ville": _villeController.text,
      "code_postal": _codePostalController.text,
      "superficie": double.tryParse(_superficieController.text),
      "nombre_pieces": int.tryParse(_nombrePiecesController.text),
      "nombre_coloc_max": int.tryParse(_nombreColocController.text),
      "type_logement": _typeLogement,
      "loyer": double.tryParse(_loyerController.text),
      "charges_incluses": _chargesIncluses,
      "meuble": _meuble,
      "disponible_a_partir": _dateDispoController.text,
      "proprietaire_id": userId,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/logements'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(newProperty),
    );

    setState(() => _isSubmitting = false);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propriété ajoutée avec succès')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${response.body}')));
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
              ),
              TextFormField(
                controller: _superficieController,
                decoration: const InputDecoration(labelText: 'Superficie (m²)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _nombrePiecesController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de pièces',
                ),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _nombreColocController,
                decoration: const InputDecoration(
                  labelText: 'Capacité de colocataires',
                ),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _loyerController,
                decoration: const InputDecoration(labelText: 'Loyer (DA)'),
                keyboardType: TextInputType.number,
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
              ),
              TextFormField(
                controller: _dateDispoController,
                decoration: const InputDecoration(
                  labelText: 'Disponible à partir',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
                        ? const CircularProgressIndicator()
                        : const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
