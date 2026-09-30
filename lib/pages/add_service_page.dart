import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../repositories/maintenance_repository.dart';
import '../models/maintenance_models.dart';

class AddServicePage extends StatefulWidget {
  final String vehicleId;
  final VehicleService? service;

  const AddServicePage({
    super.key,
    required this.vehicleId,
    this.service,
  });

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _maintenanceRepo = MaintenanceRepository();
  final ImagePicker _imagePicker = ImagePicker();

  final _workshopNameController = TextEditingController();
  final _invoiceDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _totalAmountController = TextEditingController();
  final _odometerController = TextEditingController();
  final _notesController = TextEditingController();

  File? _invoiceImage;
  InvoiceExtractionResult? _extractedData;
  bool _isExtracting = false;
  bool _isSaving = false;

  final List<ServiceItem> _serviceItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _workshopNameController.text = widget.service!.workshopName;
      _invoiceDateController.text =
          DateFormat('yyyy-MM-dd').format(widget.service!.invoiceDate);
      _totalAmountController.text =
          widget.service!.totalAmount.toStringAsFixed(2);
      _odometerController.text = widget.service!.odometerReading.toString();
      _notesController.text = widget.service!.notes ?? '';
      _serviceItems.addAll(widget.service!.items);
    }
  }

  @override
  void dispose() {
    _workshopNameController.dispose();
    _invoiceDateController.dispose();
    _totalAmountController.dispose();
    _odometerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _invoiceImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _captureImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _invoiceImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _extractWithAI() async {
    if (_invoiceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an invoice image first')),
      );
      return;
    }

    setState(() => _isExtracting = true);

    try {
      // Initialize Gemini with your API key
      // You should store this securely (e.g., environment variable or secure storage)
      const geminiApiKey = 'YOUR_GEMINI_API_KEY'; // Replace with actual API key
      _maintenanceRepo.initGemini(geminiApiKey);

      final result = await _maintenanceRepo.extractInvoiceData(_invoiceImage!);

      setState(() {
        _extractedData = result;
        _workshopNameController.text = result.workshopName;
        _invoiceDateController.text =
            DateFormat('yyyy-MM-dd').format(result.invoiceDate);
        _totalAmountController.text = result.totalAmount.toStringAsFixed(2);
        _odometerController.text = result.odometerReading.toString();
        _serviceItems.clear();
        _serviceItems.addAll(result.items);
        _isExtracting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice data extracted successfully')),
      );
    } catch (e) {
      setState(() => _isExtracting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Extraction failed: $e')),
      );
    }
  }

  void _addServiceItem() {
    setState(() {
      _serviceItems.add(ServiceItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        serviceId: '',
        category: 'other',
        description: '',
        amount: 0.0,
        quantity: 1,
        createdAt: DateTime.now(),
      ));
    });
  }

  void _removeServiceItem(int index) {
    setState(() {
      _serviceItems.removeAt(index);
    });
  }

  void _updateServiceItem(int index, ServiceItem item) {
    setState(() {
      _serviceItems[index] = item;
    });
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
      final odometer = int.tryParse(_odometerController.text) ?? 0;
      final invoiceDate = DateTime.parse(_invoiceDateController.text);

      // Filter out items with zero amount
      final validItems =
          _serviceItems.where((item) => item.amount > 0).toList();

      if (widget.service != null) {
        // Update existing service
        await _maintenanceRepo.updateVehicleService(
          serviceId: widget.service!.id,
          workshopName: _workshopNameController.text.trim(),
          invoiceDate: invoiceDate,
          totalAmount: totalAmount,
          odometerReading: odometer,
          invoiceImage: _invoiceImage,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          items: validItems,
        );
      } else {
        // Create new service
        await _maintenanceRepo.createVehicleService(
          vehicleId: widget.vehicleId,
          workshopName: _workshopNameController.text.trim(),
          invoiceDate: invoiceDate,
          totalAmount: totalAmount,
          odometerReading: odometer,
          invoiceImage: _invoiceImage,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          items: validItems,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service saved successfully')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving service: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100f14),
      appBar: AppBar(
        title: const Text('Add Service', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF100f14),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _saveService,
              child: const Text('Save',
                  style: TextStyle(color: Color(0xFFfca541))),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice Image Section
              Card(
                color: const Color(0xFF1C1C1E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invoice Image',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFf7f8f9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_invoiceImage != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _invoiceImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54),
                                onPressed: () =>
                                    setState(() => _invoiceImage = null),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFF212227),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF7f7f81)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 48, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              const Text(
                                'No invoice selected',
                                style: TextStyle(color: Color(0xFF7f7f81)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFfca541),
                                side:
                                    const BorderSide(color: Color(0xFFfca541)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _captureImage,
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Camera'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFfca541),
                                side:
                                    const BorderSide(color: Color(0xFFfca541)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_invoiceImage != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isExtracting ? null : _extractWithAI,
                            icon: _isExtracting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.auto_awesome, size: 18),
                            label: Text(_isExtracting
                                ? 'Extracting...'
                                : 'Extract with AI'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFfca541),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Basic Information
              Card(
                color: const Color(0xFF1C1C1E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Service Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFf7f8f9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _workshopNameController,
                        style: const TextStyle(color: Color(0xFFf7f8f9)),
                        decoration: const InputDecoration(
                          labelText: 'Workshop Name',
                          labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF7f7f81)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFfca541)),
                          ),
                        ),
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _invoiceDateController,
                        style: const TextStyle(color: Color(0xFFf7f8f9)),
                        decoration: const InputDecoration(
                          labelText: 'Invoice Date',
                          labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF7f7f81)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFfca541)),
                          ),
                          suffixIcon: Icon(Icons.calendar_today,
                              color: Color(0xFF7f7f81)),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate:
                                DateTime.now().add(const Duration(days: 30)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFFfca541),
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF1C1C1E),
                                    onSurface: Color(0xFFf7f8f9),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            _invoiceDateController.text =
                                DateFormat('yyyy-MM-dd').format(picked);
                          }
                        },
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _totalAmountController,
                        style: const TextStyle(color: Color(0xFFf7f8f9)),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Amount (R)',
                          labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF7f7f81)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFfca541)),
                          ),
                          prefixText: 'R ',
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) return 'Required';
                          if (double.tryParse(value!) == null)
                            return 'Invalid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _odometerController,
                        style: const TextStyle(color: Color(0xFFf7f8f9)),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Odometer Reading (km)',
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
                          if (int.tryParse(value!) == null)
                            return 'Invalid odometer';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        style: const TextStyle(color: Color(0xFFf7f8f9)),
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
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
              const SizedBox(height: 20),

              // Service Items
              Card(
                color: const Color(0xFF1C1C1E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Service Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFf7f8f9),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addServiceItem,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Item'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFfca541),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_serviceItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF212227),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'No items added yet',
                              style: TextStyle(color: Color(0xFF7f7f81)),
                            ),
                          ),
                        )
                      else
                        ..._serviceItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return _ServiceItemTile(
                            item: item,
                            index: index,
                            onUpdate: (updatedItem) =>
                                _updateServiceItem(index, updatedItem),
                            onRemove: () => _removeServiceItem(index),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceItemTile extends StatefulWidget {
  final ServiceItem item;
  final int index;
  final Function(ServiceItem) onUpdate;
  final VoidCallback onRemove;

  const _ServiceItemTile({
    required this.item,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_ServiceItemTile> createState() => _ServiceItemTileState();
}

class _ServiceItemTileState extends State<_ServiceItemTile> {
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _quantityController;

  static const List<String> _categories = [
    'engine_oil',
    'oil_filter',
    'air_filter',
    'fuel_filter',
    'spark_plugs',
    'brake_pads_front',
    'brake_pads_rear',
    'brake_discs_front',
    'brake_discs_rear',
    'coolant',
    'transmission_fluid',
    'battery',
    'tires',
    'timing_belt',
    'cabin_air_filter',
    'labor',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.item.category);
    _descriptionController =
        TextEditingController(text: widget.item.description ?? '');
    _amountController =
        TextEditingController(text: widget.item.amount.toStringAsFixed(2));
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _updateItem() {
    widget.onUpdate(ServiceItem(
      id: widget.item.id,
      serviceId: widget.item.serviceId,
      category: _categoryController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      unit: widget.item.unit,
      createdAt: widget.item.createdAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF212227),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFf7f8f9),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _categoryController.text.isEmpty
                  ? null
                  : _categoryController.text,
              style: const TextStyle(color: Color(0xFFf7f8f9)),
              dropdownColor: const Color(0xFF1C1C1E),
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7f7f81)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFfca541)),
                ),
              ),
              items: _categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(color: Color(0xFFf7f8f9)),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _categoryController.text = value;
                  _updateItem();
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Color(0xFFf7f8f9)),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7f7f81)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFfca541)),
                ),
              ),
              onChanged: (_) => _updateItem(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    style: const TextStyle(color: Color(0xFFf7f8f9)),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (R)',
                      labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF7f7f81)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFfca541)),
                      ),
                      prefixText: 'R ',
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    style: const TextStyle(color: Color(0xFFf7f8f9)),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF7f7f81)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFfca541)),
                      ),
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
