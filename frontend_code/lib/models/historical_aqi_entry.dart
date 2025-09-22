class HistoricalAqiEntry {
  final String stationId;
  final DateTime timestamp;
  final int aqi;
  final Map<String, double> pollutants;

  HistoricalAqiEntry({
    required this.stationId,
    required this.timestamp,
    required this.aqi,
    required this.pollutants,
  });

  factory HistoricalAqiEntry.fromJson(Map<String, dynamic> json) {
    return HistoricalAqiEntry(
      stationId: json['station_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      aqi: json['aqi'] as int,
      pollutants: Map<String, double>.from(json['pollutants'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'timestamp': timestamp.toIso8601String(),
      'aqi': aqi,
      'pollutants': pollutants,
    };
  }

  String get aqiCategory {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Fair';
    if (aqi <= 150) return 'Moderate';
    if (aqi <= 200) return 'Poor';
    if (aqi <= 300) return 'Very Poor';
    return 'Hazardous';
  }

  @override
  String toString() {
    return 'HistoricalAqiEntry(stationId: $stationId, aqi: $aqi, timestamp: $timestamp)';
  }
}
