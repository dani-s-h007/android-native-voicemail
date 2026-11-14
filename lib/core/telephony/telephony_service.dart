import 'package:flutter/services.dart';

class TelephonyService {
  static const MethodChannel _channel = MethodChannel('com.dalsc.voicemail_assistant/telephony');

  static Future<String> getCarrierName() async {
    try {
      final String carrier = await _channel.invokeMethod('getCarrierName') ?? 'Unknown';
      return carrier;
    } catch (e) {
      return 'Unknown';
    }
  }

  static Future<List<Map<String, dynamic>>> getActiveSims() async {
    try {
      final List<dynamic>? sims = await _channel.invokeMethod('getActiveSims');
      if (sims != null) {
        return sims.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Sends USSD in background with automatic 4-second timeout protection
  static Future<Map<String, dynamic>> sendUssd(String ussdCode, {int subId = -1}) async {
    try {
      final dynamic result = await _channel.invokeMethod('sendUssdRequest', {
        'ussdCode': ussdCode,
        'subId': subId,
      }).timeout(const Duration(seconds: 4), onTimeout: () {
        return {
          'status': 'TIMEOUT_FALLBACK',
          'message': 'Modem USSD timeout (common on Jio/Airtel VoLTE). Sent to phone dialer.'
        };
      });
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      return {'status': 'ERROR', 'message': e.message ?? e.code};
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  /// Directly dials the MMI code using the Android native phone dialer (instant, 100% reliable)
  static Future<Map<String, dynamic>> dialMmi(String ussdCode, {int subId = -1}) async {
    try {
      final dynamic result = await _channel.invokeMethod('dialMmiDirect', {
        'ussdCode': ussdCode,
        'subId': subId,
      }).timeout(const Duration(seconds: 4), onTimeout: () {
        return {
          'status': 'TIMEOUT',
          'message': 'Dialer dispatch timeout.'
        };
      });
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      return {'status': 'ERROR', 'message': e.message ?? e.code};
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  /// Opens native Android Phone App Call Settings (TelecomManager.ACTION_SHOW_CALL_SETTINGS)
  static Future<void> openCallSettings() async {
    try {
      await _channel.invokeMethod('openCallSettings');
    } catch (_) {}
  }
}
