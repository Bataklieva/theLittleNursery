class ParentProfile {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? fcmToken;

  const ParentProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.fcmToken,
  });

  factory ParentProfile.fromMap(String uid, Map<String, dynamic> map) {
    return ParentProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      fcmToken: map['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'fcmToken': fcmToken,
    };
  }

  ParentProfile copyWith({
    String? name,
    String? phone,
    String? fcmToken,
  }) {
    return ParentProfile(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
