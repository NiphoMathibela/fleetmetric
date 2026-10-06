import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/maintenance_bloc.dart';
import '../repositories/maintenance_repository.dart';
import '../models/maintenance_models.dart';
import 'add_service_page.dart';
import 'edit_schedule_dialog.dart';

class MaintenanceDashboard extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const MaintenanceDashboard({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard> {
  late final MaintenanceBloc _maintenanceBloc;

  @override
  void initState() {
    super.initState();
    _maintenanceBloc = MaintenanceBloc(MaintenanceRepository());
    _maintenanceBloc.add(LoadMaintenanceData(widget.vehicleId));
  }

  @override
  void dispose() {
    _maintenanceBloc.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this page
    _maintenanceBloc.add(LoadMaintenanceData(widget.vehicleId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _maintenanceBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFF100f14),
        appBar: AppBar(
          title: Text('${widget.vehicleName} Maintenance',
              style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color(0xFF100f14),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () =>
                  _maintenanceBloc.add(LoadMaintenanceData(widget.vehicleId)),
            ),
          ],
        ),
        body: BlocBuilder<MaintenanceBloc, MaintenanceState>(
          builder: (context, state) {
            if (state is MaintenanceLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MaintenanceError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.message}',
                      style: const TextStyle(color: Color(0xFFf7f8f9)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _maintenanceBloc
                          .add(LoadMaintenanceData(widget.vehicleId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is MaintenanceLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  _maintenanceBloc.add(LoadMaintenanceData(widget.vehicleId));
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Odometer Display
                      _OdometerCard(currentOdometer: state.currentOdometer),
                      const SizedBox(height: 20),

                      // Maintenance Status Cards
                      const Text(
                        'Maintenance Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFf7f8f9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MaintenanceStatusGrid(
                        schedules: state.schedules,
                        currentOdometer: state.currentOdometer,
                        vehicleId: widget.vehicleId,
                      ),
                      const SizedBox(height: 24),

                      // Service History
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Service History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFf7f8f9),
                            ),
                          ),
                          Text(
                            '${state.services.length} services',
                            style: const TextStyle(
                              color: Color(0xFF7f7f81),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (state.services.isEmpty)
                        Container(
                          height: 180,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 48, color: Color(0xFF7f7f81)),
                              SizedBox(height: 12),
                              Text(
                                'No service records yet',
                                style: TextStyle(color: Color(0xFF7f7f81)),
                              ),
                            ],
                          ),
                        )
                      else
                        ...state.services.map((service) => _ServiceCard(
                              service: service,
                              repository: MaintenanceRepository(),
                              onDelete: () {
                                _maintenanceBloc.add(DeleteService(service.id));
                              },
                              onEdit: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddServicePage(
                                      vehicleId: widget.vehicleId,
                                      service: service,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _maintenanceBloc.add(
                                      LoadMaintenanceData(widget.vehicleId));
                                }
                              },
                            )),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFfca541),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddServicePage(vehicleId: widget.vehicleId),
              ),
            );
            if (result == true) {
              _maintenanceBloc.add(LoadMaintenanceData(widget.vehicleId));
            }
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label:
              const Text('Add Service', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class _OdometerCard extends StatelessWidget {
  final int currentOdometer;

  const _OdometerCard({required this.currentOdometer});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFfca541).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.speed,
                color: Color(0xFFfca541),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Odometer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7f7f81),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentOdometer.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]},',
                        )} km',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFf7f8f9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceStatusGrid extends StatelessWidget {
  final List<MaintenanceSchedule> schedules;
  final int currentOdometer;
  final String vehicleId;

  const _MaintenanceStatusGrid({
    required this.schedules,
    required this.currentOdometer,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final status = schedule.getStatus(currentOdometer);
        final kmRemaining = schedule.getKmRemaining(currentOdometer);

        return _MaintenanceStatusCard(
          schedule: schedule,
          status: status,
          kmRemaining: kmRemaining,
          currentOdometer: currentOdometer,
          vehicleId: vehicleId,
        );
      },
    );
  }
}

class _MaintenanceStatusCard extends StatelessWidget {
  final MaintenanceSchedule schedule;
  final MaintenanceStatus status;
  final int? kmRemaining;
  final int currentOdometer;
  final String vehicleId;

  const _MaintenanceStatusCard({
    required this.schedule,
    required this.status,
    this.kmRemaining,
    required this.currentOdometer,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status.color,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: Color(0xFF7f7f81),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                schedule.componentName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf7f8f9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (kmRemaining != null)
                Text(
                  kmRemaining! < 0
                      ? '${kmRemaining!.abs()} km overdue'
                      : '$kmRemaining km remaining',
                  style: TextStyle(
                    fontSize: 11,
                    color: status == MaintenanceStatus.overdue
                        ? Colors.red
                        : const Color(0xFF7f7f81),
                  ),
                ),
              if (schedule.lastServiceKm != null)
                Text(
                  'Last: ${schedule.lastServiceKm.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )} km',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7f7f81),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditScheduleDialog(
        schedule: schedule,
        currentOdometer: currentOdometer,
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        context.read<MaintenanceBloc>().add(LoadMaintenanceData(vehicleId));
      }
    });
  }
}

class _ServiceCard extends StatelessWidget {
  final VehicleService service;
  final MaintenanceRepository repository;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ServiceCard({
    required this.service,
    required this.repository,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      color: const Color(0xFF1C1C1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFfca541).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.receipt_long,
            color: Color(0xFFfca541),
            size: 20,
          ),
        ),
        title: Text(
          service.workshopName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFf7f8f9),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateFormat.format(service.invoiceDate),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7f7f81),
              ),
            ),
            Text(
              '${service.odometerReading.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},',
                  )} km • R ${service.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7f7f81),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFfca541), size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1C1C1E),
                    title: const Text('Delete Service',
                        style: TextStyle(color: Color(0xFFf7f8f9))),
                    content: const Text(
                        'Are you sure you want to delete this service record?',
                        style: TextStyle(color: Color(0xFF7f7f81))),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel',
                            style: TextStyle(color: Color(0xFFfca541))),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFf7f8f9),
                  ),
                ),
                const SizedBox(height: 8),
                if (service.items.isEmpty)
                  const Text(
                    'No items recorded',
                    style: TextStyle(color: Color(0xFF7f7f81)),
                  )
                else
                  ...service.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.description ?? item.category,
                                style: const TextStyle(
                                  color: Color(0xFFf7f8f9),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              'R ${item.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFFfca541),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),
                if (service.notes != null && service.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFf7f8f9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.notes!,
                    style: const TextStyle(
                      color: Color(0xFF7f7f81),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
