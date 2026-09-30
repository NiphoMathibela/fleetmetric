import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fuel_models.dart';

class FuelRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  // --- VEHICLES ---

  Future<List<Vehicle>> getVehicles() async {
    final response = await _supabase
        .from('vehicles')
        .select()
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Vehicle.fromJson(json)).toList();
  }

  Future<Vehicle> addVehicle({
    required String make,
    required String model,
    required String registrationNumber,
    required int startingOdometer,
  }) async {
    final response = await _supabase
        .from('vehicles')
        .insert({
          'user_id': _currentUserId,
          'make': make,
          'model': model,
          'registration_number': registrationNumber,
          'starting_odometer': startingOdometer,
        })
        .select()
        .single();

    return Vehicle.fromJson(response);
  }

  Future<void> updateVehicle({
    required String id,
    required String make,
    required String model,
    required String registrationNumber,
    required int startingOdometer,
  }) async {
    await _supabase
        .from('vehicles')
        .update({
          'make': make,
          'model': model,
          'registration_number': registrationNumber,
          'starting_odometer': startingOdometer,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', _currentUserId);
  }

  // --- STORAGE & FUEL SLIPS ---

  Future<String> uploadSlipImage(File imageFile) async {
    final userId = _currentUserId;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';

    await _supabase.storage.from('fuel-slips').upload(
          path,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return path;
  }

  /// Saves the complete fuel slip record to PostgreSQL
  Future<void> saveFuelSlip({
    required File imageFile,
    required String vehicleId,
    required String merchantName,
    required double totalAmount,
    required double vatAmount,
    required double pricePerUnit,
    required double volumeUnits,
    required int odometerReading,
    required DateTime transactionDate,
  }) async {
    // 1. Upload image
    final imagePath = await uploadSlipImage(imageFile);

    // 2. Fetch last fuel slip to calculate distance & consumption
    final lastSlip = await getLatestFuelSlip(vehicleId);
    double? distanceDriven;
    double? consumptionL100km;

    if (lastSlip != null && lastSlip['odometer_reading'] != null) {
      final prevOdo = lastSlip['odometer_reading'] as int;
      if (odometerReading > prevOdo) {
        distanceDriven = (odometerReading - prevOdo).toDouble();
        consumptionL100km = (volumeUnits / distanceDriven) * 100;
      }
    }

    // 3. Prepare payload
    final slipData = {
      'user_id': _currentUserId,
      'vehicle_id': vehicleId,
      'merchant_name': merchantName,
      'transaction_date': transactionDate.toIso8601String(),
      'total_amount': totalAmount,
      'vat_amount': vatAmount,
      'price_per_unit': pricePerUnit,
      'volume_units': volumeUnits,
      'odometer_reading': odometerReading,
      'image_path': imagePath,
      'distance_driven': distanceDriven,
      'consumption_l_100km': consumptionL100km,
    };

    await _supabase.from('fuel_slips').insert(slipData);
  }

  Future<String> getSignedImageUrl(String imagePath) async {
    return await _supabase.storage
        .from('fuel-slips')
        .createSignedUrl(imagePath, 60 * 60);
  }

  Future<List<Map<String, dynamic>>> getFuelSlips() async {
    final response = await _supabase
        .from('fuel_slips')
        .select('*, vehicles(make, model, registration_number)')
        .eq('user_id', _currentUserId)
        .order('transaction_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // --- ANALYTICS & MAINTENANCE METHODS ---

  /// Gets the most recent fuel slip for a specific vehicle
  Future<Map<String, dynamic>?> getLatestFuelSlip(String vehicleId) async {
    final response = await _supabase
        .from('fuel_slips')
        .select()
        .eq('user_id', _currentUserId)
        .eq('vehicle_id', vehicleId)
        .order('transaction_date', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  /// Gets latest odometer reading recorded for a vehicle
  Future<int> getLatestOdometer(String vehicleId) async {
    final lastSlip = await getLatestFuelSlip(vehicleId);
    if (lastSlip != null && lastSlip['odometer_reading'] != null) {
      return lastSlip['odometer_reading'] as int;
    }

    // Fall back to vehicle starting odometer if no fuel slips exist
    final vehicleResponse = await _supabase
        .from('vehicles')
        .select('starting_odometer')
        .eq('id', vehicleId)
        .single();

    return vehicleResponse['starting_odometer'] as int? ?? 0;
  }

  /// Gets historical L/100km figures for anomaly detection and trend charts
  Future<List<double>> getHistoricalL100km(String vehicleId) async {
    final response = await _supabase
        .from('fuel_slips')
        .select('consumption_l_100km')
        .eq('user_id', _currentUserId)
        .eq('vehicle_id', vehicleId)
        .not('consumption_l_100km', 'is', null)
        .order('transaction_date', ascending: true);

    return (response as List)
        .map((e) => (e['consumption_l_100km'] as num).toDouble())
        .toList();
  }

  /// Fetches maintenance schedules for a given vehicle
  Future<List<Map<String, dynamic>>> getMaintenanceSchedules(
      String vehicleId) async {
    final response = await _supabase
        .from('maintenance_schedules')
        .select()
        .eq('user_id', _currentUserId)
        .eq('vehicle_id', vehicleId);

    return List<Map<String, dynamic>>.from(response);
  }

  // --- DASHBOARD ANALYTICS ---

  /// Gets fuel slips for a specific vehicle for dashboard calculations
  Future<List<Map<String, dynamic>>> getFuelSlipsForVehicle(
      String vehicleId) async {
    final response = await _supabase
        .from('fuel_slips')
        .select()
        .eq('user_id', _currentUserId)
        .eq('vehicle_id', vehicleId)
        .order('transaction_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Gets fuel slips filtered by date range (for dashboard metrics)
  Future<List<Map<String, dynamic>>> getFuelSlipsByDateRange({
    String? vehicleId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    var query = _supabase
        .from('fuel_slips')
        .select('*, vehicles(make, model, registration_number)')
        .eq('user_id', _currentUserId)
        .gte('transaction_date', startDate.toIso8601String())
        .lte('transaction_date', endDate.toIso8601String());

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    final response = await query.order('transaction_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Calculates total liters for a date range
  Future<double> calculateTotalLiters({
    String? vehicleId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final slips = await getFuelSlipsByDateRange(
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
    );

    double total = 0.0;
    for (final slip in slips) {
      total += (slip['volume_units'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// Calculates total spend for a date range
  Future<double> calculateTotalSpend({
    String? vehicleId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final slips = await getFuelSlipsByDateRange(
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
    );

    double total = 0.0;
    for (final slip in slips) {
      total += (slip['total_amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// Calculates total distance for a date range
  Future<double> calculateTotalDistance({
    String? vehicleId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final slips = await getFuelSlipsByDateRange(
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
    );

    double total = 0.0;
    for (final slip in slips) {
      total += (slip['distance_driven'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// Calculates average L/100km for a date range
  Future<double> calculateAvgL100kmForRange({
    String? vehicleId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final slips = await getFuelSlipsByDateRange(
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
    );

    final validSlips =
        slips.where((s) => s['consumption_l_100km'] != null).toList();
    if (validSlips.isEmpty) return 0.0;

    final total = validSlips.fold(0.0,
        (sum, slip) => sum + ((slip['consumption_l_100km'] as num).toDouble()));

    return total / validSlips.length;
  }

  /// Calculates monthly forecast based on last 30 days of spending
  Future<double> calculateMonthlyForecast(String vehicleId) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final response = await _supabase
        .from('fuel_slips')
        .select('total_amount')
        .eq('user_id', _currentUserId)
        .eq('vehicle_id', vehicleId)
        .gte('transaction_date', thirtyDaysAgo.toIso8601String());

    if (response.isEmpty) return 0.0;

    final total = (response as List).fold(
        0.0,
        (sum, slip) =>
            sum + ((slip['total_amount'] as num?)?.toDouble() ?? 0.0));

    return total;
  }

  /// Calculates average cost per km for a vehicle
  Future<double> calculateAvgCostPerKm(String vehicleId) async {
    final slips = await getFuelSlipsForVehicle(vehicleId);
    if (slips.isEmpty) return 0.0;

    double totalCost = 0.0;
    double totalDistance = 0.0;

    for (int i = 0; i < slips.length; i++) {
      final slip = slips[i];
      totalCost += (slip['total_amount'] as num?)?.toDouble() ?? 0.0;

      if (slip['distance_driven'] != null) {
        totalDistance += (slip['distance_driven'] as num).toDouble();
      }
    }

    if (totalDistance == 0) return 0.0;
    return totalCost / totalDistance;
  }

  /// Calculates current average L/100km for a vehicle
  Future<double> calculateCurrentAvgL100km(String vehicleId) async {
    final historical = await getHistoricalL100km(vehicleId);
    if (historical.isEmpty) return 0.0;

    return historical.reduce((a, b) => a + b) / historical.length;
  }

  /// Gets efficiency history (date and L/100km) for chart
  Future<List<Map<String, dynamic>>> getEfficiencyHistory(
      String vehicleId) async {
    final response = await _supabase
        .from('fuel_slips')
        .select('transaction_date, consumption_l_100km')
        .eq('user_id', _currentUserId)
        .eq('vehicle_id', vehicleId)
        .not('consumption_l_100km', 'is', null)
        .order('transaction_date', ascending: true)
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Deletes a fuel slip by ID
  Future<void> deleteFuelSlip(String slipId) async {
    await _supabase
        .from('fuel_slips')
        .delete()
        .eq('id', slipId)
        .eq('user_id', _currentUserId);
  }

  /// Updates an existing fuel slip
  Future<void> updateFuelSlip({
    required String slipId,
    required String vehicleId,
    required String merchantName,
    required double totalAmount,
    required double vatAmount,
    required double pricePerUnit,
    required double volumeUnits,
    required int odometerReading,
    required DateTime transactionDate,
    File? newImageFile,
  }) async {
    String? imagePath;

    if (newImageFile != null) {
      imagePath = await uploadSlipImage(newImageFile);
    }

    final slip = await _supabase
        .from('fuel_slips')
        .select('odometer_reading')
        .eq('id', slipId)
        .single();

    final prevOdo = slip['odometer_reading'] as int?;
    double? distanceDriven;
    double? consumptionL100km;

    if (prevOdo != null && odometerReading > prevOdo) {
      distanceDriven = (odometerReading - prevOdo).toDouble();
      consumptionL100km = (volumeUnits / distanceDriven) * 100;
    }

    final updateData = {
      'vehicle_id': vehicleId,
      'merchant_name': merchantName,
      'transaction_date': transactionDate.toIso8601String(),
      'total_amount': totalAmount,
      'vat_amount': vatAmount,
      'price_per_unit': pricePerUnit,
      'volume_units': volumeUnits,
      'odometer_reading': odometerReading,
      'distance_driven': distanceDriven,
      'consumption_l_100km': consumptionL100km,
    };

    if (imagePath != null) {
      updateData['image_path'] = imagePath;
    }

    await _supabase
        .from('fuel_slips')
        .update(updateData)
        .eq('id', slipId)
        .eq('user_id', _currentUserId);
  }

  /// Gets a single fuel slip by ID
  Future<Map<String, dynamic>?> getFuelSlipById(String slipId) async {
    final response = await _supabase
        .from('fuel_slips')
        .select('*, vehicles(make, model, registration_number)')
        .eq('id', slipId)
        .eq('user_id', _currentUserId)
        .maybeSingle();

    return response;
  }
}
