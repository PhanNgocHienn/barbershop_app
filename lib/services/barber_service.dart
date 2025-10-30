import 'package:cloud_firestore/cloud_firestore.dart';

class BarberService {
  final _col = FirebaseFirestore.instance.collection('barbers');

  Stream<QuerySnapshot> barbersStream() {
    return _col.orderBy('name').snapshots();
  }

  Future<DocumentReference> addBarber(Map<String, dynamic> data) async {
    try {
      final now = FieldValue.serverTimestamp();
      final ref = await _col.add({...data, 'createdAt': now, 'updatedAt': now});
      // Helpful debug log when adding succeeds
      print('[BarberService] addBarber success id=${ref.id}');
      return ref;
    } catch (e, st) {
      // Print error + stacktrace to help troubleshooting
      print('[BarberService] addBarber failed: $e');
      print(st);
      rethrow;
    }
  }

  Future<void> updateBarber(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBarber(String id) async {
    // Note: if there are subcollections (reviews/bookings) you may want to
    // delete them or keep them; implement cascading if required.
    await _col.doc(id).delete();
  }
}
