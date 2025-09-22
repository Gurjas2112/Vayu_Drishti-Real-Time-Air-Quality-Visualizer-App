import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vayudrishti/core/backend_connection_service.dart';
import 'package:vayudrishti/providers/air_quality_provider.dart';
import 'package:vayudrishti/providers/location_provider.dart';

enum NotificationType { warning, alert, info, success, forecast, health }

enum NotificationPriority { low, medium, high, critical }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final NotificationPriority priority;
  final Map<String, dynamic>? data;
  bool isRead;
  bool isArchived;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.data,
    this.isRead = false,
    this.isArchived = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.info,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      data: json['data'],
      isRead: json['isRead'] ?? false,
      isArchived: json['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'data': data,
      'isRead': isRead,
      'isArchived': isArchived,
    };
  }
}

class NotificationSettings {
  bool enableNotifications;
  bool enableLocationAlerts;
  bool enableHealthAlerts;
  bool enableForecastAlerts;
  bool enableCriticalAlerts;
  double alertThreshold;
  bool enableSound;
  bool enableVibration;
  List<String> mutedHours; // Hours when notifications are muted (24h format)

  NotificationSettings({
    this.enableNotifications = true,
    this.enableLocationAlerts = true,
    this.enableHealthAlerts = true,
    this.enableForecastAlerts = false,
    this.enableCriticalAlerts = true,
    this.alertThreshold = 100.0,
    this.enableSound = true,
    this.enableVibration = true,
    this.mutedHours = const [],
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enableNotifications: json['enableNotifications'] ?? true,
      enableLocationAlerts: json['enableLocationAlerts'] ?? true,
      enableHealthAlerts: json['enableHealthAlerts'] ?? true,
      enableForecastAlerts: json['enableForecastAlerts'] ?? false,
      enableCriticalAlerts: json['enableCriticalAlerts'] ?? true,
      alertThreshold: (json['alertThreshold'] ?? 100.0).toDouble(),
      enableSound: json['enableSound'] ?? true,
      enableVibration: json['enableVibration'] ?? true,
      mutedHours: List<String>.from(json['mutedHours'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableNotifications': enableNotifications,
      'enableLocationAlerts': enableLocationAlerts,
      'enableHealthAlerts': enableHealthAlerts,
      'enableForecastAlerts': enableForecastAlerts,
      'enableCriticalAlerts': enableCriticalAlerts,
      'alertThreshold': alertThreshold,
      'enableSound': enableSound,
      'enableVibration': enableVibration,
      'mutedHours': mutedHours,
    };
  }

  NotificationSettings copyWith({
    bool? enableNotifications,
    bool? enableLocationAlerts,
    bool? enableHealthAlerts,
    bool? enableForecastAlerts,
    bool? enableCriticalAlerts,
    double? alertThreshold,
    bool? enableSound,
    bool? enableVibration,
    List<String>? mutedHours,
  }) {
    return NotificationSettings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableLocationAlerts: enableLocationAlerts ?? this.enableLocationAlerts,
      enableHealthAlerts: enableHealthAlerts ?? this.enableHealthAlerts,
      enableForecastAlerts: enableForecastAlerts ?? this.enableForecastAlerts,
      enableCriticalAlerts: enableCriticalAlerts ?? this.enableCriticalAlerts,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      mutedHours: mutedHours ?? this.mutedHours,
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final List<NotificationItem> _notifications = [];
  NotificationSettings _settings = NotificationSettings();

  // Backend services
  AirQualityProvider? _airQualityProvider;
  LocationProvider? _locationProvider;

  // State
  bool _isInitialized = false;
  double? _lastAQI;

  // Getters
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  List<NotificationItem> get unreadNotifications =>
      _notifications.where((n) => !n.isRead && !n.isArchived).toList();
  List<NotificationItem> get criticalNotifications => _notifications
      .where((n) => n.priority == NotificationPriority.critical && !n.isRead)
      .toList();
  int get unreadCount => unreadNotifications.length;
  NotificationSettings get settings => _settings;
  bool get isInitialized => _isInitialized;

  // Initialize the notification provider
  Future<void> initialize({
    required BackendConnectionService backendService,
    required AirQualityProvider airQualityProvider,
    required LocationProvider locationProvider,
  }) async {
    _airQualityProvider = airQualityProvider;
    _locationProvider = locationProvider;

    // Load settings and notifications from local storage
    await _loadSettings();
    await _loadNotifications();

    // Set up listeners for AQI changes
    _setupAQIListener();

    // Generate initial notifications if needed
    await _generateInitialNotifications();

    _isInitialized = true;
    notifyListeners();

    _logger.i('NotificationProvider initialized');
  }

  // Setup AQI monitoring
  void _setupAQIListener() {
    _airQualityProvider?.addListener(_onAQIChanged);
  }

  // Handle AQI changes
  void _onAQIChanged() {
    final currentAQI = _airQualityProvider?.currentAQI?.aqi.toDouble();
    if (currentAQI == null) return;

    // Check if we should create a notification
    if (_shouldCreateAQINotification(currentAQI)) {
      _createAQINotification(currentAQI);
    }

    _lastAQI = currentAQI;
  }

  // Determine if AQI notification should be created
  bool _shouldCreateAQINotification(double currentAQI) {
    if (!_settings.enableNotifications || !_settings.enableLocationAlerts) {
      return false;
    }

    // Don't notify if in muted hours
    if (_isInMutedHours()) return false;

    // First time checking AQI
    if (_lastAQI == null) {
      return currentAQI > _settings.alertThreshold;
    }

    // Significant increase (>20 AQI points)
    if (currentAQI - _lastAQI! > 20) return true;

    // Crossed threshold
    if (_lastAQI! <= _settings.alertThreshold &&
        currentAQI > _settings.alertThreshold) {
      return true;
    }

    // Significant improvement (>30 AQI points decrease)
    if (_lastAQI! - currentAQI > 30) return true;

    return false;
  }

  // Create AQI-based notification
  void _createAQINotification(double aqi) {
    final location = _locationProvider?.currentAddress ?? 'your area';

    NotificationItem notification;

    if (aqi <= 50) {
      notification = NotificationItem(
        id: _generateId(),
        title: '🌟 Excellent Air Quality!',
        message:
            'Perfect conditions in $location (AQI: ${aqi.toInt()}). Great time for outdoor activities!',
        timestamp: DateTime.now(),
        type: NotificationType.success,
        priority: NotificationPriority.low,
        data: {'aqi': aqi, 'location': location},
      );
    } else if (aqi <= 100) {
      notification = NotificationItem(
        id: _generateId(),
        title: '✅ Good Air Quality',
        message:
            'Air quality is acceptable in $location (AQI: ${aqi.toInt()}). Enjoy your day outdoors!',
        timestamp: DateTime.now(),
        type: NotificationType.info,
        priority: NotificationPriority.low,
        data: {'aqi': aqi, 'location': location},
      );
    } else if (aqi <= 150) {
      notification = NotificationItem(
        id: _generateId(),
        title: '⚠️ Moderate Air Quality',
        message:
            'Air quality is moderate in $location (AQI: ${aqi.toInt()}). Sensitive individuals should limit outdoor activities.',
        timestamp: DateTime.now(),
        type: NotificationType.warning,
        priority: NotificationPriority.medium,
        data: {'aqi': aqi, 'location': location},
      );
    } else if (aqi <= 200) {
      notification = NotificationItem(
        id: _generateId(),
        title: '🚨 Poor Air Quality Alert',
        message:
            'Air quality is poor in $location (AQI: ${aqi.toInt()}). Everyone should reduce outdoor activities.',
        timestamp: DateTime.now(),
        type: NotificationType.alert,
        priority: NotificationPriority.high,
        data: {'aqi': aqi, 'location': location},
      );
    } else {
      notification = NotificationItem(
        id: _generateId(),
        title: '🚨 HAZARDOUS Air Quality!',
        message:
            'DANGEROUS air quality in $location (AQI: ${aqi.toInt()}). Stay indoors and avoid all outdoor activities!',
        timestamp: DateTime.now(),
        type: NotificationType.alert,
        priority: NotificationPriority.critical,
        data: {'aqi': aqi, 'location': location},
      );
    }

    addNotification(notification);
  }

  // Generate health advisory notifications
  Future<void> createHealthAdvisoryNotification(
    String advisory,
    NotificationPriority priority,
  ) async {
    if (!_settings.enableHealthAlerts || _isInMutedHours()) return;

    final notification = NotificationItem(
      id: _generateId(),
      title: '💊 Health Advisory',
      message: advisory,
      timestamp: DateTime.now(),
      type: NotificationType.health,
      priority: priority,
    );

    addNotification(notification);
  }

  // Create forecast notification
  Future<void> createForecastNotification(String forecast) async {
    if (!_settings.enableForecastAlerts || _isInMutedHours()) return;

    final notification = NotificationItem(
      id: _generateId(),
      title: '📈 Air Quality Forecast',
      message: forecast,
      timestamp: DateTime.now(),
      type: NotificationType.forecast,
      priority: NotificationPriority.medium,
    );

    addNotification(notification);
  }

  // Add notification
  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification); // Add to beginning

    // Keep only last 100 notifications
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }

    _saveNotifications();
    notifyListeners();

    _logger.i('Added notification: ${notification.title}');
  }

  // Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      _saveNotifications();
      notifyListeners();
    }
  }

  // Mark all as read
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    _saveNotifications();
    notifyListeners();
  }

  // Delete notification
  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _saveNotifications();
    notifyListeners();
  }

  // Archive notification
  void archiveNotification(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isArchived = true;
      _saveNotifications();
      notifyListeners();
    }
  }

  // Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }

  // Update settings
  void updateSettings(NotificationSettings newSettings) {
    _settings = newSettings;
    _saveSettings();
    notifyListeners();
  }

  // Get notifications by type
  List<NotificationItem> getNotificationsByType(NotificationType type) {
    return _notifications
        .where((n) => n.type == type && !n.isArchived)
        .toList();
  }

  // Refresh notifications (reload from backend or local storage)
  Future<void> refreshNotifications() async {
    await _loadNotifications();
    await _generateInitialNotifications();
    notifyListeners();
  }

  // Add test notification for debugging
  void addTestNotification() {
    final testNotification = NotificationItem(
      id: _generateId(),
      title: '🧪 Test Notification',
      message:
          'This is a test notification to verify the system is working correctly. Time: ${DateTime.now().toString()}',
      timestamp: DateTime.now(),
      type: NotificationType.info,
      priority: NotificationPriority.medium,
    );
    addNotification(testNotification);
  }

  // Check if current time is in muted hours
  bool _isInMutedHours() {
    final now = DateTime.now();
    final currentHour = now.hour.toString().padLeft(2, '0');
    return _settings.mutedHours.contains(currentHour);
  }

  // Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Generate initial notifications for demo
  Future<void> _generateInitialNotifications() async {
    if (_notifications.isNotEmpty) return; // Already have notifications

    // Add some sample notifications
    final sampleNotifications = [
      NotificationItem(
        id: _generateId(),
        title: '🌟 Welcome to VayuDrishti!',
        message:
            'Stay informed about air quality in your area with real-time updates and personalized alerts.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.info,
        priority: NotificationPriority.low,
      ),
      NotificationItem(
        id: _generateId(),
        title: '⚠️ High PM2.5 Detected',
        message:
            'PM2.5 levels are elevated. Consider wearing a mask if going outside.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        type: NotificationType.warning,
        priority: NotificationPriority.medium,
      ),
    ];

    for (var notification in sampleNotifications) {
      _notifications.add(notification);
    }

    _saveNotifications();
  }

  // Load settings from local storage
  Future<void> _loadSettings() async {
    // TODO: Implement actual local storage loading
    // For now, use default settings
    _settings = NotificationSettings();
  }

  // Save settings to local storage
  Future<void> _saveSettings() async {
    // TODO: Implement actual local storage saving
    _logger.d('Settings saved: ${_settings.toJson()}');
  }

  // Load notifications from local storage
  Future<void> _loadNotifications() async {
    // TODO: Implement actual local storage loading
    // For now, notifications list starts empty
  }

  // Save notifications to local storage
  Future<void> _saveNotifications() async {
    // TODO: Implement actual local storage saving
    _logger.d('Saved ${_notifications.length} notifications');
  }

  // Clean up old notifications
  void cleanupOldNotifications() {
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    _notifications.removeWhere(
      (n) => n.timestamp.isBefore(oneMonthAgo) && n.isRead,
    );
    _saveNotifications();
    notifyListeners();
  }

  @override
  void dispose() {
    _airQualityProvider?.removeListener(_onAQIChanged);
    super.dispose();
  }
}
