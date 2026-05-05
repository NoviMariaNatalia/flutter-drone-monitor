class Drone {
  final String id;
  final String name;
  final String type;
  final String imageUrl;
  final bool isActive;
  final double latitude;
  final double longitude;
  final String location;

  Drone({
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.isActive,
    required this.latitude,
    required this.longitude,
    required this.location,
  });

  factory Drone.fromJson(Map<String, dynamic> json) {
    return Drone(
      id: json['drone_id'] ?? '',
      name: json['name'] ?? '-',
      type: json['type'] ?? '-',
      imageUrl: '',
      isActive: json['is_active'] ?? false, // ← dari field is_active
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      location: json['location'] ?? '-',
    );
  }
}