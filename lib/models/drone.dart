class Drone {
  final String id;
  final String name;
  final String type;
  final bool isActive;
  final double latitude;
  final double longitude;
  final String location;
  final double floodHeight;

  Drone({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.latitude,
    required this.longitude,
    required this.location,
    this.floodHeight = 0.0,
  });

  factory Drone.fromJson(Map<String, dynamic> json) {
    return Drone(
      id: json['drone_id'] ?? '',
      name: json['name'] ?? '-',
      type: json['type'] ?? '-',
      isActive: json['is_active'] ?? false,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      location: json['location'] ?? '-',
      floodHeight: 0.0, // nanti ganti dari json['flood_height']
    );
  }
}