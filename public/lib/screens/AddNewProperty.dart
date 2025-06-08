import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddNewPropertyScreen extends StatefulWidget {
  const AddNewPropertyScreen({super.key});

  @override
  State<AddNewPropertyScreen> createState() => _AddNewPropertyScreenState();
}

class _AddNewPropertyScreenState extends State<AddNewPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
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
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage(imageQuality: 80);
    if (images != null && images.length <= 10) {
      setState(() {
        _selectedImages = images;
      });
    } else if (images != null && images.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous pouvez sélectionner jusqu’à 10 images maximum.'),
        ),
      );
    }
  }

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
        final logementData = jsonDecode(response.body);
        final logementId =
            logementData['id'] ?? logementData['logement']?['id'];
        // Upload images if any
        if (logementId != null && _selectedImages.isNotEmpty) {
          try {
            var uploadUrl = Uri.parse(
              '$baseUrl/api/logements/$logementId/upload-pictures',
            );
            var request = http.MultipartRequest('POST', uploadUrl);
            for (var img in _selectedImages) {
              request.files.add(
                await http.MultipartFile.fromPath('pictures', img.path),
              );
            }
            var uploadResp = await request.send();
            if (uploadResp.statusCode == 200) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Images téléchargées avec succès'),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Erreur lors de l’upload des images: ${uploadResp.statusCode}',
                  ),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de l’upload des images: $e')),
            );
          }
        }
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
              // Image picker area at top
              GestureDetector(
                onTap: _isSubmitting ? null : _pickImages,
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.20,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child:
                      _selectedImages.isEmpty
                          ? Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 60,
                              color: Colors.grey[500],
                            ),
                          )
                          : Stack(
                            children: [
                              ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, idx) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_selectedImages[idx].path),
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.35,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.photo_library,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_selectedImages.length}/10',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 16),
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
