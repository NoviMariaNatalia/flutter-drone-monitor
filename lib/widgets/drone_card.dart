import 'package:flutter/material.dart';
import '../models/drone.dart';
import '../constants/app_colors.dart';

class DroneCard extends StatelessWidget {
  final Drone drone;

  const DroneCard({super.key, required this.drone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Info drone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drone.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  drone.type,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                // Tombol Start/Stop
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: drone.isActive
                        ? const Color(0xFFFA5858)  // merah → Stop Drone
                        : const Color(0xFFB2EBF2), // tosca → Start Drone
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    drone.isActive ? 'Stop Drone' : 'Start Drone',
                    style: TextStyle(
                      color: drone.isActive
                          ? Colors.white        // teks putih di atas merah
                          : const Color(0xFF677071), // teks #677071 di atas tosca
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Foto drone + status badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  drone.imageUrl,
                  width: 110,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 110,
                    height: 90,
                    color: AppColors.background,
                    child: const Icon(Icons.router, color: AppColors.textSecondary),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: drone.isActive ? AppColors.statusOn : AppColors.statusOff,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}