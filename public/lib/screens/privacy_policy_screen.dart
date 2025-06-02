import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCDEF9),
      appBar: AppBar(
        title: const Text('Politique de Confidentialité'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dernière mise à jour : Juin 2024',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Introduction',
              'Bienvenue dans notre politique de confidentialité. Nous respectons votre vie privée et nous nous engageons à protéger vos données personnelles. Cette politique vous informe sur la manière dont nous traitons vos données lorsque vous utilisez notre application de colocation.',
            ),
            _buildSection(
              'Collecte des Données',
              'Nous collectons les informations suivantes :\n\n'
                  '• Informations de profil (nom, prénom, photo)\n'
                  '• Coordonnées (email, numéro de téléphone)\n'
                  '• Préférences de colocation\n'
                  '• Informations sur vos propriétés\n'
                  '• Historique des interactions\n'
                  '• Données de géolocalisation (avec votre consentement)',
            ),
            _buildSection(
              'Utilisation des Données',
              'Vos données sont utilisées pour :\n\n'
                  '• Gérer votre compte et profil\n'
                  '• Faciliter la mise en relation entre colocataires\n'
                  '• Améliorer nos services\n'
                  '• Personnaliser votre expérience\n'
                  '• Vous envoyer des notifications pertinentes\n'
                  '• Assurer la sécurité de notre plateforme',
            ),
            _buildSection(
              'Protection des Données',
              'Nous mettons en œuvre des mesures de sécurité appropriées pour protéger vos données contre tout accès, modification, divulgation ou destruction non autorisés. Vos données sont stockées sur des serveurs sécurisés et nous utilisons le chiffrement pour protéger les informations sensibles.',
            ),
            _buildSection(
              'Vos Droits',
              'Vous avez le droit de :\n\n'
                  '• Accéder à vos données personnelles\n'
                  '• Rectifier vos données\n'
                  '• Supprimer vos données\n'
                  '• Limiter le traitement\n'
                  '• Porter vos données\n'
                  '• Vous opposer au traitement\n'
                  '• Retirer votre consentement',
            ),
            _buildSection(
              'Cookies et Traceurs',
              'Nous utilisons des cookies et autres technologies de suivi pour améliorer votre expérience, analyser l\'utilisation de notre application et personnaliser nos services. Vous pouvez contrôler l\'utilisation des cookies dans les paramètres de votre appareil.',
            ),
            _buildSection(
              'Contact',
              'Pour toute question concernant cette politique ou vos données personnelles, contactez notre délégué à la protection des données à :\n\ndpo@roomie.com',
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'J\'ai compris',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
