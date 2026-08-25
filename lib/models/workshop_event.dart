import 'package:cloud_firestore/cloud_firestore.dart';

class WorkshopEvent {
  final String id;
  final String title;
  final String description;
  final String locationId;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final int bookedCount;

  const WorkshopEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.locationId,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.bookedCount,
  });

  bool get isFull => bookedCount >= capacity;
  int get spotsLeft => (capacity - bookedCount).clamp(0, capacity);

  factory WorkshopEvent.fromMap(String id, Map<String, dynamic> map) {
    return WorkshopEvent(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      locationId: map['locationId'] as String? ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      capacity: map['capacity'] as int? ?? 0,
      bookedCount: map['bookedCount'] as int? ?? 0,
    );
  }
}
