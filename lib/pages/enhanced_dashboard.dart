import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/fuel_repository.dart';
import 'package:intl/intl.dart';

class EnhancedDashboard extends StatefulWidget {
  const EnhancedDashboard({super.key});

  @override
  State<EnhancedDashboard> createState() => _EnhancedDashboardState();
}

class _EnhancedDashboardState extends State<EnhancedDashboard> {
  final _repo = FuelRepository();

  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedVehicleId;

  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _fuelSlips = [];

  double _totalLiters = 0.0;
  double _totalSpend = 0.0;
  double _totalDistance = 0.0;
  double _avgL100km = 0.0;

  bool _showAllSlips = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final vehicles = await _repo.getVehicles();
      final vehicleDataList = vehicles
          .map((v) => {
                'id': v.id,
                'name': '${v.make} ${v.model}',
              })
          .toList();

      final slips = await _repo.getFuelSlipsByDateRange(
        vehicleId: _selectedVehicleId,
        startDate: _startDate,
        endDate: _endDate,
      );

      final totalLiters = await _repo.calculateTotalLiters(
        vehicleId: _selectedVehicleId,
        startDate: _startDate,
        endDate: _endDate,
      );

      final totalSpend = await _repo.calculateTotalSpend(
        vehicleId: _selectedVehicleId,
        startDate: _startDate,
        endDate: _endDate,
      );

      final totalDistance = await _repo.calculateTotalDistance(
        vehicleId: _selectedVehicleId,
        startDate: _startDate,
        endDate: _endDate,
      );

      final avgL100km = await _repo.calculateAvgL100kmForRange(
        vehicleId: _selectedVehicleId,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _vehicles = vehicleDataList;
          _fuelSlips = slips;
          _totalLiters = totalLiters;
          _totalSpend = totalSpend;
          _totalDistance = totalDistance;
          _avgL100km = avgL100km;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _showAllSlips = false;
      });
      _loadData();
    }
  }

  void _shiftPeriod(int days) {
    setState(() {
      _startDate = _startDate.add(Duration(days: days));
      _endDate = _endDate.add(Duration(days: days));
      _showAllSlips = false;
    });
    _loadData();
  }

  Future<void> _deleteSlip(String slipId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Slip',
            style: TextStyle(color: Color(0xFFf7f8f9))),
        content: const Text('Are you sure you want to delete this slip?',
            style: TextStyle(color: Color(0xFF7f7f81))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFFfca541))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.deleteFuelSlip(slipId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Slip deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting slip: $e')),
          );
        }
      }
    }
  }

  void _editSlip(Map<String, dynamic> slip) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _toggleShowAll() {
    setState(() {
      _showAllSlips = !_showAllSlips;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100f14),
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF100f14),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Selector
                    _DateRangeSelector(
                      startDate: _startDate,
                      endDate: _endDate,
                      showAllSlips: _showAllSlips,
                      onDateRangeTap: _selectDateRange,
                      onPrevious: () => _shiftPeriod(-30),
                      onNext: () => _shiftPeriod(30),
                      onToggleShowAll: _toggleShowAll,
                    ),
                    const SizedBox(height: 20),

                    // Vehicle Filter (if vehicles exist)
                    if (_vehicles.isNotEmpty) ...[
                      Card(
                        color: const Color(0xFF1C1C1E),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedVehicleId,
                              isExpanded: true,
                              hint: const Text('All Vehicles',
                                  style: TextStyle(color: Color(0xFFf7f8f9))),
                              icon: const Icon(Icons.directions_car,
                                  color: Color(0xFFfca541)),
                              dropdownColor: const Color(0xFF1C1C1E),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All Vehicles',
                                      style:
                                          TextStyle(color: Color(0xFFf7f8f9))),
                                ),
                                ..._vehicles
                                    .map((v) => DropdownMenuItem<String?>(
                                          value: v['id'],
                                          child: Text(
                                            v['name'],
                                            style: const TextStyle(
                                                color: Color(0xFFf7f8f9)),
                                          ),
                                        )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedVehicleId = value;
                                  _showAllSlips = false;
                                });
                                _loadData();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Summary Metrics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Total Liters',
                            value: '${_totalLiters.toStringAsFixed(1)} L',
                            icon: Icons.local_gas_station,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Total Spend',
                            value: 'R ${_totalSpend.toStringAsFixed(2)}',
                            icon: Icons.account_balance_wallet,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Avg Efficiency',
                            value: '${_avgL100km.toStringAsFixed(1)} L/100km',
                            icon: Icons.speed,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Total Distance',
                            value:
                                '${(_totalDistance / 1000).toStringAsFixed(0)} km',
                            icon: Icons.route,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Fuel Slips Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fuel Slips',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFf7f8f9),
                          ),
                        ),
                        Text(
                          '${_fuelSlips.length} logs',
                          style: const TextStyle(
                            color: Color(0xFF7f7f81),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_fuelSlips.isEmpty)
                      Container(
                        height: 180,
                        alignment: Alignment.center,
                        child: Text(
                          _showAllSlips
                              ? 'No fuel slips recorded yet.'
                              : 'No fuel slips in this time period.',
                          style: const TextStyle(color: Color(0xFF7f7f81)),
                        ),
                      )
                    else
                      ..._fuelSlips.map((slip) => _FuelSlipCard(
                            slip: slip,
                            repo: _repo,
                            onEdit: () => _editSlip(slip),
                            onDelete: () => _deleteSlip(slip['id']),
                          )),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final bool showAllSlips;
  final VoidCallback onDateRangeTap;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleShowAll;

  const _DateRangeSelector({
    required this.startDate,
    required this.endDate,
    required this.showAllSlips,
    required this.onDateRangeTap,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.chevron_left, color: Color(0xFFfca541)),
                  onPressed: showAllSlips ? null : onPrevious,
                ),
                Expanded(
                  child: InkWell(
                    onTap: showAllSlips ? null : onDateRangeTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          Text(
                            showAllSlips ? 'All Time' : 'Selected Period',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7f7f81),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            showAllSlips
                                ? 'All Historical Data'
                                : '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFf7f8f9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.chevron_right, color: Color(0xFFfca541)),
                  onPressed: showAllSlips ? null : onNext,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onToggleShowAll,
              icon: Icon(
                showAllSlips ? Icons.calendar_today : Icons.history,
                size: 16,
                color: const Color(0xFFfca541),
              ),
              label: Text(
                showAllSlips
                    ? 'Show Last 30 Days'
                    : 'View All Historical Slips',
                style: const TextStyle(
                  color: Color(0xFFfca541),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7f7f81),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFf7f8f9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FuelSlipCard extends StatelessWidget {
  final Map<String, dynamic> slip;
  final FuelRepository repo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FuelSlipCard({
    required this.slip,
    required this.repo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = slip['vehicles'] as Map<String, dynamic>?;
    final vehicleText = vehicle != null
        ? '${vehicle['make']} ${vehicle['model']}'
        : 'Unknown Vehicle';
    final date = DateTime.parse(slip['transaction_date']);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Card(
      color: const Color(0xFF1C1C1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FutureBuilder<String>(
                future: repo.getSignedImageUrl(slip['image_path']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[800],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasData) {
                    return Image.network(
                      snapshot.data!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    );
                  }
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[800],
                    child: const Icon(Icons.receipt, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slip['merchant_name'] ?? 'Fuel Station',
                    style: const TextStyle(
                      color: Color(0xFFf7f8f9),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicleText,
                    style: const TextStyle(
                      color: Color(0xFF7f7f81),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(date),
                    style: const TextStyle(
                      color: Color(0xFF7f7f81),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'R ${(slip['total_amount'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFfca541),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(slip['volume_units'] as num).toStringAsFixed(1)} L',
                        style: const TextStyle(
                          color: Color(0xFF7f7f81),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit,
                      size: 20, color: Color(0xFF7f7f81)),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
