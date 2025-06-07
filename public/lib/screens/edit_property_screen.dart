import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EditPropertyScreen extends StatefulWidget {
  final int propertyId;
  final String baseUrl = 'http://10.0.2.2:3000';
  const EditPropertyScreen({Key? key, required this.propertyId})
    : super(key: key);

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  // Controllers for text fields
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _superficieController = TextEditingController();
  final _nombrePiecesController = TextEditingController();
  final _nombreColocMaxController = TextEditingController();
  final _loyerController = TextEditingController();
  final _capaciteMaxColocatairesController = TextEditingController();

  // Dropdowns and switches
  String _typeLogement = 'appartement';
  bool _chargesIncluses = false;
  bool _meuble = false;
  bool _estActif = true;
  DateTime? _disponibleAPartir;

  final List<String> _typesLogement = [
    'appartement',
    'maison',
    'studio',
    'chambre',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProperty();
  }

  void _fetchProperty() async {
    final url = '${widget.baseUrl}/api/logements/${widget.propertyId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _titreController.text = data['titre'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _adresseController.text = data['adresse'] ?? '';
          _villeController.text = data['ville'] ?? '';
          _codePostalController.text = data['code_postal'] ?? '';
          _superficieController.text = data['superficie']?.toString() ?? '';
          _nombrePiecesController.text =
              data['nombre_pieces']?.toString() ?? '';
          _nombreColocMaxController.text =
              data['nombre_coloc_max']?.toString() ?? '';
          _typeLogement = data['type_logement'] ?? 'appartement';
          _loyerController.text = data['loyer']?.toString() ?? '';
          _chargesIncluses = data['charges_incluses'] ?? false;
          _meuble = data['meuble'] ?? false;
          _estActif = data['est_actif'] ?? true;
          _disponibleAPartir =
              data['disponible_a_partir'] != null &&
                      data['disponible_a_partir'] != ''
                  ? DateTime.tryParse(data['disponible_a_partir'])
                  : null;
          _capaciteMaxColocatairesController.text =
              data['capacite_max_colocataires']?.toString() ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: {response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de connexion: $e')));
    }
  }

  void _submit() async {
    final url = '${widget.baseUrl}/api/logements/${widget.propertyId}';
    final storage = const FlutterSecureStorage();
    final userDataStr = await storage.read(key: 'user_data');
    int? userId;
    if (userDataStr != null) {
      try {
        final userData = jsonDecode(userDataStr);
        userId = userData['id'];
      } catch (e) {
        // fallback: userId stays null
      }
    }
    final body = jsonEncode({
      'titre': _titreController.text,
      'description': _descriptionController.text,
      'adresse': _adresseController.text,
      'ville': _villeController.text,
      'code_postal': _codePostalController.text,
      'superficie': double.tryParse(_superficieController.text),
      'nombre_pieces': int.tryParse(_nombrePiecesController.text),
      'nombre_coloc_max': int.tryParse(_nombreColocMaxController.text),
      'type_logement': _typeLogement,
      'loyer': double.tryParse(_loyerController.text),
      'charges_incluses': _chargesIncluses,
      'meuble': _meuble,
      'est_actif': _estActif,
      'disponible_a_partir': _disponibleAPartir?.toIso8601String(),
      'capacite_max_colocataires': int.tryParse(
        _capaciteMaxColocatairesController.text,
      ),
      // Optionally include proprietaire_id if needed by backend:
      if (userId != null) 'proprietaire_id': userId,
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      Navigator.of(context).pop(); // Remove loading
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propriété modifiée avec succès!')),
        );
        Navigator.of(
          context,
        ).pop(true); // Return to previous screen, maybe with success
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${response.body}')));
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de connexion: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la propriété')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titreController,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _adresseController,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            TextField(
              controller: _villeController,
              decoration: const InputDecoration(labelText: 'Ville'),
            ),
            TextField(
              controller: _codePostalController,
              decoration: const InputDecoration(labelText: 'Code Postal'),
            ),
            TextField(
              controller: _superficieController,
              decoration: const InputDecoration(labelText: 'Superficie (m²)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _nombrePiecesController,
              decoration: const InputDecoration(labelText: 'Nombre de pièces'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _nombreColocMaxController,
              decoration: const InputDecoration(labelText: 'Nombre coloc max'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: _typeLogement,
              items:
                  _typesLogement
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _typeLogement = val);
              },
              decoration: const InputDecoration(labelText: 'Type de logement'),
            ),
            TextField(
              controller: _loyerController,
              decoration: const InputDecoration(labelText: 'Loyer'),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              title: const Text('Charges incluses'),
              value: _chargesIncluses,
              onChanged: (val) => setState(() => _chargesIncluses = val),
            ),
            SwitchListTile(
              title: const Text('Meublé'),
              value: _meuble,
              onChanged: (val) => setState(() => _meuble = val),
            ),
            SwitchListTile(
              title: const Text('Actif'),
              value: _estActif,
              onChanged: (val) => setState(() => _estActif = val),
            ),
            ListTile(
              title: Text(
                _disponibleAPartir == null
                    ? 'Disponible à partir (non défini)'
                    : 'Disponible à partir: ${_disponibleAPartir!.toLocal().toString().split(' ')[0]}',
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _disponibleAPartir ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _disponibleAPartir = picked);
              },
            ),
            TextField(
              controller: _capaciteMaxColocatairesController,
              decoration: const InputDecoration(
                labelText: 'Capacité max colocataires',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Enregistrer les modifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _superficieController.dispose();
    _nombrePiecesController.dispose();
    _nombreColocMaxController.dispose();
    _loyerController.dispose();
    _capaciteMaxColocatairesController.dispose();
    super.dispose();
  }
}
