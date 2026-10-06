import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/maintenance_models.dart';
import '../repositories/maintenance_repository.dart';

class EditScheduleDialog extends StatefulWidget {
  final MaintenanceSchedule schedule;
  final int currentOdometer;

  const EditScheduleDialog({
    super.key,
    required this.schedule,
    required this.currentOdometer,
  });

  @override
  State<EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends State<EditScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _maintenanceRepo = MaintenanceRepository();

  late TextEditingController _intervalKmController;
  late TextEditingController _intervalDaysController;
  late TextEditingController _notesController;

  bool _isLoading = false;
  bool _enableNotification = true;

  @override
  void initState() {
    super.initState();
    _intervalKmController =
        TextEditingController(text: widget.schedule.intervalKm.toString());
    _intervalDaysController = TextEditingController(
        text: widget.schedule.intervalDays?.toString() ?? '');
    _notesController = TextEditingController(text: widget.schedule.notes ?? '');
  }

  @override
  void dispose() {
    _intervalKmController.dispose();
    _intervalDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final intervalKm = int.tryParse(_intervalKmController.text) ?? 0;
      final intervalDays = _intervalDaysController.text.trim().isEmpty
          ? null
          : int.tryParse(_intervalDaysController.text);

      // Calculate next due values
      final lastServiceKm = widget.schedule.lastServiceKm ?? widget.currentOdometer;
      final nextDueKm = lastServiceKm + intervalKm;

      DateTime? nextDueDate;
      if (intervalDays != null && widget.schedule.lastServiceDate != null) {
        nextDueDate = widget.schedule.lastServiceDate!.add(Duration(days: intervalDays));
      }

      final updatedSchedule = widget.schedule.copyWith(
        intervalKm: intervalKm,
        intervalDays: intervalDays,
        nextDueKm: nextDueKm,
        nextDueDate: nextDueDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await _maintenanceRepo.updateMaintenanceSchedule(updatedSchedule);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating schedule: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      title: Text(
        'Edit ${widget.schedule.componentName}',
        style: const TextStyle(color: Color(0xFFf7f8f9)),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Service Interval',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf7f8f9),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _intervalKmController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFFf7f8f9)),
                decoration: const InputDecoration(
                  labelText: 'Interval (km)',
                  labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7f7f81)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFfca541)),
                  ),
                  suffixText: 'km',
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Invalid number';
                  if (int.parse(value) <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _intervalDaysController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFFf7f8f9)),
                decoration: const InputDecoration(
                  labelText: 'Interval (days) - Optional',
                  labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7f7f81)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFfca541)),
                  ),
                  suffixText: 'days',
                  helperText: 'Leave empty for km-based only',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Current Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf7f8f9),
                ),
              ),
              const SizedBox(height: 12),
              _StatusRow(
                label: 'Last Service',
                value: widget.schedule.lastServiceKm != null
                    ? '${widget.schedule.lastServiceKm} km'
                    : 'Not yet serviced',
              ),
              _StatusRow(
                label: 'Last Service Date',
                value: widget.schedule.lastServiceDate != null
                    ? dateFormat.format(widget.schedule.lastServiceDate!)
                    : 'Not recorded',
              ),
              _StatusRow(
                label: 'Next Due (km)',
                value: '${widget.schedule.nextDueKm ?? 0} km',
              ),
              _StatusRow(
                label: 'Next Due (date)',
                value: widget.schedule.nextDueDate != null
                    ? dateFormat.format(widget.schedule.nextDueDate!)
                    : 'Not set',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(color: Color(0xFFf7f8f9)),
                decoration: const InputDecoration(
                  labelText: 'Notes - Optional',
                  labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7f7f81)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFfca541)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF7f7f81)),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSchedule,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFfca541),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatusRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7f7f81),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFf7f8f9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
