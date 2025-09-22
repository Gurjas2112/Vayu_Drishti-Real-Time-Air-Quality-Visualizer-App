import 'package:logger/logger.dart';

/// Enhanced notification service that bridges the legacy notification system
/// with the new provider-based notification system
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Logger _logger = Logger();

  // Legacy notification callbacks for existing notification screen
  Function(NotificationItem)? onNotificationAdded;
  Function()? onNotificationsCleared;

  // Real-time AQI monitoring
  double? _lastAQI;
  DateTime? _lastNotificationTime;

  /// Initialize the service with callbacks for legacy support
  void initialize({
    Function(NotificationItem)? onNotificationAdded,
    Function()? onNotificationsCleared,
  }) {
    this.onNotificationAdded = onNotificationAdded;
    this.onNotificationsCleared = onNotificationsCleared;
    _logger.i('NotificationService initialized');
  }

  /// Create AQI-based notification
  void createAQINotification(double aqi, {String? location}) {
    // Prevent spam notifications
    if (_shouldSkipNotification(aqi)) return;

    final notification = _generateAQINotification(aqi, location ?? 'your area');
    _addNotification(notification);

    _lastAQI = aqi;
    _lastNotificationTime = DateTime.now();
  }

  /// Create health advisory notification
  void createHealthNotification(String message, NotificationPriority priority) {
    final notification = NotificationItem(
      id: _generateId(),
      title: '💊 Health Advisory',
      message: message,
      timestamp: DateTime.now(),
      type: NotificationType.health,
      priority: priority,
    );

    _addNotification(notification);
  }

  /// Create forecast notification
  void createForecastNotification(String forecast) {
    final notification = NotificationItem(
      id: _generateId(),
      title: '📈 Air Quality Forecast',
      message: forecast,
      timestamp: DateTime.now(),
      type: NotificationType.forecast,
      priority: NotificationPriority.medium,
    );

    _addNotification(notification);
  }

  /// Create general info notification
  void createInfoNotification(String title, String message) {
    final notification = NotificationItem(
      id: _generateId(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: NotificationType.info,
      priority: NotificationPriority.low,
    );

    _addNotification(notification);
  }

  /// Create success notification
  void createSuccessNotification(String title, String message) {
    final notification = NotificationItem(
      id: _generateId(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: NotificationType.success,
      priority: NotificationPriority.low,
    );

    _addNotification(notification);
  }

  /// Clear all notifications
  void clearAllNotifications() {
    onNotificationsCleared?.call();
    _logger.i('All notifications cleared');
  }

  bool _shouldSkipNotification(double currentAQI) {
    // Don't notify if last notification was within 30 minutes
    if (_lastNotificationTime != null) {
      final timeDiff = DateTime.now().difference(_lastNotificationTime!);
      if (timeDiff.inMinutes < 30) return true;
    }

    // Don't notify if AQI change is less than 20 points
    if (_lastAQI != null && (currentAQI - _lastAQI!).abs() < 20) {
      return true;
    }

    return false;
  }

  NotificationItem _generateAQINotification(double aqi, String location) {
    if (aqi <= 50) {
      return NotificationItem(
        id: _generateId(),
        title: '🌟 Excellent Air Quality!',
        message:
            'Perfect conditions in $location (AQI: ${aqi.toInt()}). Great time for outdoor activities!',
        timestamp: DateTime.now(),
        type: NotificationType.success,
        priority: NotificationPriority.low,
      );
    } else if (aqi <= 100) {
      return NotificationItem(
        id: _generateId(),
        title: '✅ Good Air Quality',
        message:
            'Air quality is acceptable in $location (AQI: ${aqi.toInt()}). Enjoy your day outdoors!',
        timestamp: DateTime.now(),
        type: NotificationType.info,
        priority: NotificationPriority.low,
      );
    } else if (aqi <= 150) {
      return NotificationItem(
        id: _generateId(),
        title: '⚠️ Moderate Air Quality',
        message:
            'Air quality is moderate in $location (AQI: ${aqi.toInt()}). Sensitive individuals should limit outdoor activities.',
        timestamp: DateTime.now(),
        type: NotificationType.warning,
        priority: NotificationPriority.medium,
      );
    } else if (aqi <= 200) {
      return NotificationItem(
        id: _generateId(),
        title: '🚨 Poor Air Quality Alert',
        message:
            'Air quality is poor in $location (AQI: ${aqi.toInt()}). Everyone should reduce outdoor activities.',
        timestamp: DateTime.now(),
        type: NotificationType.alert,
        priority: NotificationPriority.high,
      );
    } else {
      return NotificationItem(
        id: _generateId(),
        title: '🚨 HAZARDOUS Air Quality!',
        message:
            'DANGEROUS air quality in $location (AQI: ${aqi.toInt()}). Stay indoors and avoid all outdoor activities!',
        timestamp: DateTime.now(),
        type: NotificationType.alert,
        priority: NotificationPriority.critical,
      );
    }
  }

  void _addNotification(NotificationItem notification) {
    onNotificationAdded?.call(notification);
    _logger.i('Notification added: ${notification.title}');
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Simplified notification item for compatibility
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final NotificationPriority priority;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.isRead = false,
  });
}

enum NotificationType { warning, alert, info, success, forecast, health }

enum NotificationPriority { low, medium, high, critical }
