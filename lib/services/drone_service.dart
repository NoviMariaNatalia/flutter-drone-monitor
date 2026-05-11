import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/flood_report.dart';

class DroneService {
  static const String baseUrl = 'https://api-drone.heivet.com/api';

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

  static Future<List<FloodReport>> getFloodReports() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/flood-reports'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'];
        return list.map((e) => FloodReport.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> deleteDrone(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-drone/$id'), // pakai int id
        headers: {'Accept': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal menghapus drone'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }
}