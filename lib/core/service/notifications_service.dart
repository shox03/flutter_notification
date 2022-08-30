import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_notification/data/data_source/local_source.dart';
import 'package:firebase_notification/data/keys/app_keys.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  final Map<String, dynamic> data = message.data;
  debugPrint("${message.data} DATAAA");
  flutterLocalNotificationsPlugin.show(
    0,
    data['title'],
    data['body'],
    NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannel.id,
        androidChannel.name,
        channelDescription: androidChannel.description,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        importance: Importance.max,
        priority: Priority.max,
      ),
      iOS: const IOSNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
        sound: 'default',
      ),
    ),
    payload: data['screen'],
  );
}

const AndroidNotificationChannel androidChannel = AndroidNotificationChannel(
  'fcm', // id
  'Application received', // title
  description:
      'THis channel is used for showing notifications about applications',
  importance: Importance.max,
);

class NotificationsService {
  NotificationsService._();

  static final NotificationsService _instance = NotificationsService._();

  static NotificationsService get getInstance => _instance;

  Future<void> initialize() async {
    final localSource = LocalSource.getInstance();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      localSource.setFcmToken(fcmToken ?? '');
    }
    debugPrint(AppKeys.FCM_TOKEN + " : " + localSource.getFcmToken());

    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        announcement: true,
        provisional: false,
      );
    }

    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    AndroidInitializationSettings androidNotificationSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidNotificationSettings,
      iOS: initializationSettingsIOS,
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (payload) {
        if (payload == '/ui') {
          // Get.toNamed(Routes.UI);
        }
      },
    );

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessageOpenedApp
        .listen(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(
      (remoteMessage) {
        final Map<String, dynamic> data = remoteMessage.data;
        flutterLocalNotificationsPlugin.show(
          0,
          data['title'],
          data['body'],
          NotificationDetails(
            android: AndroidNotificationDetails(
              androidChannel.id,
              androidChannel.name,
              channelDescription: androidChannel.description,
              icon: '@mipmap/ic_launcher',
              priority: Priority.max,
              importance: Importance.max,
              playSound: true,
            ),
            iOS: const IOSNotificationDetails(
              presentSound: true,
              presentAlert: true,
              presentBadge: true,
              sound: 'default',
            ),
          ),
          payload: data['screen'],
        );
      },
    );
  }
}
