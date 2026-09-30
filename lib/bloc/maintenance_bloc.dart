import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/maintenance_models.dart';
import '../repositories/maintenance_repository.dart';

// Events
abstract class MaintenanceEvent extends Equatable {
  const MaintenanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadMaintenanceData extends MaintenanceEvent {
  final String vehicleId;

  const LoadMaintenanceData(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class CreateService extends MaintenanceEvent {
  final String vehicleId;
  final String workshopName;
  final DateTime invoiceDate;
  final double totalAmount;
  final int odometerReading;
  final String? invoicePath;
  final String? notes;
  final List<ServiceItem> items;

  const CreateService({
    required this.vehicleId,
    required this.workshopName,
    required this.invoiceDate,
    required this.totalAmount,
    required this.odometerReading,
    this.invoicePath,
    this.notes,
    required this.items,
  });

  @override
  List<Object?> get props => [
        vehicleId,
        workshopName,
        invoiceDate,
        totalAmount,
        odometerReading,
        invoicePath,
        notes,
        items,
      ];
}

class DeleteService extends MaintenanceEvent {
  final String serviceId;

  const DeleteService(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class ExtractInvoiceData extends MaintenanceEvent {
  final String imagePath;

  const ExtractInvoiceData(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class UpdateMaintenanceSchedule extends MaintenanceEvent {
  final MaintenanceSchedule schedule;

  const UpdateMaintenanceSchedule(this.schedule);

  @override
  List<Object?> get props => [schedule];
}

// States
abstract class MaintenanceState extends Equatable {
  const MaintenanceState();

  @override
  List<Object?> get props => [];
}

class MaintenanceInitial extends MaintenanceState {}

class MaintenanceLoading extends MaintenanceState {}

class MaintenanceLoaded extends MaintenanceState {
  final List<MaintenanceSchedule> schedules;
  final List<VehicleService> services;
  final int currentOdometer;

  const MaintenanceLoaded({
    required this.schedules,
    required this.services,
    required this.currentOdometer,
  });

  @override
  List<Object?> get props => [schedules, services, currentOdometer];

  MaintenanceLoaded copyWith({
    List<MaintenanceSchedule>? schedules,
    List<VehicleService>? services,
    int? currentOdometer,
  }) {
    return MaintenanceLoaded(
      schedules: schedules ?? this.schedules,
      services: services ?? this.services,
      currentOdometer: currentOdometer ?? this.currentOdometer,
    );
  }
}

class MaintenanceError extends MaintenanceState {
  final String message;

  const MaintenanceError(this.message);

  @override
  List<Object?> get props => [message];
}

class InvoiceExtracting extends MaintenanceState {}

class InvoiceExtracted extends MaintenanceState {
  final InvoiceExtractionResult result;

  const InvoiceExtracted(this.result);

  @override
  List<Object?> get props => [result];
}

class ServiceCreating extends MaintenanceState {}

class ServiceCreated extends MaintenanceState {}

// BLoC
class MaintenanceBloc extends Bloc<MaintenanceEvent, MaintenanceState> {
  final MaintenanceRepository repository;

  MaintenanceBloc(this.repository) : super(MaintenanceInitial()) {
    on<LoadMaintenanceData>(_onLoadMaintenanceData);
    on<CreateService>(_onCreateService);
    on<DeleteService>(_onDeleteService);
    on<ExtractInvoiceData>(_onExtractInvoiceData);
    on<UpdateMaintenanceSchedule>(_onUpdateMaintenanceSchedule);
  }

  Future<void> _onLoadMaintenanceData(
    LoadMaintenanceData event,
    Emitter<MaintenanceState> emit,
  ) async {
    emit(MaintenanceLoading());
    try {
      final schedules =
          await repository.getMaintenanceSchedules(event.vehicleId);
      final services = await repository.getVehicleServices(event.vehicleId);
      final currentOdometer =
          await repository.getCurrentOdometer(event.vehicleId);

      emit(MaintenanceLoaded(
        schedules: schedules,
        services: services,
        currentOdometer: currentOdometer,
      ));
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> _onCreateService(
    CreateService event,
    Emitter<MaintenanceState> emit,
  ) async {
    emit(ServiceCreating());
    try {
      await repository.createVehicleService(
        vehicleId: event.vehicleId,
        workshopName: event.workshopName,
        invoiceDate: event.invoiceDate,
        totalAmount: event.totalAmount,
        odometerReading: event.odometerReading,
        notes: event.notes,
        items: event.items,
      );

      emit(ServiceCreated());

      // Reload data
      add(LoadMaintenanceData(event.vehicleId));
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> _onDeleteService(
    DeleteService event,
    Emitter<MaintenanceState> emit,
  ) async {
    try {
      await repository.deleteVehicleService(event.serviceId);
      // Reload data - need vehicleId from current state
      if (state is MaintenanceLoaded) {
        final loadedState = state as MaintenanceLoaded;
        if (loadedState.services.isNotEmpty) {
          final vehicleId = loadedState.services.first.vehicleId;
          add(LoadMaintenanceData(vehicleId));
        }
      }
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> _onExtractInvoiceData(
    ExtractInvoiceData event,
    Emitter<MaintenanceState> emit,
  ) async {
    emit(InvoiceExtracting());
    try {
      // This would be called with an actual file, for now placeholder
      // In real implementation, you'd pass the File object
      emit(MaintenanceError('File extraction not implemented yet'));
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> _onUpdateMaintenanceSchedule(
    UpdateMaintenanceSchedule event,
    Emitter<MaintenanceState> emit,
  ) async {
    try {
      await repository.updateMaintenanceSchedule(event.schedule);
      // Reload data
      if (state is MaintenanceLoaded) {
        final loadedState = state as MaintenanceLoaded;
        if (loadedState.schedules.isNotEmpty) {
          final vehicleId = loadedState.schedules.first.vehicleId;
          add(LoadMaintenanceData(vehicleId));
        }
      }
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }
}
