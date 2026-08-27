import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/workshop_event.dart';

/// Reads the workshop calendar from Firestore's `events` collection.
class EventService {
  EventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('events');

  /// Upcoming events, soonest first.
  Stream<List<WorkshopEvent>> watchUpcoming() {
    final now = Timestamp.fromDate(DateTime.now());
    return _events
        .where('startTime', isGreaterThanOrEqualTo: now)
        .orderBy('startTime')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WorkshopEvent.fromMap(d.id, d.data()))
            .toList());
  }

  /// Events happening on [day], ignoring time-of-day.
  Stream<List<WorkshopEvent>> watchForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _events
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThan: Timestamp.fromDate(end))
        .orderBy('startTime')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WorkshopEvent.fromMap(d.id, d.data()))
            .toList());
  }

  Future<WorkshopEvent?> getById(String eventId) async {
    final doc = await _events.doc(eventId).get();
    if (!doc.exists) return null;
    return WorkshopEvent.fromMap(doc.id, doc.data()!);
  }

  /// All events regardless of date, soonest first — for the admin list.
  Stream<List<WorkshopEvent>> watchAllForAdmin() {
    return _events.orderBy('startTime').snapshots().map((snap) =>
        snap.docs.map((d) => WorkshopEvent.fromMap(d.id, d.data())).toList());
  }

  Future<void> createEvent(WorkshopEvent event) {
    return _events.add(event.toMap());
  }

  Future<void> updateEvent(WorkshopEvent event) {
    return _events.doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String eventId) {
    return _events.doc(eventId).delete();
  }
}
