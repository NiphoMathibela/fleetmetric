import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_models.dart';

class MaintenanceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  GenerativeModel? _geminiModel;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  // Initialize Gemini AI model
  void initGemini(String apiKey) {
    _geminiModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  // --- MAINTENANCE SCHEDULES ---

  Future<List<MaintenanceSchedule>> getMaintenanceSchedules(
      String vehicleId) async {
    final response = await _supabase
        .from('maintenance_schedules')
        .select()
        .eq('user_id', _currentUserId)
        .eq('vehicle_id', vehicleId)
        .order('component_name');

    return (response as List)
        .map((json) => MaintenanceSchedule.fromJson(json))
        .toList();
  }

  Future<void> createDefaultSchedules(String vehicleId) async {
    await _supabase.rpc('create_default_maintenance_schedules',
        params: {'p_vehicle_id': vehicleId, 'p_user_id': _currentUserId});
  }

  Future<void> updateMaintenanceSchedule(MaintenanceSchedule schedule) async {
    await _supabase
        .from('maintenance_schedules')
        .update({
          'last_service_km': schedule.lastServiceKm,
          'last_service_date': schedule.lastServiceDate?.toIso8601String(),
          'next_due_km': schedule.nextDueKm,
          'next_due_date': schedule.nextDueDate?.toIso8601String(),
          'notes': schedule.notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', schedule.id)
        .eq('user_id', _currentUserId);
  }

  // --- VEHICLE SERVICES ---

  Future<List<VehicleService>> getVehicleServices(String vehicleId) async {
    final response = await _supabase
        .from('vehicle_services')
        .select('*, service_items(*)')
        .eq('user_id', _currentUserId)
        .eq('vehicle_id', vehicleId)
        .order('invoice_date', ascending: false);

    return (response as List)
        .map((json) => VehicleService.fromJson(json))
        .toList();
  }

  Future<VehicleService> createVehicleService({
    required String vehicleId,
    required String workshopName,
    required DateTime invoiceDate,
    required double totalAmount,
    required int odometerReading,
    File? invoiceImage,
    String? notes,
    required List<ServiceItem> items,
  }) async {
    String? imagePath;
    if (invoiceImage != null) {
      imagePath = await uploadInvoiceImage(invoiceImage);
    }

    final serviceResponse = await _supabase
        .from('vehicle_services')
        .insert({
          'user_id': _currentUserId,
          'vehicle_id': vehicleId,
          'workshop_name': workshopName,
          'invoice_date': invoiceDate.toIso8601String(),
          'total_amount': totalAmount,
          'odometer_reading': odometerReading,
          'invoice_path': imagePath,
          'notes': notes,
        })
        .select()
        .single();

    final serviceId = serviceResponse['id'] as String;

    // Insert service items
    for (final item in items) {
      await _supabase.from('service_items').insert({
        'service_id': serviceId,
        'category': item.category,
        'description': item.description,
        'amount': item.amount,
        'quantity': item.quantity,
        'unit': item.unit,
      });
    }

    // Update maintenance schedules based on service items
    await _updateMaintenanceSchedulesFromService(
      vehicleId,
      odometerReading,
      invoiceDate,
      items,
    );

    return VehicleService.fromJson({...serviceResponse, 'service_items': []});
  }

  Future<void> deleteVehicleService(String serviceId) async {
    await _supabase
        .from('vehicle_services')
        .delete()
        .eq('id', serviceId)
        .eq('user_id', _currentUserId);
  }

  Future<void> updateVehicleService({
    required String serviceId,
    required String workshopName,
    required DateTime invoiceDate,
    required double totalAmount,
    required int odometerReading,
    File? invoiceImage,
    String? notes,
    required List<ServiceItem> items,
  }) async {
    String? imagePath;
    if (invoiceImage != null) {
      imagePath = await uploadInvoiceImage(invoiceImage);
    }

    await _supabase
        .from('vehicle_services')
        .update({
          'workshop_name': workshopName,
          'invoice_date': invoiceDate.toIso8601String(),
          'total_amount': totalAmount,
          'odometer_reading': odometerReading,
          if (imagePath != null) 'invoice_path': imagePath,
          'notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', serviceId)
        .eq('user_id', _currentUserId);

    // Delete existing service items
    await _supabase.from('service_items').delete().eq('service_id', serviceId);

    // Insert updated service items
    for (final item in items) {
      await _supabase.from('service_items').insert({
        'service_id': serviceId,
        'category': item.category,
        'description': item.description,
        'amount': item.amount,
        'quantity': item.quantity,
        'unit': item.unit,
      });
    }

    // Get the service to update maintenance schedules
    final serviceResponse = await _supabase
        .from('vehicle_services')
        .select('vehicle_id')
        .eq('id', serviceId)
        .single();

    final vehicleId = serviceResponse['vehicle_id'] as String;

    // Update maintenance schedules based on service items
    await _updateMaintenanceSchedulesFromService(
      vehicleId,
      odometerReading,
      invoiceDate,
      items,
    );
  }

  // --- STORAGE ---

  Future<String> uploadInvoiceImage(File imageFile) async {
    final userId = _currentUserId;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';

    await _supabase.storage.from('service-invoices').upload(
          path,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return path;
  }

  Future<String> getSignedInvoiceUrl(String imagePath) async {
    return await _supabase.storage
        .from('service-invoices')
        .createSignedUrl(imagePath, 60 * 60);
  }

  // --- AI EXTRACTION ---

  Future<InvoiceExtractionResult> extractInvoiceData(File imageFile) async {
    if (_geminiModel == null) {
      throw Exception('Gemini model not initialized. Please provide API key.');
    }

    final imageBytes = await imageFile.readAsBytes();
    final prompt = '''
Extract the following information from this service invoice and return as JSON:
{
  "workshop_name": "name of the workshop/dealership",
  "invoice_date": "YYYY-MM-DD format",
  "total_amount": "total amount as number",
  "odometer_reading": "current odometer reading as integer",
  "items": [
    {
      "category": "one of: engine_oil, oil_filter, air_filter, fuel_filter, spark_plugs, brake_pads_front, brake_pads_rear, brake_discs_front, brake_discs_rear, coolant, transmission_fluid, battery, tires, timing_belt, cabin_air_filter, labor, other",
      "description": "brief description",
      "amount": "cost as number",
      "quantity": "quantity as integer",
      "unit": "unit if applicable"
    }
  ]
}

Only return valid JSON. If a field cannot be found, use null or empty string.
''';

    final imagePart = DataPart('image/jpeg', imageBytes);
    final content = Content.multi([TextPart(prompt), imagePart]);

    final response = await _geminiModel!.generateContent([content]);
    final text = response.text ?? '';

    // Extract JSON from response
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('Could not extract JSON from AI response');
    }

    final jsonString = text.substring(jsonStart, jsonEnd + 1);

    // Parse JSON directly using dart:convert
    final jsonData = jsonDecode(jsonString);

    return InvoiceExtractionResult.fromJson(jsonData);
  }

  // --- PRIVATE HELPERS ---

  Future<void> _updateMaintenanceSchedulesFromService(
    String vehicleId,
    int odometerReading,
    DateTime serviceDate,
    List<ServiceItem> items,
  ) async {
    final schedules = await getMaintenanceSchedules(vehicleId);

    // If no schedules exist, create default ones
    if (schedules.isEmpty) {
      try {
        await createDefaultSchedules(vehicleId);
        // Reload schedules after creating defaults
        final updatedSchedules = await getMaintenanceSchedules(vehicleId);
        schedules.clear();
        schedules.addAll(updatedSchedules);
      } catch (e) {
        // If creating defaults fails, just skip schedule updates
        return;
      }
    }

    for (final item in items) {
      final schedule = schedules.firstWhere(
        (s) => s.componentKey == item.category,
        orElse: () => schedules.firstWhere(
          (s) => s.componentKey == 'other',
          orElse: () => schedules.first,
        ),
      );

      final nextDueKm = odometerReading + schedule.intervalKm;
      final nextDueDate = schedule.intervalDays != null
          ? serviceDate.add(Duration(days: schedule.intervalDays!))
          : null;

      await updateMaintenanceSchedule(
        schedule.copyWith(
          lastServiceKm: odometerReading,
          lastServiceDate: serviceDate,
          nextDueKm: nextDueKm,
          nextDueDate: nextDueDate,
        ),
      );
    }
  }

  // Get current odometer for a vehicle
  Future<int> getCurrentOdometer(String vehicleId) async {
    final vehicleResponse = await _supabase
        .from('vehicles')
        .select('starting_odometer')
        .eq('id', vehicleId)
        .single();

    final startingOdo = vehicleResponse['starting_odometer'] as int? ?? 0;

    // Get latest fuel slip odometer
    final latestFuelSlip = await _supabase
        .from('fuel_slips')
        .select('odometer_reading')
        .eq('vehicle_id', vehicleId)
        .order('transaction_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (latestFuelSlip != null && latestFuelSlip['odometer_reading'] != null) {
      return latestFuelSlip['odometer_reading'] as int;
    }

    // Get latest service odometer
    final latestService = await _supabase
        .from('vehicle_services')
        .select('odometer_reading')
        .eq('vehicle_id', vehicleId)
        .order('invoice_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (latestService != null && latestService['odometer_reading'] != null) {
      return latestService['odometer_reading'] as int;
    }

    return startingOdo;
  }
}
