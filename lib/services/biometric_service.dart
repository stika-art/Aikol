import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'supabase_service.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<bool> canAuthenticate() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
    await _storage.write(key: 'biometric_enabled', value: 'true');
  }

  static Future<void> disableBiometrics() async {
    await _storage.delete(key: 'biometric_enabled');
  }

  static Future<bool> isBiometricEnabled() async {
    final String? enabled = await _storage.read(key: 'biometric_enabled');
    return enabled == 'true';
  }

  static Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Подтвердите личность для входа в Aikol',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> tryBiometricLogin() async {
    if (!await isBiometricEnabled()) return false;

    final authenticated = await authenticate();
    if (!authenticated) return false;

    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');

    if (email != null && password != null) {
      try {
        await SupabaseService.signIn(email, password);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }
}
