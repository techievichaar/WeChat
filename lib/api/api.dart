import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/models/message.dart';

class APIs {
  /// for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;
  static get user => auth.currentUser!;

  // for storing self information
  static late ChatUser me;

  // for accesing cloud firestore databse
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

// for accesing firebase storage

  static FirebaseStorage storage = FirebaseStorage.instance;

// for checking if user exist

  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

// for getting current user info

  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        // for setting user active status
        APIs.updateActiveStatus(true);
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  // for creating new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatUser = ChatUser(
        image: user.photoURL.toString(),
        about: "Hey, I'm Using WeChat",
        name: user.displayName,
        createdAt: time,
        lastActive: time,
        id: user.uid,
        isOnline: false,
        email: user.email.toString(),
        pushToken: '');
    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

// for getting all user data from firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // for updating data  from profile screen to firestore

  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  // function for update profile picture
  static Future<void> updatePRofilePicture(File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child('profilepicture/${user.uid}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      print('Data Transfer: ${p0.bytesTransferred / 100} kb');
    });
    // updating image in firebase storage
    me.image = await ref.getDownloadURL();
    await firestore.collection('users').doc(user.uid).update({
      'image': me.image,
    });
  }
  // ************** Chat Screen Related APIs ****************

  // useful for getting conversation id
  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  // for geting all messages from firestore data base
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  // for sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    // Message to send
    final Message message = Message(
      msg: msg,
      toId: chatUser.id,
      read: '',
      type: type,
      fromId: user.uid,
      sent: time,
    );

    final ref = firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson());
  }

  // update message read status
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  // get llast messages of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  // get last message time ( use in chat user card)
  static String getLastMessageTime(
      {required BuildContext context, required String time}) {
    final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();
    if (now.day == sent.day &&
        now.month == sent.month &&
        now.year == sent.year) {
      return TimeOfDay.fromDateTime(sent).format(context);
    }

    return '${sent.day} ${_getMonth(sent)} ${sent.year}';
  }

  // get last message date month from no of index

  static String _getMonth(DateTime date) {
    switch (date.month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
    }
    return 'NA';
  }

  // chats ( collection --> coversationn_id (doc)) --> messegs (collection) --> messge(doc)

// send chat image and gifs
  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      print('Data Transfer: ${p0.bytesTransferred / 100} kb');
    });
    // updating image in firebase storage
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  // for getting specific user info for users online or offline logic
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('last_seen', isEqualTo: chatUser.id)
        .snapshots();
  }

  // logic for online or last active of user state

  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // For getting Firebase Messaging token
  static Future<void> getFirebaseMessagingToken() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await fMessaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // If permission is granted or provisional, get the token
        String? token = await fMessaging.getToken();
        if (token != null) {
          // Replace 'me.pushToken' with your actual variable where you want to store the token
          me.pushToken = token;
          print("Firebase Messaging Token: $token");
        } else {
          print("Failed to get Firebase Messaging token.");
        }
      } else {
        print("User declined or has not accepted permission.");
      }
    } catch (e) {
      print("An error occurred while getting Firebase Messaging token: $e");
    }
  }
}
