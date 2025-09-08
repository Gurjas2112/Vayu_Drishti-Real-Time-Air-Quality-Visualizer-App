import 'package:flutter/material.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  double _alertThreshold = 100.0;
  bool _enableNotifications = true;
  bool _enableLocationAlerts = true;
  bool _enableHealthAlerts = true;
  bool _enableForecastAlerts = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: '⚠️ AQI Rising - Stay Indoors',
      message:
          'Air quality has deteriorated to Poor (AQI: 185). Consider staying indoors and limiting outdoor activities.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      type: NotificationType.warning,
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: '🌬️ Air Quality Improved',
      message:
          'Great news! Air quality in your area has improved to Fair (AQI: 85). It\'s safer for outdoor activities.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.info,
      isRead: true,
    ),
    NotificationItem(
      id: '3',
      title: '💨 High PM2.5 Detected',
      message:
          'PM2.5 levels are unusually high (125 μg/m³). Sensitive individuals should avoid outdoor exercise.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      type: NotificationType.alert,
      isRead: false,
    ),
    NotificationItem(
      id: '4',
      title: '☀️ Perfect Air Quality',
      message:
          'Excellent air quality today (AQI: 35)! Perfect time for outdoor activities and exercise.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.success,
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      title: '📈 Weekly AQI Forecast',
      message:
          'Air quality is expected to worsen this weekend due to weather conditions. Plan indoor activities.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.forecast,
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Notifications Center',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => _showNotificationSettings(),
          ),
          IconButton(
            icon: const Icon(
              Icons.mark_email_read_outlined,
              color: Colors.white,
            ),
            onPressed: () => _markAllAsRead(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Alert Settings Card
          _buildAlertSettingsCard(),

          // Notifications List
          Expanded(child: _buildNotificationsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showThresholdSlider(),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.tune, color: Colors.white),
        label: const Text(
          'Alerts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAlertSettingsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Alert Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Switch(
                value: _enableNotifications,
                onChanged: (value) {
                  setState(() {
                    _enableNotifications = value;
                  });
                },
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Alert Threshold: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_alertThreshold.toInt()} AQI',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getThresholdCategory(_alertThreshold.toInt()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _alertThreshold,
              min: 0,
              max: 300,
              divisions: 6,
              onChanged: (value) {
                setState(() {
                  _alertThreshold = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
    final readNotifications = _notifications.where((n) => n.isRead).toList();

    return CustomScrollView(
      slivers: [
        if (unreadNotifications.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Unread',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadNotifications.length.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return SlideTransition(
                position: _slideAnimation,
                child: _buildNotificationCard(unreadNotifications[index]),
              );
            }, childCount: unreadNotifications.length),
          ),
        ],

        if (readNotifications.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Earlier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildNotificationCard(readNotifications[index]);
            }, childCount: readNotifications.length),
          ),
        ],

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.errorColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 24),
        ),
        onDismissed: (direction) {
          setState(() {
            _notifications.removeWhere((n) => n.id == notification.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // In a real app, restore the notification
                },
              ),
            ),
          );
        },
        child: GestureDetector(
          onTap: () => _markAsRead(notification),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.white
                  : color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: notification.isRead
                  ? Border.all(color: AppColors.borderColor)
                  : Border.all(color: color.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: notification.isRead
                              ? FontWeight.w500
                              : FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Notification Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildSettingsTile(
                        'Location-based Alerts',
                        'Get notified when AQI changes in your location',
                        Icons.location_on,
                        _enableLocationAlerts,
                        (value) =>
                            setState(() => _enableLocationAlerts = value),
                      ),
                      _buildSettingsTile(
                        'Health Alerts',
                        'Receive health recommendations based on air quality',
                        Icons.health_and_safety,
                        _enableHealthAlerts,
                        (value) => setState(() => _enableHealthAlerts = value),
                      ),
                      _buildSettingsTile(
                        'Forecast Alerts',
                        'Get daily and weekly air quality forecasts',
                        Icons.trending_up,
                        _enableForecastAlerts,
                        (value) =>
                            setState(() => _enableForecastAlerts = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  void _showThresholdSlider() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Alert Threshold',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get notified when AQI exceeds ${_alertThreshold.toInt()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('0', style: TextStyle(color: AppColors.textSecondary)),
                    Expanded(
                      child: Slider(
                        value: _alertThreshold,
                        min: 0,
                        max: 300,
                        divisions: 6,
                        activeColor: AppColors.primaryColor,
                        onChanged: (value) {
                          setDialogState(() {
                            _alertThreshold = value;
                          });
                          setState(() {});
                        },
                      ),
                    ),
                    Text(
                      '300',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.getAQIColor(
                      _alertThreshold.toInt(),
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getThresholdCategory(_alertThreshold.toInt()),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.getAQIColor(_alertThreshold.toInt()),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Alert threshold set to ${_alertThreshold.toInt()} AQI',
                  ),
                  backgroundColor: AppColors.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _markAsRead(NotificationItem notification) {
    if (!notification.isRead) {
      setState(() {
        notification.isRead = true;
      });
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppColors.successColor,
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.warning:
        return AppColors.warningColor;
      case NotificationType.alert:
        return AppColors.errorColor;
      case NotificationType.info:
        return AppColors.infoColor;
      case NotificationType.success:
        return AppColors.successColor;
      case NotificationType.forecast:
        return AppColors.primaryColor;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.alert:
        return Icons.error;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.forecast:
        return Icons.trending_up;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }

  String _getThresholdCategory(int threshold) {
    if (threshold <= 50) return 'Good';
    if (threshold <= 100) return 'Fair';
    if (threshold <= 150) return 'Moderate';
    if (threshold <= 200) return 'Poor';
    if (threshold <= 300) return 'Very Poor';
    return 'Hazardous';
  }
}

enum NotificationType { warning, alert, info, success, forecast }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}
