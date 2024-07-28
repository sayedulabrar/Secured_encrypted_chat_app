class ChatActivity {
  final Map<String, bool> userPresence;

  ChatActivity({required this.userPresence});

  factory ChatActivity.fromJson(Map<String, dynamic> json) {
    return ChatActivity(
      userPresence: (json['userPresence'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value as bool),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userPresence': userPresence,
    };
  }
}
