import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vayudrishti/core/api_aqi.dart';
import 'package:vayudrishti/core/realtime_client.dart';

enum ConnectionStatus { connected, disconnected, connecting, error }

class BackendConnectionService extends ChangeNotifier {
  final AqiApiClient _apiClient = AqiApiClient.instance;
  final RealtimeClient _realtimeClient = RealtimeClient.instance;
  final Logger _logger = Logger();

  ConnectionStatus _apiStatus = ConnectionStatus.disconnected;
  ConnectionStatus _realtimeStatus = ConnectionStatus.disconnected;
  String? _errorMessage;
  DateTime? _lastConnectionCheck;

  // Getters
  ConnectionStatus get apiStatus => _apiStatus;
  ConnectionStatus get realtimeStatus => _realtimeStatus;
  String? get errorMessage => _errorMessage;
  DateTime? get lastConnectionCheck => _lastConnectionCheck;
  bool get isApiConnected => _apiStatus == ConnectionStatus.connected;
  bool get isRealtimeConnected => _realtimeStatus == ConnectionStatus.connected;
  bool get hasAnyConnection => isApiConnected || isRealtimeConnected;

  static final BackendConnectionService instance =
      BackendConnectionService._internal();
  BackendConnectionService._internal();

  void _setApiStatus(ConnectionStatus status) {
    if (_apiStatus != status) {
      _apiStatus = status;
      _logger.i('API status changed: $status');
      notifyListeners();
    }
  }

  void _setRealtimeStatus(ConnectionStatus status) {
    if (_realtimeStatus != status) {
      _realtimeStatus = status;
      _logger.i('Realtime status changed: $status');
      notifyListeners();
    }
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Initialize connections
  Future<void> initialize() async {
    _logger.i('Initializing backend connections...');
    await checkApiConnection();
    await initializeRealtimeConnection();
  }

  // Check API connection
  Future<bool> checkApiConnection() async {
    try {
      _setApiStatus(ConnectionStatus.connecting);
      _setError(null);

      final isHealthy = await _apiClient.checkHealth();

      if (isHealthy) {
        _setApiStatus(ConnectionStatus.connected);
        _lastConnectionCheck = DateTime.now();
        return true;
      } else {
        _setApiStatus(ConnectionStatus.error);
        _setError('Backend API is not responding');
        return false;
      }
    } catch (e) {
      _setApiStatus(ConnectionStatus.error);
      _setError('Failed to connect to backend API: $e');
      _logger.e('API connection failed: $e');
      return false;
    }
  }

  // Initialize realtime connection
  Future<void> initializeRealtimeConnection() async {
    try {
      _setRealtimeStatus(ConnectionStatus.connecting);

      // Set up callbacks
      _realtimeClient.onConnect = () {
        _setRealtimeStatus(ConnectionStatus.connected);
      };

      _realtimeClient.onDisconnect = () {
        _setRealtimeStatus(ConnectionStatus.disconnected);
      };

      _realtimeClient.onError = (error) {
        _setRealtimeStatus(ConnectionStatus.error);
        _setError('Realtime connection error: $error');
      };

      _realtimeClient.connect();

      // Wait a bit to see if connection succeeds
      await Future.delayed(const Duration(seconds: 3));

      if (!_realtimeClient.isConnected) {
        _setRealtimeStatus(ConnectionStatus.error);
        _setError('Failed to establish realtime connection');
      }
    } catch (e) {
      _setRealtimeStatus(ConnectionStatus.error);
      _setError('Realtime connection failed: $e');
      _logger.e('Realtime connection failed: $e');
    }
  }

  // Retry connections
  Future<void> retryConnections() async {
    _logger.i('Retrying backend connections...');
    await checkApiConnection();
    if (_realtimeStatus != ConnectionStatus.connected) {
      await initializeRealtimeConnection();
    }
  }

  // Subscribe to location updates via realtime
  void subscribeToLocationUpdates(double lat, double lon) {
    if (isRealtimeConnected) {
      _realtimeClient.subscribeToLocation(lat, lon);
    } else {
      _logger.w('Cannot subscribe to location updates: realtime not connected');
    }
  }

  // Subscribe to station updates via realtime
  void subscribeToStationUpdates(String stationId) {
    if (isRealtimeConnected) {
      _realtimeClient.subscribeToStation(stationId);
    } else {
      _logger.w('Cannot subscribe to station updates: realtime not connected');
    }
  }

  // Unsubscribe from all realtime updates
  void unsubscribeFromUpdates() {
    if (isRealtimeConnected) {
      _realtimeClient.unsubscribeAll();
    }
  }

  // Get connection status summary
  String getConnectionStatusSummary() {
    if (isApiConnected && isRealtimeConnected) {
      return 'All systems connected';
    } else if (isApiConnected) {
      return 'API connected, realtime unavailable';
    } else if (isRealtimeConnected) {
      return 'Realtime connected, API unavailable';
    } else {
      return 'Backend offline - using cached data';
    }
  }

  // Get connection status icon
  IconData getConnectionStatusIcon() {
    if (isApiConnected && isRealtimeConnected) {
      return Icons.cloud_done;
    } else if (hasAnyConnection) {
      return Icons.cloud_queue;
    } else {
      return Icons.cloud_off;
    }
  }

  // Get connection status color
  Color getConnectionStatusColor() {
    if (isApiConnected && isRealtimeConnected) {
      return Colors.green;
    } else if (hasAnyConnection) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Dispose connections
  @override
  void dispose() {
    _realtimeClient.dispose();
    super.dispose();
  }
}
