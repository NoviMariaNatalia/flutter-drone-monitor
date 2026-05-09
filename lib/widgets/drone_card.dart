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
        color: Colors.white,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drone ID
                Text(
                  drone.id,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                // Nama drone
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
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: drone.isActive
                        ? const Color(0xFFB2EBF2)
                        : const Color(0xFFFFCDD2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: drone.isActive
                              ? const Color(0xFF00838F)
                              : const Color(0xFFC62828),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        drone.isActive ? 'Active' : 'Offline',
                        style: TextStyle(
                          color: drone.isActive
                              ? const Color(0xFF677071)
                              : const Color(0xFFC62828),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tombol hapus di pojok kanan atas
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: null, // belum berfungsi
              icon: const Icon(
                Icons.delete_outline,
                color: Color(0xFFC62828),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Widget _placeholder() {
//   return Container(
//     width: 110,
//     height: 90,
//     decoration: BoxDecoration(
//       color: const Color(0xFFF5F6FA),
//       borderRadius: BorderRadius.circular(12),
//     ),
//     child: const Icon(Icons.flight, color: AppColors.textSecondary, size: 32),
//   );
// }
}