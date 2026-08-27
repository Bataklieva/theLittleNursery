import 'package:cloud_firestore/cloud_firestore.dart';

class ParentProfile {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? fcmToken;

  /// Set by the `stripeWebhook` Cloud Function (via the Admin SDK) when a
  /// membership purchase is confirmed — never written by the client. See
  /// `toMap()`, which deliberately omits this field, and firestore.rules.
  final DateTime? membershipExpiresAt;

  const ParentProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.fcmToken,
    this.membershipExpiresAt,
  });

  bool get isPremiumMember =>
      membershipExpiresAt != null &&
      membershipExpiresAt!.isAfter(DateTime.now());

  factory ParentProfile.fromMap(String uid, Map<String, dynamic> map) {
    return ParentProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      fcmToken: map['fcmToken'] as String?,
      membershipExpiresAt:
          (map['membershipExpiresAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Only the fields a parent is allowed to write themselves — see the
  /// matching field allowlist in firestore.rules.
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
      membershipExpiresAt: membershipExpiresAt,
    );
  }
}
