import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:biometric_signature/biometric_signature.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fersal_app/core/network/api_client.dart';
import 'package:fersal_app/core/storage/token_storage.dart';
import 'package:fersal_app/core/security/biometric_credentials.dart';
import 'package:fersal_app/features/auth/data/auth_api.dart';
import 'package:fersal_app/features/auth/model/login_request.dart';
import 'package:fersal_app/features/dashboard/data/dashboard_repository.dart';
import 'package:fersal_app/features/dashboard/model/dashboard_model.dart';
import 'package:fersal_app/features/caja/data/caja_repository.dart';

class Adapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) respond;
  Adapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) => respond(o);
  @override
  void close({bool force = false}) {}
}

ResponseBody body(Object? value, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(value),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

class FakeSigner extends BiometricSignature {
  String? signedPayload;
  @override
  Future<bool> deleteKeys({String? keyAlias}) async => true;
  @override
  Future<KeyCreationResult> createKeys({
    String? keyAlias,
    CreateKeysConfig? config,
    KeyFormat keyFormat = KeyFormat.base64,
    String? promptMessage,
  }) async {
    expect(config!.enforceBiometric, isTrue);
    expect(keyFormat, KeyFormat.pem);
    return KeyCreationResult(
      code: BiometricError.success,
      publicKey: 'PUBLIC-KEY-TEST',
    );
  }

  @override
  Future<SignatureResult> createSignature({
    required String payload,
    String? keyAlias,
    CreateSignatureConfig? config,
    SignatureFormat signatureFormat = SignatureFormat.base64,
    KeyFormat keyFormat = KeyFormat.base64,
    String? promptMessage,
  }) async {
    signedPayload = payload;
    return SignatureResult(
      code: BiometricError.success,
      signature: 'SIGNED-TEST-CHALLENGE',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  test('El modelo de dashboard original conserva su formato sin cambios', () {
    final m = DashboardModel.fromJson({
      'ventasHoy': 200.5,
      'transaccionesHoy': 2,
      'gananciaHoy': 50.5,
      'totalPorCobrar': 30,
      'totalPorPagar': 0,
      'stockBajo': [
        {
          'productoId': 'p',
          'nombre': 'Producto',
          'stockActual': 2,
          'stockMinimo': 3,
        },
      ],
      'ultimasTransacciones': [
        {
          'ventaId': 'v',
          'numero': 'V-1',
          'cliente': 'Cliente',
          'total': 200.5,
          'tipoPago': 'CONTADO',
          'fecha': '2026-11-10T12:00:00',
        },
      ],
    });
    expect(m.ventasHoy, 200.5);
    expect(m.stockBajo.single.stockActual, 2);
    expect(m.ultimasTransacciones.single.ventaId, 'v');
  });
  test(
    'Huella: registra clave con sesión y firma un desafío de un solo uso',
    () async {
      final storage = TokenStorage();
      await storage.saveSession(
        'JWT',
        'u',
        'alberto@example.test',
        'Alberto',
        'e',
        'FERSAL',
        's',
        'Principal',
      );
      expect(
        (await SharedPreferences.getInstance()).getString('token'),
        isNull,
      );
      final api = ApiClient(storage: storage);
      final signer = FakeSigner();
      final credentials = BiometricCredentials(signer: signer);
      String? id;
      api.dio.httpClientAdapter = Adapter((o) async {
        if (o.path == '/auth/devices') {
          expect(o.headers['Authorization'], 'Bearer JWT');
          expect(o.data['publicKey'], 'PUBLIC-KEY-TEST');
          id = o.data['deviceId'];
          return body({'id': 'remote-id'}, 201);
        }
        if (o.path == '/auth/biometric/challenge') {
          expect(o.data['deviceId'], id);
          return body({
            'challengeId': 'challenge-id',
            'challenge': 'NONCE-FROM-SERVER',
          });
        }
        if (o.path == '/auth/biometric') {
          expect(o.data['signature'], 'SIGNED-TEST-CHALLENGE');
          expect(o.data['challengeId'], 'challenge-id');
          return body({'token': 'NEW-JWT'});
        }
        if (o.path == '/auth/devices/remote-id') {
          expect(o.method, 'DELETE');
          return body(null, 204);
        }
        fail('Ruta inesperada ${o.path}');
      });
      await credentials.enroll(api);
      expect(
        (await credentials.login(api, 'alberto@example.test'))['token'],
        'NEW-JWT',
      );
      expect(signer.signedPayload, 'NONCE-FROM-SERVER');
      await expectLater(
        credentials.login(api, 'otro@example.test'),
        throwsStateError,
      );
      await credentials.disable(api);
      await expectLater(
        credentials.login(api, 'alberto@example.test'),
        throwsStateError,
      );
      api.dio.close();
    },
  );
  test(
    'Repositorios originales aceptan respuestas PHP sin cambiar pantallas',
    () async {
      final api = ApiClient(storage: TokenStorage());
      api.dio.httpClientAdapter = Adapter((o) async {
        if (o.path == '/dashboard')
          return body({
            'ventasHoy': 0,
            'transaccionesHoy': 0,
            'gananciaHoy': 0,
            'totalPorCobrar': 0,
            'totalPorPagar': 0,
            'stockBajo': [],
            'ultimasTransacciones': [],
          });
        return body({
          'id': 'c',
          'saldoInicial': 100,
          'saldoFinal': 125,
          'totalIngresos': 25,
          'totalEgresos': 0,
          'fecha': '2026-11-10T12:00:00',
        });
      });
      expect(
        (await DashboardRepository(
          api,
        ).obtenerMetricas(empresaId: 'e', sucursalId: 's')).ventasHoy,
        0,
      );
      expect(
        (await CajaRepository(api).abrirCaja(
          empresaId: 'e',
          sucursalId: 's',
          usuarioId: 'u',
          saldoInicial: 100,
        )).saldoFinal,
        125,
      );
      api.dio.close();
    },
  );
  test('Login real contra dominio y lectura con cliente original', () async {
    HttpOverrides.global = null;
    final storage = TokenStorage();
    final api = ApiClient(storage: storage);
    try {
      final login = await AuthApi(api).login(
        LoginRequest(
          email: const String.fromEnvironment('FERSAL_TEST_EMAIL'),
          password: const String.fromEnvironment('FERSAL_TEST_PASSWORD'),
        ),
      );
      await storage.saveSession(
        login.token,
        login.usuarioId,
        login.email,
        login.name,
        login.empresaId,
        login.empresaNombre,
        login.sucursalId,
        login.sucursalNombre,
      );
      final result = await api.client.get('/auth/me');
      expect(result.statusCode, 200);
    } finally {
      await storage.logout();
      api.dio.close();
    }
  }, skip: !const bool.fromEnvironment('FERSAL_LIVE_CHECK'));
}
