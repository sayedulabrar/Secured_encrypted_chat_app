class ChatUser {
  final String id;
  final String? profileImage;
  final Map<String, dynamic>? customProperties;
  final String? firstName;
  final String? lastName;

  ChatUser({
    required this.id,
    this.profileImage,
    this.customProperties,
    this.firstName,
    this.lastName,
  });

  // You can add methods to handle custom properties if needed
  dynamic getCustomProperty(String key) {
    return customProperties?[key];
  }

  void setCustomProperty(String key, dynamic value) {
    customProperties?[key] = value;
  }
}
