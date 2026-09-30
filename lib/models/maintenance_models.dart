import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleService {
  final String id;
  final String userId;
  final String vehicleId;
  final String workshopName;
  final DateTime invoiceDate;
  final double totalAmount;
  final int odometerReading;
  final String? invoicePath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ServiceItem> items;

  VehicleService({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.workshopName,
    required this.invoiceDate,
    required this.totalAmount,
    required this.odometerReading,
    this.invoicePath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory VehicleService.fromJson(Map<String, dynamic> json) {
    return VehicleService(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      workshopName: json['workshop_name'] as String,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      odometerReading: json['odometer_reading'] as int,
      invoicePath: json['invoice_path'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: (json['service_items'] as List<dynamic>?)
              ?.map(
                  (item) => ServiceItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'workshop_name': workshopName,
      'invoice_date': invoiceDate.toIso8601String(),
      'total_amount': totalAmount,
      'odometer_reading': odometerReading,
      'invoice_path': invoicePath,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VehicleService copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? workshopName,
    DateTime? invoiceDate,
    double? totalAmount,
    int? odometerReading,
    String? invoicePath,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ServiceItem>? items,
  }) {
    return VehicleService(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      workshopName: workshopName ?? this.workshopName,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      totalAmount: totalAmount ?? this.totalAmount,
      odometerReading: odometerReading ?? this.odometerReading,
      invoicePath: invoicePath ?? this.invoicePath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

class ServiceItem {
  final String id;
  final String serviceId;
  final String category;
  final String? description;
  final double amount;
  final int quantity;
  final String? unit;
  final DateTime createdAt;

  ServiceItem({
    required this.id,
    required this.serviceId,
    required this.category,
    this.description,
    required this.amount,
    this.quantity = 1,
    this.unit,
    required this.createdAt,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'category': category,
      'description': description,
      'amount': amount,
      'quantity': quantity,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ServiceItem copyWith({
    String? id,
    String? serviceId,
    String? category,
    String? description,
    double? amount,
    int? quantity,
    String? unit,
    DateTime? createdAt,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MaintenanceSchedule {
  final String id;
  final String userId;
  final String vehicleId;
  final String componentName;
  final String componentKey;
  final int intervalKm;
  final int? intervalDays;
  final int? lastServiceKm;
  final DateTime? lastServiceDate;
  final int? nextDueKm;
  final DateTime? nextDueDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceSchedule({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.componentName,
    required this.componentKey,
    required this.intervalKm,
    this.intervalDays,
    this.lastServiceKm,
    this.lastServiceDate,
    this.nextDueKm,
    this.nextDueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) {
    return MaintenanceSchedule(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      componentName: json['component_name'] as String,
      componentKey: json['component_key'] as String,
      intervalKm: json['interval_km'] as int,
      intervalDays: json['interval_days'] as int?,
      lastServiceKm: json['last_service_km'] as int?,
      lastServiceDate: json['last_service_date'] != null
          ? DateTime.parse(json['last_service_date'] as String)
          : null,
      nextDueKm: json['next_due_km'] as int?,
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'component_name': componentName,
      'component_key': componentKey,
      'interval_km': intervalKm,
      'interval_days': intervalDays,
      'last_service_km': lastServiceKm,
      'last_service_date': lastServiceDate?.toIso8601String(),
      'next_due_km': nextDueKm,
      'next_due_date': nextDueDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MaintenanceSchedule copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? componentName,
    String? componentKey,
    int? intervalKm,
    int? intervalDays,
    int? lastServiceKm,
    DateTime? lastServiceDate,
    int? nextDueKm,
    DateTime? nextDueDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      componentName: componentName ?? this.componentName,
      componentKey: componentKey ?? this.componentKey,
      intervalKm: intervalKm ?? this.intervalKm,
      intervalDays: intervalDays ?? this.intervalDays,
      lastServiceKm: lastServiceKm ?? this.lastServiceKm,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextDueKm: nextDueKm ?? this.nextDueKm,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  MaintenanceStatus getStatus(int currentOdometer) {
    if (nextDueKm == null) return MaintenanceStatus.unknown;

    final kmRemaining = nextDueKm! - currentOdometer;

    if (kmRemaining < 0) return MaintenanceStatus.overdue;
    if (kmRemaining <= 1000) return MaintenanceStatus.dueSoon;
    return MaintenanceStatus.good;
  }

  int? getKmRemaining(int currentOdometer) {
    if (nextDueKm == null) return null;
    return nextDueKm! - currentOdometer;
  }

  int? getDaysRemaining() {
    if (nextDueDate == null) return null;
    return nextDueDate!.difference(DateTime.now()).inDays;
  }
}

enum MaintenanceStatus {
  good,
  dueSoon,
  overdue,
  unknown,
}

extension MaintenanceStatusExtension on MaintenanceStatus {
  String get label {
    switch (this) {
      case MaintenanceStatus.good:
        return 'OK';
      case MaintenanceStatus.dueSoon:
        return 'Due Soon';
      case MaintenanceStatus.overdue:
        return 'Overdue';
      case MaintenanceStatus.unknown:
        return 'Unknown';
    }
  }

  Color get color {
    switch (this) {
      case MaintenanceStatus.good:
        return const Color(0xFF4CAF50); // Green
      case MaintenanceStatus.dueSoon:
        return const Color(0xFFFFC107); // Yellow/Orange
      case MaintenanceStatus.overdue:
        return const Color(0xFFF44336); // Red
      case MaintenanceStatus.unknown:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}

class InvoiceExtractionResult {
  final String workshopName;
  final DateTime invoiceDate;
  final double totalAmount;
  final int odometerReading;
  final List<ServiceItem> items;

  InvoiceExtractionResult({
    required this.workshopName,
    required this.invoiceDate,
    required this.totalAmount,
    required this.odometerReading,
    this.items = const [],
  });

  factory InvoiceExtractionResult.fromJson(Map<String, dynamic> json) {
    return InvoiceExtractionResult(
      workshopName: json['workshop_name'] as String? ?? '',
      invoiceDate: json['invoice_date'] != null
          ? DateTime.parse(json['invoice_date'] as String)
          : DateTime.now(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      odometerReading: json['odometer_reading'] as int? ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map(
                  (item) => ServiceItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workshop_name': workshopName,
      'invoice_date': invoiceDate.toIso8601String(),
      'total_amount': totalAmount,
      'odometer_reading': odometerReading,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
