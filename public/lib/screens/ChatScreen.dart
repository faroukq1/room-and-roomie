import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants.dart';

class ChatScreen extends StatefulWidget {
  final int? currentUserId;
  final int? otherUserId;
  final String? otherUserName;

  const ChatScreen({
    Key? key,
    this.currentUserId,
    this.otherUserId,
    this.otherUserName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late int? userId;
  late int? ownerId;
  late String? ownerName;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  IO.Socket? socket;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    userId = args != null ? args['currentUserId'] : widget.currentUserId;
    ownerId = args != null ? args['otherUserId'] : widget.otherUserId;
    ownerName = args != null ? args['otherUserName'] : widget.otherUserName;
    _initSocket();
  }

  void _initSocket() {
    if (socket != null || userId == null || ownerId == null) return;
    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    socket!.connect();
    socket!.onConnect((_) {
      // Join the room
      socket!.emit('joinRoom', {'userId': userId, 'otherUserId': ownerId});
      // Load chat history from the server
      socket!.emit('loadHistory', {'userId': userId, 'otherUserId': ownerId});
    });
    // Listen for incoming messages
    socket!.on('receiveMessage', (data) {
      setState(() {
        _messages.add({
          'from': data['fromUserId'],
          'to': data['toUserId'],
          'content': data['content'],
          'date': DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
        });
      });
    });
    // Optionally listen for chat history
    socket!.on('chatHistory', (data) {
      setState(() {
        _messages.clear();
        for (var msg in data) {
          _messages.add({
            'from': msg['fromUserId'],
            'to': msg['toUserId'],
            'content': msg['content'],
            'date': DateTime.tryParse(msg['date'] ?? '') ?? DateTime.now(),
          });
        }
      });
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || userId == null || ownerId == null || socket == null)
      return;
    final msg = {'content': text, 'toUserId': ownerId};
    socket!.emit('sendMessage', msg);
    _controller.clear(); // Only clear the input, do not add to _messages here
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${ownerName ?? ''}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['from'] == userId;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(msg['content']),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Écrivez un message...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
