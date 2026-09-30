import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/fuel_repository.dart';
import '../models/fuel_models.dart';

class FuelEfficiencyPoint {
  final DateTime date;
  final double l100km;

  FuelEfficiencyPoint({required this.date, required this.l100km});
}

class VehicleData {
  final String id;
  final String name;
  final double monthlyForecast;
  final double avgCostPerKm;
  final double currentAvgL100km;
  final List<FuelEfficiencyPoint> efficiencyHistory;

  VehicleData({
    required this.id,
    required this.name,
    required this.monthlyForecast,
    required this.avgCostPerKm,
    required this.currentAvgL100km,
    required this.efficiencyHistory,
  });
}

class VehicleDashboardWidget extends StatefulWidget {
  const VehicleDashboardWidget({super.key});

  @override
  State<VehicleDashboardWidget> createState() => _VehicleDashboardWidgetState();
}

class _VehicleDashboardWidgetState extends State<VehicleDashboardWidget> {
  final _repo = FuelRepository();
  bool _isLoading = true;
  String? _selectedVehicleId;
  List<VehicleData> _vehicles = [];
  VehicleData? _currentVehicle;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final vehicles = await _repo.getVehicles();
      final vehicleDataList = <VehicleData>[];

      for (final vehicle in vehicles) {
        final monthlyForecast = await _repo.calculateMonthlyForecast(vehicle.id);
        final avgCostPerKm = await _repo.calculateAvgCostPerKm(vehicle.id);
        final currentAvgL100km = await _repo.calculateCurrentAvgL100km(vehicle.id);
        final efficiencyHistoryRaw = await _repo.getEfficiencyHistory(vehicle.id);

        final efficiencyHistory = efficiencyHistoryRaw.map((e) {
          return FuelEfficiencyPoint(
            date: DateTime.parse(e['transaction_date']),
            l100km: (e['consumption_l_100km'] as num).toDouble(),
          );
        }).toList();

        vehicleDataList.add(VehicleData(
          id: vehicle.id,
          name: '${vehicle.make} ${vehicle.model}',
          monthlyForecast: monthlyForecast,
          avgCostPerKm: avgCostPerKm,
          currentAvgL100km: currentAvgL100km,
          efficiencyHistory: efficiencyHistory,
        ));
      }

      if (mounted) {
        setState(() {
          _vehicles = vehicleDataList;
          if (_vehicles.isNotEmpty) {
            _selectedVehicleId = _vehicles.first.id;
            _currentVehicle = _vehicles.first;
          }
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

  void _onVehicleChanged(String? newId) {
    if (newId == null) return;
    setState(() {
      _selectedVehicleId = newId;
      _currentVehicle = _vehicles.firstWhere((v) => v.id == newId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100f14),
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
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
                        'No vehicles available',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Add a Vehicle First'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle Selector Dropdown
                        Card(
                          elevation: 1,
                          color: const Color(0xFF1C1C1E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedVehicleId,
                                isExpanded: true,
                                icon: const Icon(Icons.directions_car, color: Color(0xFFfca541)),
                                dropdownColor: const Color(0xFF1C1C1E),
                                items: _vehicles.map((v) {
                                  return DropdownMenuItem<String>(
                                    value: v.id,
                                    child: Text(
                                      v.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFf7f8f9)),
                                    ),
                                  );
                                }).toList(),
                                onChanged: _onVehicleChanged,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                    
                        // Summary Cards Section
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Est. Monthly Spend',
                                value: 'R ${_currentVehicle!.monthlyForecast.toStringAsFixed(2)}',
                                icon: Icons.account_balance_wallet_outlined,
                                color: Colors.blue.shade700,
                                subtitle: 'Based on 30-day usage',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Cost / Km',
                                value: 'R ${_currentVehicle!.avgCostPerKm.toStringAsFixed(2)}',
                                icon: Icons.speed_outlined,
                                color: Colors.teal.shade700,
                                subtitle: 'Avg running cost',
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
                                value: '${_currentVehicle!.currentAvgL100km.toStringAsFixed(1)} L/100km',
                                icon: Icons.local_gas_station_outlined,
                                color: Colors.orange.shade800,
                                subtitle: 'Target: < 8.5 L/100km',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                    
                        // Efficiency Chart Card
                        Card(
                          elevation: 2,
                          color: const Color(0xFF1C1C1E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Fuel Efficiency Trend',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFf7f8f9),
                                          ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFfca541).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'L / 100 km',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFfca541),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 220,
                                  child: _currentVehicle!.efficiencyHistory.isEmpty
                                      ? const Center(child: Text('Not enough fill-up data yet.', style: TextStyle(color: Color(0xFF7f7f81))))
                                      : _buildLineChart(context, _currentVehicle!.efficiencyHistory),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildLineChart(BuildContext context, List<FuelEfficiencyPoint> history) {
    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.l100km);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade700,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < history.length) {
                  final dt = history[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      '${dt.day}/${dt.month}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFfca541),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFfca541).withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFf7f8f9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}