import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init(ApiClient apiClient, TokenStorage storage) async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      const channel = AndroidNotificationChannel(
        'fersal_channel',
        'Notificaciones FERSAL',
        description: 'Canal de notificaciones para caja, ventas y alertas',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Obtener el token único de este dispositivo
      final token = await _fcm.getToken();
      if (token != null) {
        print("==================================================");
        print("FCM TOKEN DE ESTE DISPOSITIVO:");
        print(token);
        print("==================================================");
        await sincronizarTokenConBackend(token, apiClient, storage);
      }

      // Escuchar si el token se renueva
      _fcm.onTokenRefresh.listen((newToken) {
        print("==================================================");
        print("FCM TOKEN RENOVADO:");
        print(newToken);
        print("==================================================");
        sincronizarTokenConBackend(newToken, apiClient, storage);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'fersal_channel',
                'Notificaciones FERSAL',
                channelDescription:
                    'Canal de notificaciones para caja, ventas y alertas',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@drawable/ic_notification',
                largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
                color: Color(0xFF1B62D4),
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> sincronizarTokenConBackend(
    String token,
    ApiClient apiClient,
    TokenStorage storage,
  ) async {
    try {
      final usuarioId = await storage.getUsuarioId();
      if (usuarioId != null && usuarioId.isNotEmpty) {
        await apiClient.client.put(
          '/usuarios/$usuarioId/fcm-token',
          data: {'token': token},
        );
      }
    } catch (_) {}
  }
}
