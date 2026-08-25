import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';

class BookingFullException implements Exception {
  const BookingFullException();
}

class AlreadyBookedException implements Exception {
  const AlreadyBookedException();
}

/// Creates and cancels workshop bookings. Booking runs inside a Firestore
/// transaction so two parents racing for the last spot can't both win it.
class BookingService {
  BookingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');

  DocumentReference<Map<String, dynamic>> _eventRef(String eventId) =>
      _firestore.collection('events').doc(eventId);

  Stream<List<Booking>> watchForParent(String parentUid) {
    return _bookings
        .where('parentUid', isEqualTo: parentUid)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }

  Future<void> book({
    required String eventId,
    required String parentUid,
    required String childId,
    required String childName,
  }) {
    return _firestore.runTransaction((tx) async {
      final eventSnap = await tx.get(_eventRef(eventId));
      if (!eventSnap.exists) {
        throw StateError('Event no longer exists.');
      }
      final data = eventSnap.data()!;
      final capacity = data['capacity'] as int? ?? 0;
      final bookedCount = data['bookedCount'] as int? ?? 0;

      final existing = await _bookings
          .where('eventId', isEqualTo: eventId)
          .where('childId', isEqualTo: childId)
          .where('status', isEqualTo: BookingStatus.confirmed.name)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw const AlreadyBookedException();
      }

      if (bookedCount >= capacity) {
        throw const BookingFullException();
      }

      final bookingRef = _bookings.doc();
      tx.set(
        bookingRef,
        Booking(
          id: bookingRef.id,
          eventId: eventId,
          parentUid: parentUid,
          childId: childId,
          childName: childName,
          status: BookingStatus.confirmed,
          createdAt: DateTime.now(),
        ).toMap(),
      );
      tx.update(_eventRef(eventId), {'bookedCount': bookedCount + 1});
    });
  }

  Future<void> cancel(Booking booking) {
    return _firestore.runTransaction((tx) async {
      final eventSnap = await tx.get(_eventRef(booking.eventId));
      tx.update(_bookings.doc(booking.id), {
        'status': BookingStatus.cancelled.name,
      });
      if (eventSnap.exists) {
        final bookedCount = eventSnap.data()!['bookedCount'] as int? ?? 0;
        tx.update(_eventRef(booking.eventId), {
          'bookedCount': (bookedCount - 1).clamp(0, bookedCount),
        });
      }
    });
  }
}
