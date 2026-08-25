import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled }

class Booking {
  final String id;
  final String eventId;
  final String parentUid;
  final String childId;
  final String childName;
  final BookingStatus status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.eventId,
    required this.parentUid,
    required this.childId,
    required this.childName,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      eventId: map['eventId'] as String,
      parentUid: map['parentUid'] as String,
      childId: map['childId'] as String,
      childName: map['childName'] as String? ?? '',
      status: BookingStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'confirmed'),
        orElse: () => BookingStatus.confirmed,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'parentUid': parentUid,
      'childId': childId,
      'childName': childName,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
