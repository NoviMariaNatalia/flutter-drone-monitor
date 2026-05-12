import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/drone.dart';
import '../widgets/drone_card.dart';
import '../widgets/add_drone_sheet.dart';
import '../services/drone_service.dart';
import 'dart:convert';
import '../services/websocket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Drone> _drones = [];
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _fetchDrones();
    _subscribeToMonitor();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchDrones() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    final result = await DroneService.getActiveDrones();

    setState(() {
      _isLoading = false;
      _drones = result.map((json) => Drone.fromJson(json)).toList();
    });
  }

  void _subscribeToMonitor() {
    WebSocketService.subscribeToMonitor(
      onStatusChanged: (data) {
        if (!mounted || data == null) return;

        final Map<String, dynamic> parsed =
        data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);

        print('[WS] Status changed: $parsed');

        final int? droneDbId = parsed['id'];
        final bool isOnline = parsed['status'] == 1 ||
            parsed['status'] == 'ONLINE' ||
            parsed['status'] == true;

        // Update status drone langsung tanpa fetch ulang
        setState(() {
          _drones = _drones.map((d) {
            if (d.dbId == droneDbId) {
              return Drone(
                dbId: d.dbId,
                id: d.id,
                name: d.name,
                type: d.type,
                isActive: isOnline,
                latitude: d.latitude,
                longitude: d.longitude,
                location: d.location,
              );
            }
            return d;
          }).toList();
        });
      },
    );
  }

  Future<void> _deleteDrone(Drone drone) async {
    if (drone.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa menghapus drone yang masih aktif!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validasi dbId ada
    if (drone.dbId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID drone tidak valid!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await DroneService.deleteDrone(drone.dbId!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success']
            ? AppColors.primary
            : Colors.red.shade600,
      ),
    );

    if (result['success']) {
      _fetchDrones(); // refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Hi, Hotman!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Welcome',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Konten utama
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const AddDroneSheet(),
          );
          // Refresh list setelah bottom sheet ditutup
          _fetchDrones();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    // State: loading
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // State: list kosong
    if (_drones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flight_land, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Belum ada drone terdaftar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDrones,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // State: data tersedia
    return RefreshIndicator(
      onRefresh: _fetchDrones, // pull to refresh
      color: AppColors.primary,
      child: ListView.builder(
        itemCount: _drones.length,
        itemBuilder: (context, index) {
          return DroneCard(
              drone: _drones[index],
              onDelete: () => _deleteDrone(_drones[index]),
          );
        },
      ),
    );
  }
}