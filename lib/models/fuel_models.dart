enum FuelType { petrol95, petrol93, diesel }
enum PaymentMethod { creditCard, debitCard, cash }

class Vehicle {
  final String id;
  final String userId;
  final String make;
  final String model;
  final String registrationNumber;
  final int startingOdometer;
  final int currentOdometer;

  Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.registrationNumber,
    required this.startingOdometer,
    required this.currentOdometer,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      registrationNumber: json['registration_number']?.toString() ?? '',
      startingOdometer: json['starting_odometer'] as int? ?? 0,
      currentOdometer: json['current_odometer'] as int? ?? json['starting_odometer'] as int? ?? 0,
    );
  }
}

class FuelSlip {
  final String? id;
  final String vehicleId;
  final String merchantName;
  final DateTime transactionDate;
  final double totalAmount;
  final double pricePerUnit;
  final double volumeUnits;
  final int odometerReading;
  final String imagePath;
  final bool isVerified;

  FuelSlip({
    this.id,
    required this.vehicleId,
    required this.merchantName,
    required this.transactionDate,
    required this.totalAmount,
    required this.pricePerUnit,
    required this.volumeUnits,
    required this.odometerReading,
    required this.imagePath,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'vehicle_id': vehicleId,
      'merchant_name': merchantName,
      'transaction_date': transactionDate.toIso8601String().split('T')[0],
      'currency': 'ZAR',
      'total_amount': totalAmount,
      'price_per_unit': pricePerUnit,
      'volume_units': volumeUnits,
      'odometer_reading': odometerReading,
      'image_path': imagePath,
      'is_verified': isVerified,
    };
  }
}