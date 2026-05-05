import 'dart:convert';
import 'package:http/http.dart' as http;

class DroneService {
  static const String baseUrl = 'http://xxx:8000/api'; // sesuaikan IP

  static Future<Map<String, dynamic>> registerDrone({
    required String droneId,
    required String name,
    required String type,
    required String location,
  }) async {
    try {
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
        final errors = data['errors'];
        String errorMsg = 'Terjadi kesalahan';
        if (errors != null) {
          errorMsg = errors.values.first[0];
        }
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  // Method baru: ambil daftar drone dari API
  static Future<List<Map<String, dynamic>>> getActiveDrones() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/drones'), // ← ganti dari /active-drones
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'];
        return list.map((e) => e as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}