import 'chatuser.dart';

class ChatMessage {
  final ChatUser user;
  final DateTime createdAt;
  final bool isMarkdown;
  final String text;
  final List<ChatMedia>? medias;
  final List<QuickReply>? quickReplies;
  final Map<String, dynamic>? customProperties;
  final List<Mention>? mentions;
  final bool read;
  final ChatMessage? replyTo;

  ChatMessage({
    required this.user,
    required this.createdAt,
    this.isMarkdown = false,
    this.text = '',
    this.medias,
    this.quickReplies,
    this.customProperties,
    this.mentions,
    this.read = false,
    this.replyTo,
  });
}

class ChatMedia {
  final String url;
  final String fileName;
  final MediaType type;

  ChatMedia({
    required this.url,
    required this.fileName,
    required this.type,
  });
}

class QuickReply {
  final String title;
  final String payload;

  QuickReply({
    required this.title,
    required this.payload,
  });
}

class Mention {
  final ChatUser user;
  final int start;
  final int end;

  Mention({
    required this.user,
    required this.start,
    required this.end,
  });
}



enum MediaType {
  image,
  video,
  audio,
  file,
}
