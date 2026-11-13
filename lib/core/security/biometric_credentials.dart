import 'dart:convert';
import 'dart:math';

import 'package:biometric_signature/biometric_signature.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

class BiometricCredentials {
  static const alias = 'fersal_auth';
  final BiometricSignature signer;
  BiometricCredentials({BiometricSignature? signer})
    : signer = signer ?? BiometricSignature();

  Future<void> enroll(ApiClient api) async {
    final email = await api.storage.getEmail();
    if (email == null || !await api.storage.hasSession()) {
      throw StateError('Primero inicia sesión con contraseña.');
    }
    final prefs = await SharedPreferences.getInstance();
    final oldId = prefs.getString('bio_remote_id');
    if (oldId != null) {
      try {
        await api.client.delete('/auth/devices/$oldId');
      } catch (_) {}
    }
    await signer.deleteKeys(keyAlias: alias);
    final keys = await signer.createKeys(
      keyAlias: alias,
      keyFormat: KeyFormat.pem,
      promptMessage: 'Usa tu huella para activar el acceso a FERSAL',
      config: CreateKeysConfig(
        signatureType: SignatureType.ecdsa,
        enforceBiometric: true,
        setInvalidatedByBiometricEnrollment: true,
        useDeviceCredentials: false,
        enableDecryption: false,
      ),
    );
    if (keys.code != BiometricError.success || keys.publicKey == null) {
      throw StateError('No se pudo registrar la clave biométrica.');
    }
    final random = Random.secure();
    final deviceId = base64UrlEncode(
      List.generate(32, (_) => random.nextInt(256)),
    );
    final response = await api.client.post(
      '/auth/devices',
      data: {
        'deviceId': deviceId,
        'publicKey': keys.publicKey,
        'nombre': 'FERSAL',
      },
    );
    await prefs.setString('bio_email', email.toLowerCase());
    await prefs.setString('bio_device_id', deviceId);
    await prefs.setString('bio_remote_id', response.data['id']);
  }

  Future<Map<String, dynamic>> login(ApiClient api, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('bio_device_id');
    if (deviceId == null ||
        prefs.getString('bio_email') != email.toLowerCase()) {
      throw StateError('Ingresa con contraseña y activa nuevamente la huella.');
    }
    final challenge = await api.client.post(
      '/auth/biometric/challenge',
      data: {'email': email, 'deviceId': deviceId},
    );
    final signed = await signer.createSignature(
      payload: challenge.data['challenge'],
      keyAlias: alias,
      promptMessage: 'Usa tu huella para ingresar a FERSAL',
      signatureFormat: SignatureFormat.base64,
      config: CreateSignatureConfig(allowDeviceCredentials: false),
    );
    if (signed.code != BiometricError.success || signed.signature == null) {
      throw StateError('No se pudo validar la huella.');
    }
    final response = await api.client.post(
      '/auth/biometric',
      data: {
        'email': email,
        'deviceId': deviceId,
        'challengeId': challenge.data['challengeId'],
        'signature': signed.signature,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> disable(ApiClient api) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('bio_remote_id');
    if (id != null && await api.storage.hasSession()) {
      try {
        await api.client.delete('/auth/devices/$id');
      } catch (_) {}
    }
    await signer.deleteKeys(keyAlias: alias);
    for (final key in ['bio_email', 'bio_device_id', 'bio_remote_id']) {
      await prefs.remove(key);
    }
  }
}
