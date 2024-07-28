import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { Text, Image }

class Message {
  String? senderID;
  String? content;
  MessageType? messageType;
  Timestamp? sentAt;
  String iv;
  bool read;

  Message({
    required this.senderID,
    required this.content,
    required this.messageType,
    required this.sentAt,
    required this.iv,
    this.read = false, // Default to unread
  });

  Message.fromJson(Map<String, dynamic> json)
      : senderID = json['senderID'],
        content = json['content'],
        sentAt = json['sentAt'],
        messageType = MessageType.values.firstWhere(
              (e) => e.name == json['messageType'],
          orElse: () => MessageType.Text, // Default value if none matches
        ),
        iv=json['iv'],
        read = json['read'] ?? false; // Default to false if read is null

  Map<String, dynamic> toJson() {
    return {
      'senderID': senderID,
      'content': content,
      'sentAt': sentAt,
      'messageType': messageType?.name,
      'iv':iv,
      'read': read,
    };
  }
}
