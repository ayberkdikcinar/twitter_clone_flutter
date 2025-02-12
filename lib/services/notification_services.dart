import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../model/user_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final firebaseMesg = FirebaseMessaging.instance;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  NotificationService.showNotification(message.data);
}

Future<void> init() async {
  await firebaseMesg.requestPermission();
  final token = await firebaseMesg.getToken();
  print('token: ' + token);
}

//
//
class NotificationService {
  static final NotificationService _instance = NotificationService._init();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._init();
  FirebaseFirestore _firebase = FirebaseFirestore.instance;

  initializeNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

    /// Note: permissions aren't requested here just to demonstrate that can be
    /// done later
    final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(onDidReceiveLocalNotification: onDidReceiveLocalNotification);

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: onSelectedNotification);

    FirebaseMessaging.onMessage.listen((event) {
      showNotification(event.data);
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> showNotification(Map<String, dynamic> message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('1234', 'new message', 'our description', importance: Importance.max, priority: Priority.high, ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, message['title'].toString(), message['message'].toString(), platformChannelSpecifics, payload: 'payloadumuz');
  }

  static Future<void> saveUserToken(String id) async {
    final _tokenCollection = FirebaseFirestore.instance.collection('token');
    final token = await firebaseMesg.getToken();
    await _tokenCollection.doc(id).set({'token': token});
  }

  Future<String> getUserToken(String id) async {
    final _tokenCollection = FirebaseFirestore.instance.collection('token');
    var _docref = await _tokenCollection.doc(id).get();
    return _docref.data()['token'];
  }

  Future<void> sendNotification(UserModel guestUser, String ownerId) async {
    var url = Uri.parse("https://fcm.googleapis.com/fcm/send");
    String title = 'Takip';
    String message = '${guestUser.username} adlı kullanıcı seni takip etti';
    String token = await getUserToken(ownerId);
    var _response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAA1zTcS4A:APA91bGNpvTFYFkaFopO_nMJr3DWbW3zeL4jRqIAMA_QhZmG5bnBld_QxmOnKMazYt9eNx9uizGpL3EKC-8kwBFQFllbiCp6O54OaOQpth1H_DYToy-5D4LGZyYU2YBXUZccuwRBvf10'
      },
      body: jsonEncode({
        "to": "$token",
        "data": {"title": "$title", "message": "$message"}
      }),
    );
    if (_response.statusCode == HttpStatus.ok) {
      //await saveNotificationToDB(guestUser, ownerId, 'follow');
      return;
    }
  }

  Future<void> saveNotificationToDB(UserModel guestUser, String ownerId, String typeOfNotification) async {
    var _content = '';
    if (typeOfNotification == 'follow') {
      _content = '${guestUser.username} has just followed you';
    }
    _firebase
        .collection('users')
        .doc(ownerId)
        .collection('notifications')
        .doc()
        .set({'id': '', 'type': '$typeOfNotification', 'from': '${guestUser.id}', 'content': '$_content', 'time': '${Timestamp.now()}'});
  }

  Future<void> deleteNotificationFromDB(String guestUserId, String ownerId, String typeOfNotification) async {
    var _querySnapshot = await _firebase
        .collection('users')
        .doc(ownerId)
        .collection('notifications')
        .where('type', isEqualTo: 'follow')
        .where('from', isEqualTo: '$guestUserId')
        .get();
    print('len:' + _querySnapshot.docs.length.toString());
    print(guestUserId);
    var _docId = _querySnapshot.docs.first.id;
    await _firebase.collection('users').doc(ownerId).collection('notifications').doc(_docId).delete();
  }

  Future<List<String>> getNotification(String userId) async {
    var _querySnapshot = await _firebase.collection('users').doc(userId).collection('notifications').get();
    return _querySnapshot.docs.map((e) => e.data()['content'].toString()).toList();
  }

  Future onDidReceiveLocalNotification(int id, String title, String body, String payload) {
    //
    //
    return null;
  }

  Future onSelectedNotification(String payload) {
    if (payload != null) {
      print('payload: ' + payload);
    }
    return null;
  }
}
