import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class RelayApiClient {
  // Live Render production backend URL
  static const String baseUrl = 'https://voicemail-relay.onrender.com';

  static Future<bool> registerDevice(String phoneNumber, String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/relay/register-device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'fcmToken': fcmToken,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("[RelayApiClient] Registration error: $e");
      return false;
    }
  }

  static Future<Uint8List> downloadEphemeralAudio(String downloadUrl, String token) async {
    final uri = Uri.parse('$downloadUrl?token=$token');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download audio file (HTTP ${response.statusCode})');
    }
  }

  static Future<bool> acknowledgeReceipt(String jobId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/relay/ack'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jobId': jobId,
          'token': token,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("[RelayApiClient] Error sending ACK: $e");
      return false;
    }
  }

  // --- DND Session Endpoints ---

  static Future<bool> activateDndSession({
    required String phoneNumber,
    required int expiresAt,
    required String mode,
    required File greetingFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/dnd/session'),
      );
      request.fields['phoneNumber'] = phoneNumber;
      request.fields['expiresAt'] = expiresAt.toString();
      request.fields['mode'] = mode;

      request.files.add(await http.MultipartFile.fromPath(
        'greetingFile',
        greetingFile.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print("[RelayApiClient] activateDndSession response: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("[RelayApiClient] activateDndSession error: $e");
      return false;
    }
  }

  static Future<bool> deactivateDndSession(String phoneNumber) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/dnd/session?phoneNumber=${Uri.encodeComponent(phoneNumber)}'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("[RelayApiClient] deactivateDndSession error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getDndStatus(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/dnd/status?phoneNumber=${Uri.encodeComponent(phoneNumber)}'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
