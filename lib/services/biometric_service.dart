import 'package:local_auth/local_auth.dart';
import 'biometric_storage.dart';

class BiometricService {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    final available = await _auth.canCheckBiometrics;
    if (!available) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to continue',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isEnabled() => BiometricStorage.isEnabled();

  static Future<void> setEnabled(bool enabled) =>
      BiometricStorage.setEnabled(enabled);
}
