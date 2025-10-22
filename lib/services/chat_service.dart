import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- EXISTING METHODS ---

  /// Generate a consistent, sorted chat/match ID for two users.
  String getMatchId(String userA, String userB) {
    List<String> uids = [userA, userB];
    uids.sort(); // Sorts the list alphabetically
    return uids.join("_");
  }

  /// Get the stream of messages for a specific match.
  Stream<QuerySnapshot> getChatStream(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Send a new message and save it to Firestore.
  Future<void> sendMessage({
    required String matchId,
    required String messageText,
    required String fromUid,
    required String toUid,
  }) async {
    if (messageText.trim().isEmpty) return;

    final messageData = {
      'text': messageText.trim(),
      'fromUid': fromUid,
      'toUid': toUid,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'reaction': null, // Field for reactions (Suggestion #2)
    };

    try {
      // Add the new message
      await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .add(messageData);

      // Update the last message preview for the chat list
      await _firestore.collection('matches').doc(matchId).set({
        'lastMessage': messageText.trim(),
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'users': [fromUid, toUid], // Ensure we know who is in this match
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  // --- NEW METHODS ---

  /// Get a real-time stream of a user's data (for online/lastSeen)
  /// ASSUMPTION: You have a 'users' collection where doc ID is the UID.
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Get a real-time stream of the match document (for typing status)
  Stream<DocumentSnapshot> getMatchStream(String matchId) {
    return _firestore.collection('matches').doc(matchId).snapshots();
  }

  /// Set the typing status for a user within a match
  /// (Suggestion #6)
  Future<void> setTypingStatus(
      String matchId, String typingUid, bool isTyping) async {
    try {
      await _firestore.collection('matches').doc(matchId).set({
        'typing': {
          typingUid: isTyping,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error setting typing status: $e");
    }
  }

  /// Mark all unread messages for the current user as read
  /// (Suggestion #6)
  Future<void> markMessagesAsRead(String matchId, String currentUid) async {
    try {
      final querySnapshot = await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .where('toUid', isEqualTo: currentUid)
          .where('isRead', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  /// Add or remove a reaction from a message
  /// (Suggestion #2)
  Future<void> reactToMessage(
      String matchId, String messageId, String? reaction) async {
    try {
      await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .doc(messageId)
          .update({'reaction': reaction});
    } catch (e) {
      debugPrint("Error reacting to message: $e");
    }
  }
}