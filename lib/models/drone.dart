class Drone {
  final String id;
  final String name;
  final String type;
  final String imageUrl;
  final bool isActive;
  final double latitude;
  final double longitude;
  final String zone;

  Drone({
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.isActive,
    required this.latitude,
    required this.longitude,
    required this.zone,
  });
}

// Hardcode data sementara
final List<Drone> dummyDrones = [
  Drone(
    id: '001',
    name: 'Syma W2',
    type: 'Quadcopter',
    imageUrl: 'https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=400',
    isActive: true,
    latitude: -6.2088,
    longitude: 106.8456,
    zone: 'Ciliwung Basin • Zone A4',
  ),
  Drone(
    id: '002',
    name: 'DJI Mini 3',
    type: 'Quadcopter',
    imageUrl: 'https://images.unsplash.com/photo-1527977966376-1c8408f9f108?w=400',
    isActive: true,
    latitude: -6.1751,
    longitude: 106.8272,
    zone: 'Kanal Barat • Zone B2',
  ),
  Drone(
    id: '003',
    name: 'Autel EVO',
    type: 'Hexacopter',
    imageUrl: '',
    isActive: false,
    latitude: -6.2297,
    longitude: 106.8295,
    zone: 'Pesanggrahan • Zone C1',
  ),
];