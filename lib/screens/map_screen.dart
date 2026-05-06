import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';
import '../models/drone.dart';
import '../services/drone_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Drone? _selectedDrone;
  List<Drone> _drones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDrones();
  }

  Future<void> _fetchDrones() async {
    setState(() => _isLoading = true);

    final result = await DroneService.getActiveDrones();

    setState(() {
      _isLoading = false;
      _drones = result.map((json) => Drone.fromJson(json)).toList();
    });
  }

  void _showDroneDetail(Drone drone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: drone_id + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    drone.id,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location context
            const Text(
              'LOCATION CONTEXT',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              drone.location,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCoordBox('LAT', '${drone.latitude.toStringAsFixed(4)}° S'),
                const SizedBox(width: 24),
                _buildCoordBox('LONG', '${drone.longitude.toStringAsFixed(4)}° E'),
              ],
            ),
            const SizedBox(height: 16),

            // Ketinggian banjir (hardcode sementara)
            const Text(
              'KETINGGIAN BANJIR',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              drone.floodHeight > 0
                  ? '${drone.floodHeight.toStringAsFixed(1)} m'
                  : '-',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Foto banjir (placeholder, belum ada data)
            const Text(
              'FOTO BANJIR',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 36, color: AppColors.textSecondary),
                    SizedBox(height: 6),
                    Text(
                      'Belum ada foto',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.track_changes, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'TACTICALOBSERVER',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
        children: [
          // Map
          FlutterMap(
            options: MapOptions(
              initialCenter: () {
                // Cari drone aktif pertama yang punya koordinat valid
                final activeDrone = _drones.firstWhere(
                      (d) => d.isActive && d.latitude != 0 && d.longitude != 0,
                  orElse: () => Drone(
                    id: '', name: '', type: '', imageUrl: '',
                    isActive: false,
                    latitude: -6.9147, longitude: 107.6098,
                    location: '',
                  ),
                );
                return LatLng(activeDrone.latitude, activeDrone.longitude);
              }(),
              initialZoom: 11,
              onTap: (_, __) => setState(() => _selectedDrone = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_drone_monitor',
              ),
              MarkerLayer(
                markers: _drones
                    .where((drone) => drone.isActive && drone.latitude != 0 && drone.longitude != 0)
                    .map((drone) {
                  return Marker(
                    point: LatLng(drone.latitude, drone.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showDroneDetail(drone),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.router, color: Colors.white, size: 20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Live Telemetry Bar (atas)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _buildInfoBadge(
                  icon: Icons.circle,
                  iconColor: AppColors.live,
                  label: 'LIVE TELEMETRY',
                ),
                const SizedBox(width: 8),
                _buildInfoBadge(
                  icon: Icons.sensors,
                  iconColor: AppColors.primary,
                  label: '${_drones.where((d) => d.isActive).length} SENSORS ACTIVE',
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}