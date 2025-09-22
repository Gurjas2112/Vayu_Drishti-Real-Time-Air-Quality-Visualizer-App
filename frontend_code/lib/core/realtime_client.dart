import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:vayudrishti/models/models.dart';
import 'config.dart';

class RealtimeClient {
  final String baseUrl; // e.g., http://localhost:8080
  io.Socket? _socket;
  final Logger _logger = Logger();
  final _aqiController = StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;

  // Callbacks for real-time updates
  Function(LatestAqi)? onAqiUpdate;
  Function(String)? onError;
  Function()? onConnect;
  Function()? onDisconnect;

  RealtimeClient({String? baseUrl})
    : baseUrl = baseUrl ?? AppConfig.backendBaseUrl;

  static final RealtimeClient instance = RealtimeClient();

  Stream<Map<String, dynamic>> get aqiUpdates => _aqiController.stream;
  bool get isConnected => _isConnected;

  void connect() {
    if (_socket?.connected == true) {
      _logger.i('Socket already connected');
      return;
    }

    _logger.i('Connecting to realtime server: $baseUrl');

    final socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      _logger.i('Connected to realtime server');
      _isConnected = true;
      onConnect?.call();
    });

    socket.onDisconnect((_) {
      _logger.i('Disconnected from realtime server');
      _isConnected = false;
      onDisconnect?.call();
    });

    socket.onConnectError((error) {
      _logger.e('Connection error: $error');
      _isConnected = false;
      onError?.call('Connection failed: $error');
    });

    socket.onError((error) {
      _logger.e('Socket error: $error');
      onError?.call('Socket error: $error');
    });

    // Listen for AQI updates
    socket.on('aqi:update', (data) {
      try {
        _logger.i('Received AQI update: $data');
        Map<String, dynamic> aqiData;

        if (data is Map<String, dynamic>) {
          aqiData = data;
        } else if (data is Map) {
          aqiData = Map<String, dynamic>.from(data);
        } else if (data is String) {
          aqiData = jsonDecode(data) as Map<String, dynamic>;
        } else {
          _logger.w('Unknown data format received');
          return;
        }

        _aqiController.add(aqiData);

        // Try to parse as LatestAqi for callback
        try {
          final latestAqi = LatestAqi.fromJson(aqiData);
          onAqiUpdate?.call(latestAqi);
        } catch (e) {
          _logger.w('Could not parse as LatestAqi: $e');
        }
      } catch (e) {
        _logger.e('Error parsing AQI update: $e');
        onError?.call('Error parsing real-time data');
      }
    });

    socket.connect();
    _socket = socket;
  }

  void disconnect() {
    if (_socket?.connected == true) {
      _logger.i('Disconnecting from realtime server');
      _socket!.disconnect();
    }
    _isConnected = false;
  }

  // Subscribe to updates for a specific location
  void subscribeToLocation(double lat, double lon) {
    if (_socket?.connected == true) {
      _logger.i('Subscribing to location updates: lat=$lat, lon=$lon');
      _socket!.emit('subscribe-location', {'lat': lat, 'lon': lon});
    } else {
      _logger.w('Cannot subscribe: socket not connected');
    }
  }

  // Subscribe to updates for a specific station
  void subscribeToStation(String stationId) {
    if (_socket?.connected == true) {
      _logger.i('Subscribing to station updates: $stationId');
      _socket!.emit('subscribe-station', {'stationId': stationId});
    } else {
      _logger.w('Cannot subscribe: socket not connected');
    }
  }

  // Unsubscribe from all updates
  void unsubscribeAll() {
    if (_socket?.connected == true) {
      _logger.i('Unsubscribing from all updates');
      _socket!.emit('unsubscribe-all');
    }
  }

  void dispose() {
    disconnect();
    _socket?.dispose();
    _aqiController.close();
  }
}
