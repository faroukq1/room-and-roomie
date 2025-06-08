import '../models/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  int _currentIndex = 2; // Set to 2 for Inbox

  List<Message> _messages = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final storage = const FlutterSecureStorage();
      final userDataStr = await storage.read(key: 'user_data');
      if (userDataStr == null) {
        setState(() {
          _isLoading = false;
        });
        print('No user data found in secure storage.');
        return;
      }
      final userData = jsonDecode(userDataStr);
      _currentUserId = userData['id'];
      final response = await http.get(
        Uri.parse('$socketUrl/api/conversations/$_currentUserId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Message> messages = [];
        for (var convo in data) {
          final otherUserId =
              convo['expediteur_id'] == _currentUserId
                  ? convo['destinataire_id']
                  : convo['expediteur_id'];
          final userResp = await http.get(
            Uri.parse('$baseUrl/api/utilisateurs/$otherUserId'),
          );
          print('User response: ${userResp.statusCode} ${userResp.body}');
          String senderName = 'Utilisateur';
          String avatarUrl = '';
          if (userResp.statusCode == 200) {
            final user = jsonDecode(userResp.body);
            senderName = (user['prenom'] ?? '') + ' ' + (user['nom'] ?? '');
            avatarUrl = user['photo_profil'] ?? '';
          }
          messages.add(
            Message(
              senderName,
              convo['contenu'] ?? '',
              DateTime.tryParse(convo['date_envoi'] ?? '') ?? DateTime.now(),
              avatarUrl,
              !(convo['lu'] ?? true) &&
                  convo['destinataire_id'] == _currentUserId,
            )..otherUserId = otherUserId,
          );
        }
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      } else {
        print('Failed to fetch conversations: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('Error in _fetchConversations: $e');
      print(stack);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCDEF9), // Light blue background
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      // Implement search functionality
                    },
                  ),
                ],
              ),
            ),

            // Message tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildMessageTab('Tous', true),
                  const SizedBox(width: 16),
                  _buildMessageTab('Non lus', false),
                ],
              ),
            ),

            // Message list
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                      ? const Center(child: Text('Aucune conversation'))
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageItem(message);
                        },
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
                  buildNavItem(0, Icons.home, 'Home'),
                  buildNavItem(1, Icons.favorite_border, 'Favoris'),
                  buildNavItem(2, Icons.article_outlined, 'Inbox'),
                  buildNavItem(3, Icons.person_outline, 'Profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(message.avatarUrl),
          onBackgroundImageError: (_, __) {
            // Handle error
          },
        ),
        title: Row(
          children: [
            Text(
              message.senderName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            Text(
              _formatTime(message.time),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              message.text,
              style: TextStyle(
                color: message.unread ? Colors.black : Colors.grey[600],
                fontWeight:
                    message.unread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        // If unread, show indicator
        trailing:
            message.unread
                ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
                : null,
        onTap: () {
          // Navigate to ChatScreen with current user and other user ID
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: {
              'currentUserId': _currentUserId,
              'otherUserId': (message as dynamic).otherUserId,
              'otherUserName': message.senderName,
              'avatarUrl': message.avatarUrl,
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();

    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (time.isAfter(now.subtract(const Duration(days: 7)))) {
      return _getWeekday(time);
    } else {
      return '${time.day}/${time.month}';
    }
  }

  String _getWeekday(DateTime time) {
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return weekdays[time.weekday - 1];
  }

  // Changed from _buildNavItem to buildNavItem (removed underscore)
  Widget buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/favorites');
        } else if (index == 2) {
          // Already on inbox screen
          setState(() {
            _currentIndex = index;
          });
        } else if (index == 3) {
          Navigator.pushReplacementNamed(context, '/profile');
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
