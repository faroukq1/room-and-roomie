class Message {
  final String senderName;
  final String text;
  final DateTime time;
  final String avatarUrl;
  final bool unread;

  Message(this.senderName, this.text, this.time, this.avatarUrl, this.unread);
}