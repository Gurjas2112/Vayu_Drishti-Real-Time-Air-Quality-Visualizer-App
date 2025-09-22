import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/providers/notification_provider.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late TextEditingController _searchController;
  String _searchQuery = '';
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController = TextEditingController();
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
    _tabController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: _showSearchBar
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search notifications...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  )
                : const Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(_showSearchBar ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _showSearchBar = !_showSearchBar;
                    if (!_showSearchBar) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () =>
                    _showSettingsDialog(context, notificationProvider),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => notificationProvider.refreshNotifications(),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_active, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'All (${notificationProvider.notifications.length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Alerts (${notificationProvider.getNotificationsByType(NotificationType.warning).length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Info (${notificationProvider.getNotificationsByType(NotificationType.info).length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.health_and_safety, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Health (${notificationProvider.getNotificationsByType(NotificationType.health).length})',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: SlideTransition(
            position: _slideAnimation,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(
                  context,
                  notificationProvider.notifications,
                  notificationProvider,
                ),
                _buildNotificationsList(
                  context,
                  notificationProvider.getNotificationsByType(
                    NotificationType.warning,
                  ),
                  notificationProvider,
                ),
                _buildNotificationsList(
                  context,
                  notificationProvider.getNotificationsByType(
                    NotificationType.info,
                  ),
                  notificationProvider,
                ),
                _buildNotificationsList(
                  context,
                  notificationProvider.getNotificationsByType(
                    NotificationType.health,
                  ),
                  notificationProvider,
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(
            context,
            notificationProvider,
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    NotificationProvider provider,
  ) {
    return FloatingActionButton(
      onPressed: () => _showNotificationActions(context, provider),
      backgroundColor: AppColors.primaryColor,
      child: const Icon(Icons.more_vert, color: Colors.white),
    );
  }

  void _showNotificationActions(
    BuildContext context,
    NotificationProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.add_alert,
                color: AppColors.primaryColor,
              ),
              title: const Text('Add Test Notification'),
              subtitle: const Text('Create a sample notification'),
              onTap: () {
                Navigator.pop(context);
                _showTestNotificationDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.mark_email_read,
                color: AppColors.primaryColor,
              ),
              title: const Text('Mark All as Read'),
              subtitle: const Text('Mark all notifications as read'),
              onTap: () {
                Navigator.pop(context);
                provider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text('Clear All'),
              subtitle: const Text('Remove all notifications'),
              onTap: () {
                Navigator.pop(context);
                _showClearAllDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.settings,
                color: AppColors.primaryColor,
              ),
              title: const Text('Notification Settings'),
              subtitle: const Text('Configure notification preferences'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationSettings(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(
    BuildContext context,
    NotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to remove all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.air, color: AppColors.primaryColor),
              title: Text('Air Quality Alerts'),
              trailing: Icon(Icons.toggle_on, color: AppColors.primaryColor),
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Health Warnings'),
              trailing: Icon(Icons.toggle_on, color: AppColors.primaryColor),
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text('App Updates'),
              trailing: Icon(Icons.toggle_off, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<NotificationItem> _filterNotifications(
    List<NotificationItem> notifications,
  ) {
    if (_searchQuery.isEmpty) {
      return notifications;
    }
    return notifications.where((notification) {
      return notification.title.toLowerCase().contains(_searchQuery) ||
          notification.message.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Widget _buildNotificationsList(
    BuildContext context,
    List<NotificationItem> notifications,
    NotificationProvider provider,
  ) {
    final filteredNotifications = _filterNotifications(notifications);

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.notifications_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching notifications'
                  : 'No notifications',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'You\'re all caught up!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        provider.refreshNotifications();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return _buildNotificationCard(context, notification, provider);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItem notification,
    NotificationProvider provider,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                provider.addNotification(notification);
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: notification.isRead ? 2 : 6,
        shadowColor: notification.isRead
            ? Colors.grey.withOpacity(0.2)
            : _getNotificationColor(notification.type).withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: notification.isRead
              ? BorderSide.none
              : BorderSide(
                  color: _getNotificationColor(notification.type),
                  width: 2,
                ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!notification.isRead) {
              provider.markAsRead(notification.id);
            }
            _showNotificationDetails(context, notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(
                          notification.type,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: _getNotificationColor(notification.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildHighlightedText(
                                  notification.title,
                                  TextStyle(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                    fontSize: 16,
                                    color: notification.isRead
                                        ? Colors.grey[700]
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (notification.priority !=
                                  NotificationPriority.low)
                                _buildPriorityChip(notification.priority),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy • HH:mm',
                            ).format(notification.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
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
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHighlightedText(
                  notification.message,
                  TextStyle(
                    fontSize: 14,
                    color: notification.isRead
                        ? Colors.grey[600]
                        : Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                if (notification.data != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _showNotificationDetails(context, notification);
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('View Details'),
                        style: TextButton.styleFrom(
                          foregroundColor: _getNotificationColor(
                            notification.type,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, TextStyle style) {
    if (_searchQuery.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final queryIndex = lowerText.indexOf(_searchQuery.toLowerCase());

    if (queryIndex == -1) {
      return Text(text, style: style);
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          if (queryIndex > 0) TextSpan(text: text.substring(0, queryIndex)),
          TextSpan(
            text: text.substring(queryIndex, queryIndex + _searchQuery.length),
            style: style.copyWith(
              backgroundColor: AppColors.primaryColor.withOpacity(0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (queryIndex + _searchQuery.length < text.length)
            TextSpan(text: text.substring(queryIndex + _searchQuery.length)),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(NotificationPriority priority) {
    Color color;
    String label;
    IconData icon;

    switch (priority) {
      case NotificationPriority.critical:
        color = Colors.red[600]!;
        label = 'Critical';
        icon = Icons.priority_high;
        break;
      case NotificationPriority.high:
        color = Colors.orange[600]!;
        label = 'High';
        icon = Icons.warning;
        break;
      case NotificationPriority.medium:
        color = Colors.blue[600]!;
        label = 'Medium';
        icon = Icons.info;
        break;
      case NotificationPriority.low:
        color = Colors.grey[600]!;
        label = 'Low';
        icon = Icons.low_priority;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.warning:
        return AppColors.errorColor;
      case NotificationType.alert:
        return Colors.red[600]!;
      case NotificationType.info:
        return AppColors.primaryColor;
      case NotificationType.success:
        return Colors.green[600]!;
      case NotificationType.forecast:
        return Colors.blue[600]!;
      case NotificationType.health:
        return Colors.purple[600]!;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.alert:
        return Icons.error;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.forecast:
        return Icons.cloud;
      case NotificationType.health:
        return Icons.health_and_safety;
    }
  }

  void _showNotificationDetails(
    BuildContext context,
    NotificationItem notification,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Received: ${DateFormat('EEEE, MMMM dd, yyyy at HH:mm').format(notification.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              notification.message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            if (notification.data != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Additional Information:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notification.data.toString(),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (notification.data != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle action with data
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getNotificationColor(notification.type),
                foregroundColor: Colors.white,
              ),
              child: const Text('Take Action'),
            ),
        ],
      ),
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    NotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Notification Settings'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive air quality alerts'),
                value: provider.settings.enableNotifications,
                onChanged: (value) {
                  provider.updateSettings(
                    provider.settings.copyWith(enableNotifications: value),
                  );
                },
                activeThumbColor: AppColors.primaryColor,
              ),
              const Divider(),
              ListTile(
                title: const Text('AQI Alert Threshold'),
                subtitle: Text(
                  'Alert when AQI exceeds ${provider.settings.alertThreshold.round()}',
                ),
                trailing: SizedBox(
                  width: 100,
                  child: Slider(
                    value: provider.settings.alertThreshold,
                    min: 50,
                    max: 300,
                    divisions: 25,
                    activeColor: AppColors.primaryColor,
                    onChanged: (value) {
                      provider.updateSettings(
                        provider.settings.copyWith(alertThreshold: value),
                      );
                    },
                  ),
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Location-based Alerts'),
                subtitle: const Text('Alerts based on current location'),
                value: provider.settings.enableLocationAlerts,
                onChanged: (value) {
                  provider.updateSettings(
                    provider.settings.copyWith(enableLocationAlerts: value),
                  );
                },
                activeThumbColor: AppColors.primaryColor,
              ),
              SwitchListTile(
                title: const Text('Health Recommendations'),
                subtitle: const Text('Receive health advice'),
                value: provider.settings.enableHealthAlerts,
                onChanged: (value) {
                  provider.updateSettings(
                    provider.settings.copyWith(enableHealthAlerts: value),
                  );
                },
                activeThumbColor: AppColors.primaryColor,
              ),
              SwitchListTile(
                title: const Text('Forecast Notifications'),
                subtitle: const Text('Daily air quality forecasts'),
                value: provider.settings.enableForecastAlerts,
                onChanged: (value) {
                  provider.updateSettings(
                    provider.settings.copyWith(enableForecastAlerts: value),
                  );
                },
                activeThumbColor: AppColors.primaryColor,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Settings saved')));
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

  void _showTestNotificationDialog(
    BuildContext context,
    NotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Test Notification'),
        content: const Text(
          'This will create a test notification to verify the system is working correctly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.addTestNotification();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test notification created')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Test'),
          ),
        ],
      ),
    );
  }
}
