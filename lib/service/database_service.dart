import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryp_comm/service/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';
import '../main.dart';
import '../models/chatactivity.dart';
import '../models/sortedprofile.dart';
import '/models/chat.dart';
import '/models/message.dart';
import '/models/profile.dart';
import 'auth_service.dart';

class DatabaseService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final GetIt _getIt = GetIt.instance;

  late CollectionReference _userCollection;
  late CollectionReference _chatCollection;
  late CollectionReference _chatActivity;
  late AuthService _authService;
  late StorageService _storageService;

  late String key;
  late String algorithm;

  DatabaseService() {
    _authService = _getIt.get<AuthService>();
    _storageService=_getIt.get<StorageService>();
    _userCollection = _firestore.collection("users").withConverter<Profile>(
        fromFirestore: (snapshots, _) => Profile.fromJson(snapshots.data()!),
        toFirestore: (user_profile, _) => user_profile.toJson());

    _chatCollection = _firestore.collection("chats").withConverter<Chat>(
        fromFirestore: (snapshots, _) => Chat.fromJson(snapshots.data()!),
        toFirestore: (chat, _) => chat.toJson());

    _chatActivity = _firestore.collection("activity").withConverter<ChatActivity>(
      fromFirestore: (snapshots, _) => ChatActivity.fromJson(snapshots.data()!),
      toFirestore: (chat, _) => chat.toJson(),
    );


  }

  Stream<List<String>> getActiveUsersStream() {
    return _firestore.collection('tokens')
        .where('is_online', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != _authService.user!.uid)
          .map((doc) => doc.id)
          .toList();
    });
  }

  Stream<List<Profile>> getActiveUserProfilesStream() {
    return getActiveUsersStream().switchMap((userIds) {
      if (userIds.isEmpty) {
        return Stream.value([]);
      }

      final userProfileStreams = userIds.map((userId) {
        return _userCollection.doc(userId).snapshots().map((snapshot) {
          return snapshot.data();
        }).where((profile) => profile != null).cast<Profile>();
      });

      return Rx.combineLatestList(userProfileStreams);
    });
  }
  

  Future<bool> signup(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }


  Future<void> updateProfileImage(File img) async {
    try {
      String uid = _authService.user!.uid;
      DocumentSnapshot userDoc = await _userCollection.doc(uid).get();
      Profile? currentProfile = userDoc.data() as Profile?;

      // Delete previous profile picture if it exists
      if (currentProfile != null && currentProfile.pfpURL != null && currentProfile.pfpURL!.isNotEmpty) {
        await _storageService.deleteFileFromStorage(url: currentProfile.pfpURL!);
      }

      // Upload new profile picture
      String? newProfileURL = await _storageService.uploadUserPfp(file: img, uid: uid);

      if (newProfileURL != null) {
        // Update profile document with new profile picture URL
        await _userCollection.doc(uid).update({'pfpURL': newProfileURL});
        // Optionally, you can refresh the profile after the update
        await _authService.fetchPersonalProfile();
      } else {
        throw Exception('Failed to upload new profile picture.');
      }
    } catch (e) {
      // Rethrow the error to be caught by the calling method
      throw Exception('Error updating profile picture: $e');
    }
  }


  Future<void> signupWithRole(String email, String password, String role,File img) async {
    User? adminUser = _firebaseAuth.currentUser;
    String? adminEmail = adminUser?.email;

    if (adminEmail != null) {
      String? adminPassword = await _secureStorage.read(key: 'adminPassword');

      bool success = await signup(email, password);
      if (success) {
        // Get the newly created user's UID
        String uid = _firebaseAuth.currentUser!.uid;
        String? pfpURL = await _storageService.uploadUserPfp(
          file: img, // Replace with your image file variable
          uid: uid,
        );

        Profile newUser = Profile(
          userid: uid,
          email: email,
          password: password,
          role: role,
          disabled: false,
          pfpURL: pfpURL,
        );

        await createUserProfile(user_profile: newUser);

        if (adminPassword != null) {
          AuthCredential adminCredential = EmailAuthProvider.credential(
            email: adminEmail,
            password: adminPassword,
          );
          _authService.user=adminUser;
          await _firebaseAuth.signInWithCredential(adminCredential);
        }
      }
    }
  }

  Future<void> toggleUserStatus(String email) async {
    QuerySnapshot querySnapshot = await _userCollection
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.size > 0) {
      String userId = querySnapshot.docs[0].id;
      bool currentStatus = querySnapshot.docs[0].get('disabled') ?? false;

      await _userCollection.doc(userId).update({
        'disabled': !currentStatus,
      });
    } else {
      throw Exception('User not found with email $email');
    }
  }

  Stream<QuerySnapshot<Profile>> getUserProfiles() {
    return _userCollection
        .where("userid", isNotEqualTo: _authService.user!.uid)
        .snapshots() as Stream<QuerySnapshot<Profile>>;
  }



  Stream<SortedProfilesData> getSortedUserProfiles() {
    return _userCollection
        .where("userid", isNotEqualTo: _authService.user!.uid)
        .snapshots()
        .switchMap((userSnapshot) {
      final userId = _authService.user!.uid;

      // Create a stream of chat updates
      return _chatCollection
          .where("participants", arrayContains: userId)
          .snapshots()
          .map((chatSnapshot) {
        try {
          final chats = chatSnapshot.docs.map((doc) => doc.data() as Chat).toList();
          final lastMessageTimestamps = <String, DateTime?>{};

          for (var chat in chats) {
            final participantId = chat.participants.firstWhere((id) => id != userId);
            if (chat.messages.isNotEmpty) {
              final lastMessage = chat.messages.last;
              lastMessageTimestamps[participantId] = lastMessage.sentAt?.toDate();
            }
          }

          final sortedUserProfiles = userSnapshot.docs
              .map((doc) => doc.data() as Profile)
              .where((profile) => lastMessageTimestamps.containsKey(profile.userid) &&
              lastMessageTimestamps[profile.userid] != null)
              .toList();

          sortedUserProfiles.sort((a, b) {
            final aTimestamp = lastMessageTimestamps[a.userid] ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTimestamp = lastMessageTimestamps[b.userid] ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTimestamp.compareTo(aTimestamp);
          });

          // Return the sorted profiles along with the current timestamp
          return SortedProfilesData(sortedUserProfiles, DateTime.now(),lastMessageTimestamps);
        } catch (e) {
          print("Error fetching or sorting chats: $e");
          return SortedProfilesData([], DateTime.now(),{});
        }
      });
    });
  }








  void addProfile(Profile user_profile) async {
    _userCollection.add(user_profile);
  }

  Future<void> createUserProfile({required Profile user_profile}) async {
    await _userCollection.doc(user_profile.userid).set(user_profile);
  }

  Future<void> updateProfile(String user_profileId, Profile user_profile) async {
    await _userCollection.doc(user_profileId).update(user_profile.toJson());
  }

  void deleteProfile(String user_profileId) {
    _userCollection.doc(user_profileId).delete();
  }

  Future<Profile?> fetchPersonalProfile() async {
    QuerySnapshot querySnapshot = await _userCollection
        .where('userid', isEqualTo: _authService.user!.uid)
        .get();

    QuerySnapshot<Profile> profileSnapshot = querySnapshot as QuerySnapshot<Profile>;

    if (profileSnapshot.docs.isNotEmpty) {
      DocumentSnapshot<Profile> docSnapshot = profileSnapshot.docs.first;
      return docSnapshot.data();
    } else {
      return null;
    }
  }



  Future<Profile?> fetchProfile(String otherId) async {
    try {
      QuerySnapshot querySnapshot = await _userCollection
          .where('userid', isEqualTo: otherId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot docSnapshot = querySnapshot.docs.first;
        // Ensure data is of type Map<String, dynamic>
        final data = docSnapshot.data() as Profile;
        print('Profile Data: $data');
        // Convert Map<String, dynamic> data to Profile
        return data;
      } else {
        print('No profile found for userId: $otherId');
        return null;
      }
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }





  Future<bool> checkChatExists(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final result = await _chatCollection.doc(chatID).get();
    if (result != null) {
      return result.exists;
    }
    return false;
  }

  Future<void> createNewChat(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);

    final docRef = _chatCollection.doc(chatID);
    final docRef2= _chatActivity.doc(chatID);
    final chat = Chat(
      id: chatID,
      participants: [uid1, uid2],
      messages: [],
    );

    await docRef.set(chat);
    Map<String, bool> initiateactivity= {
      uid1:false,
      uid2:false
    };
    final chatactivity= ChatActivity(userPresence: initiateactivity);
    await docRef2.set(chatactivity);
  }


  Future<void> enterChat(String chatId, String userId) async {
    await _chatActivity.doc(chatId).update({
      'userPresence.$userId': true,
    });
  }

  Future<void> leaveChat(String chatId, String userId) async {
    await _chatActivity.doc(chatId).update({
      'userPresence.$userId': false,
    });
  }



  Future<bool> isChatActiveUser(String chatId, String userId) async {
    try {
      final snapshot = await _chatActivity.doc(chatId).get();
      final chatActivity = snapshot.data() as ChatActivity?;

      if (chatActivity == null) {
        return false; // Handle the case where chatActivity is null
      }
      print("printing stattus beofore........");
      print(chatActivity.userPresence[userId]);

      // Extract the user presence status from ChatActivity
      return chatActivity.userPresence[userId] ?? false;
    } catch (e) {
      // Handle any errors that occur during the fetch operation
      print("Error fetching chat activity: $e");
      return false;
    }
  }





  Future<void> sendChatMessage(String uid1, String uid2, Message message) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatCollection.doc(chatID);

    await docRef.update({
      "messages": FieldValue.arrayUnion([
        message.toJson(),
      ]),
    });
  }


  Stream<Chat> getChatDataForDate(String uid1, String uid2, DateTime selectedDate) {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    DateTime startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

    return _chatCollection.doc(chatID).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return Chat(id: chatID, participants: [], messages: []);
      }

      Chat chat = snapshot.data() as Chat;
      List<Message> filteredMessages = chat.messages.where((message) {
        Timestamp createdAt = message.sentAt as Timestamp;
        DateTime messageDate = createdAt.toDate();
        return messageDate.isAfter(startOfDay) && messageDate.isBefore(endOfDay);
      }).toList();

      return Chat(
        id: chat.id,
        participants: chat.participants,
        messages: filteredMessages,
      );


    });
  }



  Stream<DocumentSnapshot<Chat>> getChatData(String uid1, String uid2) {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    return _chatCollection.doc(chatID).snapshots() as Stream<DocumentSnapshot<Chat>>;
  }

  Stream<List<Message>> getUnreadMessagesStreamForCurrentUser() {
    String currentUserId = _authService.user!.uid;

    // Create a stream for listening to chat documents where the user is a participant
    return _chatCollection
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .switchMap((chatSnapshot) {
      // List to store unread messages
      List<Message> unreadMessages = [];

      // Process each chat document
      final chatStreams = chatSnapshot.docs.map((chatDoc) {
        // print(chatDoc.id);

        // Stream for the current chat document's messages array
        return Stream.value(chatDoc['messages'] as List<dynamic>).map((messages) {
          // Filter and collect unread messages
          final unreadMessagesInChat = (messages as List<dynamic>).map((messageData) {
            final message = Message.fromJson(messageData as Map<String, dynamic>);
            return (message.senderID != currentUserId && !message.read) ? message : null;
          }).whereType<Message>().toList(); // Filter out null values

          unreadMessages.addAll(unreadMessagesInChat);

          // Sort the unread messages by their sentAt timestamp
          unreadMessages.sort((a, b) {
            return b.sentAt!.toDate().compareTo(a.sentAt!.toDate());
          });

          return unreadMessages;
        });
      });

      // Combine all chat message streams
      return Rx.combineLatestList(chatStreams).map((_) => unreadMessages);
    });
  }


  Future<void> deleteChatMessage(String currentUserId, String otherUserId, DateTime sentAt) async {
    final chatId = generateChatID(uid1: currentUserId, uid2: otherUserId);
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    final chatSnapshot = await chatDoc.get();
    if (chatSnapshot.exists) {
      List<dynamic> messages = chatSnapshot.data()?['messages'] ?? [];

      messages.removeWhere((message) {
        return message['sentAt'] != null && (message['sentAt'] as Timestamp).toDate().isAtSameMomentAs(sentAt);
      });

      await chatDoc.update({'messages': messages});
    }
  }

  Future<void> markMessagesAsRead(String currentUserId, String otherUserId) async {
    final chatId = generateChatID(uid1: currentUserId, uid2: otherUserId);
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    final chatSnapshot = await chatDoc.get();
    if (chatSnapshot.exists) {
      List<dynamic> messages = chatSnapshot.data()?['messages'] ?? [];

      final updatedMessages = messages.map((message) {
        if (message['senderID'] != currentUserId && message['read'] == false) {
          return {
            ...message,
            'read': true,
          };
        }
        return message;
      }).toList();

      await chatDoc.update({'messages': updatedMessages});
    }
  }

  Future<void> sendLocationToDatabase(LocationData location) async {
    final firestore = FirebaseFirestore.instance;
    print(location);
    await firestore.collection('malicious_users').add({
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': Timestamp.now(),
    });
  }


}



