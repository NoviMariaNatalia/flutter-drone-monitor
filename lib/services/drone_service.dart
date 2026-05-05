import 'dart:convert';
import 'package:http/http.dart' as http;

class DroneService {
  // Ganti IP sesuai situasi:
  // - Emulator Android : 10.0.2.2
  // - HP Fisik         : IP WiFi laptop kamu (cek via ipconfig)
  static const String baseUrl = 'http://192.168.100.68:8000/api';

  static Future<Map<String, dynamic>> registerDrone({
    required String droneId,
    required String name,
    required String type,
    required String location,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register-drone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'drone_id': droneId,
        'name': name,
        'type': type,
        'location': location,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {'success': true, 'message': data['message']};
    } else {
      // Ambil pesan error dari Laravel (misal drone_id sudah terdaftar)
      final errors = data['errors'];
      String errorMsg = 'Terjadi kesalahan';
      if (errors != null) {
        errorMsg = errors.values.first[0];
      }
      return {'success': false, 'message': errorMsg};
    }
  }
}