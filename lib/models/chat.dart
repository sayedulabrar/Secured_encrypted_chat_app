import 'message.dart';

class Chat {
  String id;
  List<String> participants;
  List<Message> messages;

  Chat({
    required this.id,
    required this.participants,
    required this.messages,
  });

  Chat.fromJson(Map<String, dynamic> json)
      : this(
      id: json['id']! as String,
      participants: List<String>.from(json['participants']! as List),
      messages: (json['messages']! as List)
          .map((item) => Message.fromJson(item as Map<String, Object?>))
          .toList(),
  );

  Chat copyWith({
    String? id,
    List<String>? participants,
    List<Message>? messages,

  }) {
    return Chat(
        id: id ?? this.id,
        participants: participants ?? this.participants,
        messages: messages ?? this.messages,

    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'participants': participants,
      'messages': messages.map((message) => message.toJson()).toList(),

    };
  }
}