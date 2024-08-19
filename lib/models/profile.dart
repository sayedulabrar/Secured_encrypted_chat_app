class Profile {
  final String userid;
  final String email;
  final String password;
  final String role;
  final bool disabled;
  final String? pfpURL; // Optional field for profile picture URL
  final String? div; // Optional field for Division
  final String? unit; // Optional field for Unit
  final String? appointment; // Optional field for Appointment

  Profile({
    required this.userid,
    required this.email,
    required this.password,
    required this.role,
    required this.disabled,
    this.pfpURL, // Initialize pfpURL as optional
    this.div, // Initialize div as optional
    this.unit, // Initialize unit as optional
    this.appointment, // Initialize appointment as optional
  });

  Profile.fromJson(Map<String, Object?> json)
      : userid = json['userid']! as String,
        email = json['email']! as String,
        password = json['password']! as String,
        role = json['role']! as String,
        disabled = json['disabled']! as bool,
        pfpURL = json['pfpURL'] as String?, // Deserialize pfpURL
        div = json['div'] as String?, // Deserialize div
        unit = json['unit'] as String?, // Deserialize unit
        appointment = json['appointment'] as String?; // Deserialize appointment

  Profile copyWith({
    String? userid,
    String? email,
    String? password,
    String? role,
    bool? disabled,
    String? pfpURL, // Include pfpURL in copyWith method
    String? div, // Include div in copyWith method
    String? unit, // Include unit in copyWith method
    String? appointment, // Include appointment in copyWith method
  }) {
    return Profile(
      userid: userid ?? this.userid,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      disabled: disabled ?? this.disabled,
      pfpURL: pfpURL ?? this.pfpURL, // Update pfpURL if provided
      div: div ?? this.div, // Update div if provided
      unit: unit ?? this.unit, // Update unit if provided
      appointment: appointment ?? this.appointment, // Update appointment if provided
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
      'div': div, // Serialize div
      'unit': unit, // Serialize unit
      'appointment': appointment, // Serialize appointment
    };
  }
}
