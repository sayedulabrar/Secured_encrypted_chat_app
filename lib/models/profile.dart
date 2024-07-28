class Profile {
  final String userid;
  final String email;
  final String password;
  final String role;
  final bool disabled;
  final String? pfpURL; // Added pfpURL field

  Profile({
    required this.userid,
    required this.email,
    required this.password,
    required this.role,
    required this.disabled,
    this.pfpURL, // Initialize pfpURL as optional
  });

  Profile.fromJson(Map<String, Object?> json)
      : userid = json['userid']! as String,
        email = json['email']! as String,
        password = json['password']! as String,
        role = json['role']! as String,
        disabled = json['disabled']! as bool,
        pfpURL = json['pfpURL'] as String?; // Deserialize pfpURL

  Profile copyWith({
    String? userid,
    String? email,
    String? password,
    String? role,
    bool? disabled,
    String? pfpURL, // Include pfpURL in copyWith method
  }) {
    return Profile(
      userid: userid ?? this.userid,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      disabled: disabled ?? this.disabled,
      pfpURL: pfpURL ?? this.pfpURL, // Update pfpURL if provided
    );
  }

  Map<String, Object?> toJson() {
    return {
      'userid': userid,
      'email': email,
      'password': password,
      'role': role,
      'disabled': disabled,
      'pfpURL': pfpURL, // Serialize pfpURL
    };
  }
}
