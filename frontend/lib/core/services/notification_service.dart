import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static const String _notificationPrefsKey = 'notification_settings';
  static const String _alertHistoryKey = 'alert_history';

  // Notification settings
  static bool _notificationsEnabled = true;
  static bool _emergencyAlertsEnabled = true;
  static bool _dailyReportsEnabled = true;
  static bool _forecastAlertsEnabled = true;
  static int _alertThreshold = 100; // AQI threshold for alerts

  // Initialize notification service
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_notificationPrefsKey);

    if (settingsJson != null) {
      final settings = json.decode(settingsJson);
      _notificationsEnabled = settings['enabled'] ?? true;
      _emergencyAlertsEnabled = settings['emergencyAlerts'] ?? true;
      _dailyReportsEnabled = settings['dailyReports'] ?? true;
      _forecastAlertsEnabled = settings['forecastAlerts'] ?? true;
      _alertThreshold = settings['alertThreshold'] ?? 100;
    }
  }

  // Save notification settings
  static Future<void> saveSettings({
    bool? notificationsEnabled,
    bool? emergencyAlertsEnabled,
    bool? dailyReportsEnabled,
    bool? forecastAlertsEnabled,
    int? alertThreshold,
  }) async {
    if (notificationsEnabled != null) {
      _notificationsEnabled = notificationsEnabled;
    }
    if (emergencyAlertsEnabled != null) {
      _emergencyAlertsEnabled = emergencyAlertsEnabled;
    }
    if (dailyReportsEnabled != null) _dailyReportsEnabled = dailyReportsEnabled;
    if (forecastAlertsEnabled != null) {
      _forecastAlertsEnabled = forecastAlertsEnabled;
    }
    if (alertThreshold != null) _alertThreshold = alertThreshold;

    final settings = {
      'enabled': _notificationsEnabled,
      'emergencyAlerts': _emergencyAlertsEnabled,
      'dailyReports': _dailyReportsEnabled,
      'forecastAlerts': _forecastAlertsEnabled,
      'alertThreshold': _alertThreshold,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationPrefsKey, json.encode(settings));
  }

  // Check if notifications should be sent
  static bool shouldSendNotification(String notificationType) {
    if (!_notificationsEnabled) return false;

    switch (notificationType) {
      case 'emergency':
        return _emergencyAlertsEnabled;
      case 'daily':
        return _dailyReportsEnabled;
      case 'forecast':
        return _forecastAlertsEnabled;
      default:
        return true;
    }
  }

  // Send pollution spike alert
  static Future<void> sendPollutionSpikeAlert(
    BuildContext context,
    String locationName,
    int currentAQI,
    int previousAQI,
  ) async {
    if (!shouldSendNotification('emergency') || currentAQI < _alertThreshold) {
      return;
    }

    final alert = PollutionAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'spike',
      locationName: locationName,
      currentAQI: currentAQI,
      previousAQI: previousAQI,
      timestamp: DateTime.now(),
      severity: _getAlertSeverity(currentAQI),
      message: _generateSpikeMessage(locationName, currentAQI, previousAQI),
    );

    await _saveAlert(alert);
    _showInAppNotification(context, alert);
  }

  // Send daily air quality report
  static Future<void> sendDailyReport(
    BuildContext context,
    String locationName,
    int avgAQI,
    int maxAQI,
    String category,
  ) async {
    if (!shouldSendNotification('daily')) return;

    final alert = PollutionAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'daily_report',
      locationName: locationName,
      currentAQI: avgAQI,
      previousAQI: maxAQI,
      timestamp: DateTime.now(),
      severity: 'info',
      message:
          'Daily air quality report for $locationName: Average AQI $avgAQI ($category)',
    );

    await _saveAlert(alert);
    _showInAppNotification(context, alert);
  }

  // Send forecast alert
  static Future<void> sendForecastAlert(
    BuildContext context,
    String locationName,
    int forecastAQI,
    String forecastCategory,
    DateTime forecastDate,
  ) async {
    if (!shouldSendNotification('forecast') || forecastAQI < _alertThreshold) {
      return;
    }

    final alert = PollutionAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'forecast',
      locationName: locationName,
      currentAQI: forecastAQI,
      previousAQI: 0,
      timestamp: DateTime.now(),
      severity: _getAlertSeverity(forecastAQI),
      message: _generateForecastMessage(
        locationName,
        forecastAQI,
        forecastCategory,
        forecastDate,
      ),
    );

    await _saveAlert(alert);
    _showInAppNotification(context, alert);
  }

  // Send emergency alert for schools/hospitals
  static Future<void> sendEmergencyAlert(
    BuildContext context,
    String institutionType,
    String locationName,
    int currentAQI,
  ) async {
    if (!shouldSendNotification('emergency') || currentAQI < 200) {
      return;
    }

    final alert = PollutionAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'emergency',
      locationName: locationName,
      currentAQI: currentAQI,
      previousAQI: 0,
      timestamp: DateTime.now(),
      severity: 'critical',
      message: _generateEmergencyMessage(
        institutionType,
        locationName,
        currentAQI,
      ),
    );

    await _saveAlert(alert);
    _showInAppNotification(context, alert);
  }

  // Show in-app notification
  static void _showInAppNotification(
    BuildContext context,
    PollutionAlert alert,
  ) {
    final color = _getAlertColor(alert.severity);
    final icon = _getAlertIcon(alert.type);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      alert.type == 'emergency'
                          ? 'Emergency Alert'
                          : 'Air Quality Alert',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      alert.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: color,
          duration: Duration(seconds: alert.severity == 'critical' ? 10 : 5),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () => _showDetailedAlert(context, alert),
          ),
        ),
      );
    }
  }

  // Show detailed alert dialog
  static void _showDetailedAlert(BuildContext context, PollutionAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAlertIcon(alert.type),
              color: _getAlertColor(alert.severity),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.type == 'emergency'
                    ? 'Emergency Alert'
                    : 'Air Quality Alert',
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message),
            const SizedBox(height: 16),
            Text(
              'Location: ${alert.locationName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('AQI: ${alert.currentAQI}'),
            Text('Time: ${_formatTime(alert.timestamp)}'),
            if (alert.type == 'spike' && alert.previousAQI > 0)
              Text('Previous AQI: ${alert.previousAQI}'),
            const SizedBox(height: 16),
            Text(
              'Recommendations:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._getAlertRecommendations(
              alert.currentAQI,
            ).map((rec) => Text('• $rec')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Get alert history
  static Future<List<PollutionAlert>> getAlertHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_alertHistoryKey) ?? [];

    return historyJson
        .map((json) => PollutionAlert.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Save alert to history
  static Future<void> _saveAlert(PollutionAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_alertHistoryKey) ?? [];

    historyJson.insert(0, jsonEncode(alert.toJson()));

    // Keep only last 100 alerts
    if (historyJson.length > 100) {
      historyJson.removeRange(100, historyJson.length);
    }

    await prefs.setStringList(_alertHistoryKey, historyJson);
  }

  // Helper methods
  static String _getAlertSeverity(int aqi) {
    if (aqi >= 300) return 'critical';
    if (aqi >= 200) return 'high';
    if (aqi >= 150) return 'medium';
    return 'low';
  }

  static Color _getAlertColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade600;
      case 'medium':
        return Colors.yellow.shade700;
      case 'info':
        return Colors.blue.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  static IconData _getAlertIcon(String type) {
    switch (type) {
      case 'emergency':
        return Icons.warning;
      case 'spike':
        return Icons.trending_up;
      case 'forecast':
        return Icons.schedule;
      case 'daily_report':
        return Icons.assessment;
      default:
        return Icons.notifications;
    }
  }

  static String _generateSpikeMessage(
    String location,
    int current,
    int previous,
  ) {
    final increase = current - previous;
    return 'Air quality spike detected in $location! AQI increased by $increase points to $current.';
  }

  static String _generateForecastMessage(
    String location,
    int aqi,
    String category,
    DateTime date,
  ) {
    final dateStr = '${date.day}/${date.month}';
    return 'Poor air quality forecast for $location on $dateStr: AQI $aqi ($category)';
  }

  static String _generateEmergencyMessage(
    String institutionType,
    String location,
    int aqi,
  ) {
    return 'EMERGENCY: Hazardous air quality (AQI $aqi) detected near $institutionType in $location. Immediate action required.';
  }

  static List<String> _getAlertRecommendations(int aqi) {
    if (aqi >= 300) {
      return [
        'Stay indoors immediately',
        'Close all windows and doors',
        'Use air purifier if available',
        'Seek medical attention if experiencing symptoms',
      ];
    } else if (aqi >= 200) {
      return [
        'Limit outdoor activities',
        'Wear N95 mask when going outside',
        'Keep windows closed',
        'Use air purifier indoors',
      ];
    } else if (aqi >= 150) {
      return [
        'Reduce outdoor exercise',
        'Consider wearing a mask outdoors',
        'Limit time outside for sensitive individuals',
      ];
    } else {
      return [
        'Monitor air quality regularly',
        'Be aware of changing conditions',
      ];
    }
  }

  static String _formatTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Getters for current settings
  static bool get notificationsEnabled => _notificationsEnabled;
  static bool get emergencyAlertsEnabled => _emergencyAlertsEnabled;
  static bool get dailyReportsEnabled => _dailyReportsEnabled;
  static bool get forecastAlertsEnabled => _forecastAlertsEnabled;
  static int get alertThreshold => _alertThreshold;
}

class PollutionAlert {
  final String id;
  final String type;
  final String locationName;
  final int currentAQI;
  final int previousAQI;
  final DateTime timestamp;
  final String severity;
  final String message;

  PollutionAlert({
    required this.id,
    required this.type,
    required this.locationName,
    required this.currentAQI,
    required this.previousAQI,
    required this.timestamp,
    required this.severity,
    required this.message,
  });

  factory PollutionAlert.fromJson(Map<String, dynamic> json) {
    return PollutionAlert(
      id: json['id'],
      type: json['type'],
      locationName: json['locationName'],
      currentAQI: json['currentAQI'],
      previousAQI: json['previousAQI'],
      timestamp: DateTime.parse(json['timestamp']),
      severity: json['severity'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'locationName': locationName,
      'currentAQI': currentAQI,
      'previousAQI': previousAQI,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity,
      'message': message,
    };
  }
}
