class MaintenanceAlert {
  final String taskName;
  final int kmRemaining;
  final bool isOverdue;

  MaintenanceAlert({
    required this.taskName,
    required this.kmRemaining,
    required this.isOverdue,
  });
}

class MaintenanceService {
  static List<MaintenanceAlert> checkSchedules({
    required int currentOdometer,
    required List<Map<String, dynamic>> schedules,
  }) {
    List<MaintenanceAlert> alerts = [];

    for (var schedule in schedules) {
      final taskName = schedule['component_name'] as String? ?? 'Unknown';
      final nextDue = schedule['next_due_km'] as int?;
      if (nextDue == null) continue;

      final remaining = nextDue - currentOdometer;

      // Alert if within 500km of service or past due
      if (remaining <= 500) {
        alerts.add(MaintenanceAlert(
          taskName: taskName,
          kmRemaining: remaining,
          isOverdue: remaining < 0,
        ));
      }
    }

    return alerts;
  }
}