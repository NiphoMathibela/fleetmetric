import 'package:flutter/material.dart';
import '../models/fuel_models.dart';
import '../services/fuel_repository.dart';
import 'maintenance_dashboard.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final _repo = FuelRepository();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.getVehicles();
      setState(() {
        _vehicles = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vehicles: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _openVehicleForm([Vehicle? vehicle]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _VehicleFormSheet(
        vehicle: vehicle,
        onSaved: () {
          Navigator.pop(context);
          _fetchVehicles();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100f14),
      appBar: AppBar(
        title: const Text('Garage / Vehicles',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF100f14),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No vehicles added yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          backgroundColor: Color(int.parse('0xFFfca541')),
                        ),
                        onPressed: () => _openVehicleForm(),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Your First Vehicle',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.directions_car),
                        ),
                        title: Text(
                          '${vehicle.make} ${vehicle.model}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Reg: ${vehicle.registrationNumber}\nStarting Odo: ${vehicle.startingOdometer} km',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.build,
                                  color: Color(0xFFfca541)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MaintenanceDashboard(
                                      vehicleId: vehicle.id,
                                      vehicleName:
                                          '${vehicle.make} ${vehicle.model}',
                                    ),
                                  ),
                                );
                              },
                              tooltip: 'Maintenance',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openVehicleForm(vehicle),
                              tooltip: 'Edit Vehicle',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _vehicles.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openVehicleForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            )
          : null,
    );
  }
}

class _VehicleFormSheet extends StatefulWidget {
  final Vehicle? vehicle;
  final VoidCallback onSaved;

  const _VehicleFormSheet({this.vehicle, required this.onSaved});

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repo = FuelRepository();

  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _regController;
  late TextEditingController _odoController;

  bool _isLoading = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(text: widget.vehicle?.make ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _regController =
        TextEditingController(text: widget.vehicle?.registrationNumber ?? '');
    _odoController = TextEditingController(
        text: widget.vehicle?.startingOdometer.toString() ?? '0');
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final make = _makeController.text.trim();
      final model = _modelController.text.trim();
      final reg = _regController.text.trim().toUpperCase();
      final odo = int.tryParse(_odoController.text) ?? 0;

      if (_isEditing) {
        await _repo.updateVehicle(
          id: widget.vehicle!.id,
          make: make,
          model: model,
          registrationNumber: reg,
          startingOdometer: odo,
        );
      } else {
        await _repo.addVehicle(
          make: make,
          model: model,
          registrationNumber: reg,
          startingOdometer: odo,
        );
      }

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving vehicle: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Vehicle' : 'Add New Vehicle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _makeController,
              decoration:
                  const InputDecoration(labelText: 'Make (e.g. Audi, BMW)'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _modelController,
              decoration:
                  const InputDecoration(labelText: 'Model (e.g. A3, 323i)'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _regController,
              decoration:
                  const InputDecoration(labelText: 'Registration Number'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _odoController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Starting Odometer (km)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Update Vehicle' : 'Save Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}
