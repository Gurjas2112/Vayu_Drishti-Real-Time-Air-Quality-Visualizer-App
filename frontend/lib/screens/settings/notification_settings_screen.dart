import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = NotificationService.notificationsEnabled;
  bool _emergencyAlertsEnabled = NotificationService.emergencyAlertsEnabled;
  bool _dailyReportsEnabled = NotificationService.dailyReportsEnabled;
  bool _forecastAlertsEnabled = NotificationService.forecastAlertsEnabled;
  double _alertThreshold = NotificationService.alertThreshold.toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Push Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Receive alerts about air quality changes in your area',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Notifications'),
                      subtitle: const Text(
                        'Master control for all notifications',
                      ),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveSettings();
                      },
                      activeThumbColor: Colors.blue.shade600,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Alert types
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Alert Types',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Emergency alerts
                    SwitchListTile(
                      title: const Text('Emergency Alerts'),
                      subtitle: const Text('Critical air quality warnings'),
                      value: _emergencyAlertsEnabled && _notificationsEnabled,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() {
                                _emergencyAlertsEnabled = value;
                              });
                              _saveSettings();
                            }
                          : null,
                      activeThumbColor: Colors.red.shade600,
                      secondary: const Icon(Icons.emergency),
                    ),

                    const Divider(),

                    // Daily reports
                    SwitchListTile(
                      title: const Text('Daily Reports'),
                      subtitle: const Text('Daily air quality summary'),
                      value: _dailyReportsEnabled && _notificationsEnabled,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() {
                                _dailyReportsEnabled = value;
                              });
                              _saveSettings();
                            }
                          : null,
                      activeThumbColor: Colors.blue.shade600,
                      secondary: const Icon(Icons.today),
                    ),

                    const Divider(),

                    // Forecast alerts
                    SwitchListTile(
                      title: const Text('Forecast Alerts'),
                      subtitle: const Text('Predictions for poor air quality'),
                      value: _forecastAlertsEnabled && _notificationsEnabled,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() {
                                _forecastAlertsEnabled = value;
                              });
                              _saveSettings();
                            }
                          : null,
                      activeThumbColor: Colors.purple.shade600,
                      secondary: const Icon(Icons.schedule),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Alert threshold
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune,
                          color: Colors.green.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Alert Threshold',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get notified when AQI exceeds ${_alertThreshold.toInt()}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Text('50'),
                        Expanded(
                          child: Slider(
                            value: _alertThreshold,
                            min: 50,
                            max: 300,
                            divisions: 25,
                            label: _alertThreshold.toInt().toString(),
                            onChanged: _notificationsEnabled
                                ? (value) {
                                    setState(() {
                                      _alertThreshold = value;
                                    });
                                  }
                                : null,
                            onChangeEnd: (value) {
                              _saveSettings();
                            },
                            activeColor: _getThresholdColor(
                              _alertThreshold.toInt(),
                            ),
                          ),
                        ),
                        const Text('300'),
                      ],
                    ),

                    // Threshold category
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _getThresholdColor(
                          _alertThreshold.toInt(),
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getThresholdColor(_alertThreshold.toInt()),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getThresholdCategory(_alertThreshold.toInt()),
                        style: TextStyle(
                          color: _getThresholdColor(_alertThreshold.toInt()),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Alert history button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAlertHistory(),
                icon: const Icon(Icons.history),
                label: const Text('View Alert History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test notification button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _notificationsEnabled
                    ? () => _sendTestNotification()
                    : null,
                icon: const Icon(Icons.send),
                label: const Text('Send Test Notification'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getThresholdColor(int threshold) {
    if (threshold >= 200) return Colors.red;
    if (threshold >= 150) return Colors.orange;
    if (threshold >= 100) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getThresholdCategory(int threshold) {
    if (threshold >= 200) return 'Very Unhealthy+';
    if (threshold >= 150) return 'Unhealthy+';
    if (threshold >= 100) return 'Unhealthy for Sensitive Groups+';
    return 'Moderate+';
  }

  void _saveSettings() {
    NotificationService.saveSettings(
      notificationsEnabled: _notificationsEnabled,
      emergencyAlertsEnabled: _emergencyAlertsEnabled,
      dailyReportsEnabled: _dailyReportsEnabled,
      forecastAlertsEnabled: _forecastAlertsEnabled,
      alertThreshold: _alertThreshold.toInt(),
    );
  }

  void _sendTestNotification() {
    NotificationService.sendPollutionSpikeAlert(
      context,
      'Test Location',
      150,
      100,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAlertHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Alert History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Alert list
              Expanded(
                child: FutureBuilder<List<PollutionAlert>>(
                  future: NotificationService.getAlertHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No alerts yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'You\'ll see your notification history here',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final alerts = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getAlertColor(alert.severity),
                              child: Icon(
                                _getAlertIcon(alert.type),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              alert.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${alert.locationName} • ${_formatTime(alert.timestamp)}',
                            ),
                            trailing: Text(
                              'AQI ${alert.currentAQI}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getAlertColor(alert.severity),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAlertColor(String severity) {
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

  IconData _getAlertIcon(String type) {
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
