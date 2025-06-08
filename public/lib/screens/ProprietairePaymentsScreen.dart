import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProprietairePaymentsScreen extends StatefulWidget {
  const ProprietairePaymentsScreen({super.key});

  @override
  State<ProprietairePaymentsScreen> createState() => _ProprietairePaymentsScreenState();
}

class _ProprietairePaymentsScreenState extends State<ProprietairePaymentsScreen> {
  List<dynamic> payments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    final storage = const FlutterSecureStorage();
    final userDataStr = await storage.read(key: 'user_data');
    int? proprietaireId;
    if (userDataStr != null) {
      try {
        final userData = jsonDecode(userDataStr);
        proprietaireId = userData['id'];
      } catch (e) {}
    }
    if (proprietaireId == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    final url = Uri.parse('http://10.0.2.2:3000/api/paiements/proprietaire/$proprietaireId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        payments = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements reçus')),
      body: payments.isEmpty
          ? const Center(child: Text('Aucun paiement trouvé.'))
          : ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final p = payments[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('${p['prenom'] ?? ''} ${p['nom'] ?? ''}'),
                  subtitle: Text('Email: ${p['email'] ?? ''}\nLogement: ${p['titre'] ?? ''}'),
                  trailing: Text('${p['montant']} DA'),
                );
              },
            ),
    );
  }
}
