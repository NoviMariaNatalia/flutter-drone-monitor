import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/drone_service.dart';

class AddDroneSheet extends StatefulWidget {
  const AddDroneSheet({super.key});

  @override
  State<AddDroneSheet> createState() => _AddDroneSheetState();
}

class _AddDroneSheetState extends State<AddDroneSheet> {
  final _formKey = GlobalKey<FormState>();
  final _droneIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;

  final List<String> _droneTypes = [
    'Quadcopter',
    'Hexacopter',
    'Octocopter',
    'Fixed Wing',
  ];
  String _selectedType = 'Quadcopter';

  @override
  void dispose() {
    _droneIdController.dispose();
    _nameController.dispose();
    _typeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await DroneService.registerDrone(
      droneId: _droneIdController.text.trim(),
      name: _nameController.text.trim(),
      type: _selectedType,
      location: _locationController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: const Color(0xFF3AC9D8),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tambah Drone Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Field Drone ID
            _buildLabel('Drone ID'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _droneIdController,
              decoration: _inputDecoration('Contoh: drone-01'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Drone ID tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Field Nama Drone
            _buildLabel('Nama Drone'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Contoh: Syma W2'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama drone tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Dropdown Tipe Drone
            _buildLabel('Tipe Drone'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: _inputDecoration(''),
              items: _droneTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 14),

            // Field Lokasi
            _buildLabel('Lokasi'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _locationController,
              decoration: _inputDecoration('Contoh: Ciliwung Basin'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Lokasi tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Tombol Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Daftarkan Drone',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}