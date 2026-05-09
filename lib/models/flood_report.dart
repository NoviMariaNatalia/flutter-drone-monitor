class FloodReport {
  final int id;
  final String droneId;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String waktu;
  final double? altitude; // TODO: uncomment saat /api/flood-reports sudah return field ini

  FloodReport({
    required this.id,
    required this.droneId,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.waktu,
    this.altitude,
  });

  factory FloodReport.fromJson(Map<String, dynamic> json) {
    return FloodReport(
      id: json['id'],
      droneId: json['drone_id'] ?? '-',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url'] ?? '',
      waktu: json['waktu'] ?? '-',
      // altitude: double.tryParse(json['altitude']?.toString() ?? '0') ?? 0.0,
      // TODO: uncomment baris di atas saat backend sudah return field 'altitude'
    );
  }
}