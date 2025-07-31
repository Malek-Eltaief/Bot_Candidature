import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
static  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
static  final FirebaseAuth _auth = FirebaseAuth.instance;

/// Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user's role
  Future<String?> getUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }

  // Toggle favorite job
  Future<void> toggleFavorite(String jobId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _firestore.collection('users').doc(uid).collection('favorites').doc(jobId);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.delete();
    } else {
      await ref.set({'jobId': jobId, 'addedAt': Timestamp.now()});
    }
  }

  // Stream all jobs
  Stream<QuerySnapshot> getJobsStream() {
    return _firestore.collection('jobs').snapshots();
  }

  // Stream favorite status of a job
  Stream<DocumentSnapshot> isJobFavorite(String jobId) {
    final uid = _auth.currentUser?.uid;
    return _firestore.collection('users').doc(uid).collection('favorites').doc(jobId).snapshots();
  }

  // Add job offer
  Future<void> addJob({
    required String title,
    required String company,
    required String location,
    required String contractType,
    required String description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await _firestore.collection('jobs').add({
      'title': title.trim(),
      'company': company.trim(),
      'location': location.trim(),
      'contractType': contractType.trim(),
      'description': description.trim(),
      'createdBy': user.uid,
      'createdAt': Timestamp.now(),
      'status': 'active',
    });
  }
  Future<void> updateJob({
  required String jobId,
  required String title,
  required String company,
  required String location,
  required String contractType,
  required String description,
}) async {
  await _firestore.collection('jobs').doc(jobId).update({
    'title': title,
    'company': company,
    'location': location,
    'contractType': contractType,
    'description': description,
  });
}

/// Delete a job
  Future<void> deleteJob(String jobId) async {
    await _firestore.collection('jobs').doc(jobId).delete();
  }

  /// Get job by ID
  Future<DocumentSnapshot> getJobById(String jobId) {
    return _firestore.collection('jobs').doc(jobId).get();
  }
/// Check if a job is favorited
  Future<bool> isFavoriteJob(String jobId) async {
    final user = currentUser;
    if (user != null) {
      final favDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(jobId)
          .get();
      return favDoc.exists;
    }
    return false;
  }
// Toggle favorite status
  Future<void> addToFavorites(String jobId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(jobId)
        .set({'jobId': jobId, 'addedAt': Timestamp.now()});
  }

  Future<void> removeFromFavorites(String jobId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(jobId)
        .delete();
  }

  /// Stream favorite status (optional for StreamBuilder)
  Stream<DocumentSnapshot> favoriteStatusStream(String jobId) {
    final user = currentUser;
    return _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(jobId)
        .snapshots();
  }

  //update profile
    Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<void> getUserProfile({
    required String uid,
    required String fullName,
    required String email,
    required String jobPosition,
    required String location,
  })  async {
    await _firestore.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': email,
      'jobPosition': jobPosition,
      'location': location,
    }, SetOptions(merge: true));
  }
  static Future<void> updateUserProfile({
    required String fullName,
    required String email,
    required String job,
    required String location,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'fullName': fullName,
        'email': email,
        'jobPosition': job,
        'location': location,
      }, SetOptions(merge: true));
    } else {
      throw Exception("User not logged in");
    }
  }

  //favorites 
  Future<void> removeFavorite(String userId, String jobId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(jobId)
        .delete();
  }

  Stream<QuerySnapshot> getFavorites(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots();
  }

 
}
