import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/app.dart';
import 'core/network/api_client.dart';
import 'core/notifications/fcm_service.dart';
import 'core/storage/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final storage = TokenStorage();
  final apiClient = ApiClient(storage: storage);
  await FcmService().init(apiClient, storage);

  runApp(const FersalApp());
}
