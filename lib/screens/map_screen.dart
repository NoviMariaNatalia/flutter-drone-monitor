import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';
import '../models/drone.dart';
import '../models/flood_report.dart';
import '../services/drone_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Drone> _drones = [];
  List<FloodReport> _floodReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);

    // Fetch drone dan flood reports secara paralel
    final results = await Future.wait([
      DroneService.getActiveDrones(),
      DroneService.getFloodReports(),
    ]);

    setState(() {
      _isLoading = false;
      _drones = (results[0] as List)
          .map((json) => Drone.fromJson(json as Map<String, dynamic>))
          .toList();
      _floodReports = results[1] as List<FloodReport>;
    });
  }

  // Grouping flood reports yang koordinatnya sangat berdekatan (radius < 50 meter)
  Map<String, List<FloodReport>> _groupFloodReports() {
    const double threshold = 0.0005; // ~50 meter
    Map<String, List<FloodReport>> groups = {};

    for (final report in _floodReports) {
      String? assignedKey;

      for (final key in groups.keys) {
        final parts = key.split(',');
        final groupLat = double.parse(parts[0]);
        final groupLng = double.parse(parts[1]);

        if ((report.latitude - groupLat).abs() < threshold &&
            (report.longitude - groupLng).abs() < threshold) {
          assignedKey = key;
          break;
        }
      }

      if (assignedKey != null) {
        groups[assignedKey]!.add(report);
      } else {
        final key = '${report.latitude},${report.longitude}';
        groups[key] = [report];
      }
    }

    return groups;
  }

  // Popup detail drone (existing)
  void _showDroneDetail(Drone drone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDroneDetailSheet(drone),
    );
  }

  // Popup detail titik banjir (baru)
  void _showFloodDetail(FloodReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFloodDetailSheet(report),
    );
  }

  void _showFullscreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Foto Banjir',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          body: Center(
            child: InteractiveViewer( // ← bisa pinch-to-zoom
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator(color: Colors.white);
                },
              ),
            ),
          ),
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
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary),
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
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _getInitialCenter(),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                'com.example.flutter_drone_monitor',
              ),

              // Layer 1: Marker titik banjir (merah) — pakai grouping
              MarkerLayer(
                markers: () {
                  final groups = _groupFloodReports();
                  return groups.entries.map((entry) {
                    final parts = entry.key.split(',');
                    final point = LatLng(
                      double.parse(parts[0]),
                      double.parse(parts[1]),
                    );
                    return _buildFloodClusterMarker(point, entry.value);
                  }).toList();
                }(),
              ),

              // Layer 2: Marker posisi drone aktif (biru/primary) — di atas banjir
              MarkerLayer(
                markers: _drones
                    .where((d) =>
                d.isActive &&
                    d.latitude != 0 &&
                    d.longitude != 0)
                    .map((drone) => _buildDroneMarker(drone))
                    .toList(),
              ),
            ],
          ),

          // Info badges di atas
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoBadge(
                      icon: Icons.water,
                      iconColor: Colors.red,
                      label: '${_floodReports.length} FLOOD POINTS',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Legend di pojok kanan bawah
          Positioned(
            bottom: 20,
            right: 12,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  LatLng _getInitialCenter() {
    // Prioritas: drone aktif → titik banjir → default Bandung
    final activeDrone = _drones.firstWhere(
          (d) => d.isActive && d.latitude != 0 && d.longitude != 0,
      orElse: () => Drone(
        id: '', name: '', type: '',
        isActive: false,
        latitude: 0, longitude: 0, location: '',
      ),
    );

    if (activeDrone.latitude != 0) {
      return LatLng(activeDrone.latitude, activeDrone.longitude);
    }

    if (_floodReports.isNotEmpty) {
      return LatLng(_floodReports.first.latitude, _floodReports.first.longitude);
    }

    return const LatLng(-6.9147, 107.6098); // Default: Bandung
  }

  Marker _buildDroneMarker(Drone drone) {
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
  }

  // Marker untuk cluster (bisa berisi 1 atau lebih report)
  Marker _buildFloodClusterMarker(LatLng point, List<FloodReport> reports) {
    final isCluster = reports.length > 1;

    return Marker(
      point: point,
      width: isCluster ? 44 : 36,
      height: isCluster ? 44 : 36,
      child: GestureDetector(
        onTap: () => isCluster
            ? _showFloodClusterDetail(reports)
            : _showFloodDetail(reports.first),
        child: Stack(
          children: [
            Container(
              width: isCluster ? 44 : 36,
              height: isCluster ? 44 : 36,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.water, color: Colors.white, size: 18),
            ),
            // Badge jumlah jika cluster
            if (isCluster)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      '${reports.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFloodClusterDetail(List<FloodReport> reports) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar + header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.water,
                                  size: 12, color: Colors.red.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${reports.length} FLOOD REPORTS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'di area ini',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List semua report
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showFloodDetail(report);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            // Thumbnail foto
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: report.imageUrl.isNotEmpty
                                  ? Image.network(
                                report.imageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildMiniPlaceholder(),
                              )
                                  : _buildMiniPlaceholder(),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      report.droneId,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    report.waktu,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Lat: ${report.latitude.toStringAsFixed(5)}, '
                                        'Lng: ${report.longitude.toStringAsFixed(5)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlaceholder() {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined,
          size: 24, color: AppColors.textSecondary),
    );
  }

  Widget _buildDroneDetailSheet(Drone drone) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          const Text('LOCATION CONTEXT',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(drone.location,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCoordBox('LAT', '${drone.latitude.toStringAsFixed(4)}° S'),
              const SizedBox(width: 24),
              _buildCoordBox('LONG', '${drone.longitude.toStringAsFixed(4)}° E'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFloodDetailSheet(FloodReport report) {
    return Container(
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: badge merah "FLOOD REPORT" + drone_id
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.water, size: 12, color: Colors.red.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'FLOOD REPORT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.droneId,
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

          // Koordinat
          Row(
            children: [
              _buildCoordBox('LAT', '${report.latitude.toStringAsFixed(4)}° S'),
              const SizedBox(width: 24),
              _buildCoordBox('LONG', '${report.longitude.toStringAsFixed(4)}° E'),
            ],
          ),
          const SizedBox(height: 16),

          // Ketinggian banjir
          const Text('KETINGGIAN BANJIR',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(
            report.altitude != null && report.altitude! > 0
                ? '${report.altitude!.toStringAsFixed(1)} m'
                : '-',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Waktu pengambilan foto
          const Text('WAKTU DETEKSI',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(
            report.waktu,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Foto banjir
          const Text('FOTO BANJIR',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 8),
          if (report.imageUrl.isNotEmpty)
            GestureDetector(
              // Tap foto → fullscreen
              onTap: () => _showFullscreenImage(report.imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  report.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.fitWidth, // ← tampilkan lebar penuh, tinggi menyesuaikan
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 220,
                      color: AppColors.background,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                ),
              ),
            )
          else
            _buildImagePlaceholder(),
          // Hint tap fullscreen
          if (report.imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.fullscreen, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Tap untuk perbesar',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
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
            Text('Belum ada foto',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem(Colors.blue.shade700, Icons.router, 'Drone Aktif'),
          const SizedBox(height: 6),
          _buildLegendItem(Colors.red.shade600, Icons.water, 'Titik Banjir'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildCoordBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}