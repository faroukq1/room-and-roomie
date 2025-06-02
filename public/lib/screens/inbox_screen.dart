import 'package:flutter/material.dart';
import 'package:memo/models/message.dart'; // Update this to match your actual package name

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  int _currentIndex = 2; // Set to 2 for Inbox

  final List<Message> _messages = [
    Message(
      'Ahmed',
      'Bonjour, est-ce que l\'appartement est toujours disponible?',
      DateTime.now().subtract(const Duration(minutes: 30)),
      'https://images.unsplash.com/photo-1563370161-21ddef1051b4?crop=entropy&cs=tinysrgb&fit=max&ixid=MXwyMDg5MnwwfDF8c2VhcmNofDEwfHxwZW9wbGV8ZW58MHx8fHwxNjI0OTg0NjI2&ixlib=rb-1.2.1&q=80&w=400',
      true,
    ),
    Message(
      'Sarah',
      'Je suis intéressé par la colocation. Pouvons-nous discuter des détails?',
      DateTime.now().subtract(const Duration(hours: 2)),
      'https://images.unsplash.com/photo-1583779400131-94a7413b3e3b?crop=entropy&cs=tinysrgb&fit=max&ixid=MXwyMDg5MnwwfDF8c2VhcmNofDJ8fHxwZW9wbGV8ZW58MHx8fHwxNjI0OTg1NjA1&ixlib=rb-1.2.1&q=80&w=400',
      false,
    ),
    Message(
      'Karim',
      'À quelle distance est le logement du centre-ville?',
      DateTime.now().subtract(const Duration(days: 1)),
      'https://images.unsplash.com/photo-1600732000364-712227e08cb6?crop=entropy&cs=tinysrgb&fit=max&ixid=MXwyMDg5MnwwfDF8c2VhcmNofDMxfHxwZW9wbGV8ZW58MHx8fHwxNjI0OTg1NTkw&ixlib=rb-1.2.1&q=80&w=400',
      false,
    ),
    Message(
      'Amina',
      'Bonjour, l\'appartement a l\'air très bien. Est-ce qu\'il y a un parking disponible?',
      DateTime.now().subtract(const Duration(days: 2)),
      'https://images.unsplash.com/photo-1521747116042-b2d073d47d62?crop=entropy&cs=tinysrgb&fit=max&ixid=MXwyMDg5MnwwfDF8c2VhcmNofDR8fHxwZW9wbGV8ZW58MHx8fHwxNjI0OTg2MTA3&ixlib=rb-1.2.1&q=80&w=400',
      true,
    ),
  ];

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
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
              child: ListView.builder(
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              _formatTime(message.time),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
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
                fontWeight: message.unread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        // If unread, show indicator
        trailing: message.unread
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
          // Navigate to message detail
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();

    if (time.day == now.day && time.month == now.month && time.year == now.year) {
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
          Icon(
            icon,
            color: isSelected ? Colors.black : Colors.grey,
          ),
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
